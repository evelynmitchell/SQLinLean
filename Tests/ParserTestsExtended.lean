-- Extended Parser Tests inspired by sqlglot test suite
import SQLinLean.Parser
import SQLinLean.AST
import SQLinLean.Token

namespace SQLinLean.Tests

open SQLinLean

-- Test SELECT with column aliases
def testSelectWithAlias : IO Unit := do
  match parseSQL "SELECT name AS user_name FROM users" with
  | Sum.inl err => 
      IO.println s!"FAIL: testSelectWithAlias - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ [SelectItem.Expr (Expr.Identifier "name") (some "user_name")] _ _ _ _ _ _ _ =>
          IO.println "PASS: testSelectWithAlias"
      | _ => 
          IO.println s!"FAIL: testSelectWithAlias - Unexpected parse result: {repr stmt}"

-- Test SELECT with table alias
def testSelectTableAlias : IO Unit := do
  match parseSQL "SELECT u.name FROM users AS u" with
  | Sum.inl err => 
      IO.println s!"FAIL: testSelectTableAlias - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ [SelectItem.Expr (Expr.QualifiedIdentifier "u" "name") none] 
                        (some (TableRef.Table "users" (some "u"))) none _ _ _ _ _ =>
          IO.println "PASS: testSelectTableAlias"
      | _ => 
          IO.println s!"FAIL: testSelectTableAlias - Unexpected parse result: {repr stmt}"

-- Test SELECT with ORDER BY
def testSelectOrderBy : IO Unit := do
  match parseSQL "SELECT * FROM users ORDER BY name" with
  | Sum.inl err =>
      IO.println s!"FAIL: testSelectOrderBy - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ _ _ _ orderBy _ _ =>
          if orderBy.length == 1 then
            IO.println "PASS: testSelectOrderBy"
          else
            IO.println s!"FAIL: testSelectOrderBy - Expected 1 ORDER BY item, got {orderBy.length}"
      | _ =>
          IO.println s!"FAIL: testSelectOrderBy - Unexpected parse result: {repr stmt}"

-- Test SELECT with ORDER BY DESC
def testSelectOrderByDesc : IO Unit := do
  match parseSQL "SELECT * FROM users ORDER BY age DESC" with
  | Sum.inl err =>
      IO.println s!"FAIL: testSelectOrderByDesc - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ _ _ _ [(_, false)] _ _ =>
          IO.println "PASS: testSelectOrderByDesc"
      | Statement.Select _ _ _ _ _ _ orderBy _ _ =>
          IO.println s!"FAIL: testSelectOrderByDesc - Expected DESC (false), got {repr orderBy}"
      | _ =>
          IO.println s!"FAIL: testSelectOrderByDesc - Unexpected parse result: {repr stmt}"

-- Test SELECT with ORDER BY multiple columns
def testSelectOrderByMultiple : IO Unit := do
  match parseSQL "SELECT * FROM users ORDER BY name ASC, age DESC" with
  | Sum.inl err =>
      IO.println s!"FAIL: testSelectOrderByMultiple - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ _ _ _ orderBy _ _ =>
          if orderBy.length == 2 then
            IO.println "PASS: testSelectOrderByMultiple"
          else
            IO.println s!"FAIL: testSelectOrderByMultiple - Expected 2 ORDER BY items, got {orderBy.length}"
      | _ =>
          IO.println s!"FAIL: testSelectOrderByMultiple - Unexpected parse result: {repr stmt}"

-- Test SELECT with LIMIT
def testSelectLimit : IO Unit := do
  match parseSQL "SELECT * FROM users LIMIT 10" with
  | Sum.inl err =>
      IO.println s!"FAIL: testSelectLimit - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ _ _ _ _ (some 10) _ =>
          IO.println "PASS: testSelectLimit"
      | Statement.Select _ _ _ _ _ _ _ limit _ =>
          IO.println s!"FAIL: testSelectLimit - Expected LIMIT 10, got {repr limit}"
      | _ =>
          IO.println s!"FAIL: testSelectLimit - Unexpected parse result: {repr stmt}"

-- Test SELECT with LIMIT and OFFSET
def testSelectLimitOffset : IO Unit := do
  match parseSQL "SELECT * FROM users LIMIT 10 OFFSET 20" with
  | Sum.inl err =>
      IO.println s!"FAIL: testSelectLimitOffset - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ _ _ _ _ (some 10) (some 20) =>
          IO.println "PASS: testSelectLimitOffset"
      | Statement.Select _ _ _ _ _ _ _ limit offset =>
          IO.println s!"FAIL: testSelectLimitOffset - Expected LIMIT 10 OFFSET 20, got limit={repr limit}, offset={repr offset}"
      | _ =>
          IO.println s!"FAIL: testSelectLimitOffset - Unexpected parse result: {repr stmt}"

-- Test SELECT with WHERE, ORDER BY, LIMIT, OFFSET (full query)
def testSelectFull : IO Unit := do
  match parseSQL "SELECT name, age FROM users WHERE active = 1 ORDER BY name LIMIT 10 OFFSET 5" with
  | Sum.inl err =>
      IO.println s!"FAIL: testSelectFull - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ cols (some _) (some _) _ _ orderBy (some 10) (some 5) =>
          if cols.length == 2 && orderBy.length == 1 then
            IO.println "PASS: testSelectFull"
          else
            IO.println s!"FAIL: testSelectFull - Wrong counts: cols={cols.length}, orderBy={orderBy.length}"
      | _ =>
          IO.println s!"FAIL: testSelectFull - Unexpected parse result: {repr stmt}"

-- Test SELECT with complex WHERE (multiple ANDs)
def testComplexWhere : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE age > 18 AND status = 1 AND active = 1" with
  | Sum.inl err => 
      IO.println s!"FAIL: testComplexWhere - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some _) _ _ _ _ _ =>
          IO.println "PASS: testComplexWhere"
      | _ => 
          IO.println s!"FAIL: testComplexWhere - Unexpected parse result: {repr stmt}"

-- Test SELECT with OR condition
def testWhereOr : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE age < 18 OR age > 65" with
  | Sum.inl err => 
      IO.println s!"FAIL: testWhereOr - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some _) _ _ _ _ _ =>
          IO.println "PASS: testWhereOr"
      | _ => 
          IO.println s!"FAIL: testWhereOr - Unexpected parse result: {repr stmt}"

-- Test SELECT with NOT
def testWhereNot : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE NOT deleted" with
  | Sum.inl err => 
      IO.println s!"FAIL: testWhereNot - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.Not _)) _ _ _ _ _ =>
          IO.println "PASS: testWhereNot"
      | _ => 
          IO.println s!"FAIL: testWhereNot - Unexpected parse result: {repr stmt}"

-- Test SELECT with string literal in WHERE
def testWhereString : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE name = 'Alice'" with
  | Sum.inl err => 
      IO.println s!"FAIL: testWhereString - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.BinaryOp _ _ (Expr.Literal (Literal.String "Alice")))) _ _ _ _ _ =>
          IO.println "PASS: testWhereString"
      | _ => 
          IO.println s!"FAIL: testWhereString - Unexpected parse result: {repr stmt}"

-- Test SELECT with NULL
def testWhereNull : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE email = NULL" with
  | Sum.inl err => 
      IO.println s!"FAIL: testWhereNull - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.BinaryOp _ _ (Expr.Literal Literal.Null))) _ _ _ _ _ =>
          IO.println "PASS: testWhereNull"
      | _ => 
          IO.println s!"FAIL: testWhereNull - Unexpected parse result: {repr stmt}"

-- Test SELECT with parenthesized expression
def testParenthesizedExpression : IO Unit := do
  match parseSQL "SELECT * FROM items WHERE (price + tax) > 100" with
  | Sum.inl err => 
      IO.println s!"FAIL: testParenthesizedExpression - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some _) _ _ _ _ _ =>
          IO.println "PASS: testParenthesizedExpression"
      | _ => 
          IO.println s!"FAIL: testParenthesizedExpression - Unexpected parse result: {repr stmt}"

-- Note: Qualified star (table.*) and multiple INSERT rows are not yet implemented
-- These tests are commented out until these features are added to the parser
-- def testQualifiedStar : IO Unit := do ...
-- def testInsertMultipleRows : IO Unit := do ...

-- Test INSERT with column list
def testInsertWithColumns : IO Unit := do
  match parseSQL "INSERT INTO users (name, age) VALUES ('Alice', 30)" with
  | Sum.inl err => 
      IO.println s!"FAIL: testInsertWithColumns - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Insert "users" ["name", "age"] _ =>
          IO.println "PASS: testInsertWithColumns"
      | _ => 
          IO.println s!"FAIL: testInsertWithColumns - Unexpected parse result: {repr stmt}"

-- Test DELETE without WHERE
def testDeleteAll : IO Unit := do
  match parseSQL "DELETE FROM users" with
  | Sum.inl err => 
      IO.println s!"FAIL: testDeleteAll - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Delete "users" none =>
          IO.println "PASS: testDeleteAll"
      | _ => 
          IO.println s!"FAIL: testDeleteAll - Unexpected parse result: {repr stmt}"

-- Test DELETE with complex WHERE
def testDeleteComplexWhere : IO Unit := do
  match parseSQL "DELETE FROM users WHERE age > 100 AND status = 0" with
  | Sum.inl err => 
      IO.println s!"FAIL: testDeleteComplexWhere - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Delete "users" (some _) =>
          IO.println "PASS: testDeleteComplexWhere"
      | _ => 
          IO.println s!"FAIL: testDeleteComplexWhere - Unexpected parse result: {repr stmt}"

-- Test SELECT without FROM (should work with NULL table)
def testSelectWithoutFrom : IO Unit := do
  match parseSQL "SELECT 1" with
  | Sum.inl err => 
      IO.println s!"FAIL: testSelectWithoutFrom - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ [SelectItem.Expr (Expr.Literal (Literal.Integer 1)) none] none _ _ _ _ _ _ =>
          IO.println "PASS: testSelectWithoutFrom"
      | _ => 
          IO.println s!"FAIL: testSelectWithoutFrom - Unexpected parse result: {repr stmt}"

-- Test multiple columns with various types
def testMultipleColumnTypes : IO Unit := do
  match parseSQL "SELECT id, name, 3.14, 'text', NULL FROM users" with
  | Sum.inl err => 
      IO.println s!"FAIL: testMultipleColumnTypes - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ cols _ _ _ _ _ _ _ =>
          if cols.length == 5 then
            IO.println "PASS: testMultipleColumnTypes"
          else
            IO.println s!"FAIL: testMultipleColumnTypes - Expected 5 columns, got {cols.length}"
      | _ => 
          IO.println s!"FAIL: testMultipleColumnTypes - Not a SELECT: {repr stmt}"

-- Test arithmetic operations in SELECT
def testArithmeticInSelect : IO Unit := do
  match parseSQL "SELECT price * 1.1, quantity + 1 FROM products" with
  | Sum.inl err => 
      IO.println s!"FAIL: testArithmeticInSelect - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ cols _ _ _ _ _ _ _ =>
          if cols.length == 2 then
            IO.println "PASS: testArithmeticInSelect"
          else
            IO.println s!"FAIL: testArithmeticInSelect - Expected 2 columns, got {cols.length}"
      | _ => 
          IO.println s!"FAIL: testArithmeticInSelect - Not a SELECT: {repr stmt}"

-- Test WHERE with all comparison operators
def testParserAllComparisonOperators : IO Unit := do
  match parseSQL "SELECT * FROM t WHERE a = 1" with
  | Sum.inl err => 
      IO.println s!"FAIL: testParserAllComparisonOperators(=) - {err}"
  | Sum.inr _ =>
      match parseSQL "SELECT * FROM t WHERE a != 1" with
      | Sum.inl err => 
          IO.println s!"FAIL: testParserAllComparisonOperators(!=) - {err}"
      | Sum.inr _ =>
          match parseSQL "SELECT * FROM t WHERE a < 1" with
          | Sum.inl err => 
              IO.println s!"FAIL: testParserAllComparisonOperators(<) - {err}"
          | Sum.inr _ =>
              match parseSQL "SELECT * FROM t WHERE a > 1" with
              | Sum.inl err => 
                  IO.println s!"FAIL: testParserAllComparisonOperators(>) - {err}"
              | Sum.inr _ =>
                  match parseSQL "SELECT * FROM t WHERE a <= 1" with
                  | Sum.inl err => 
                      IO.println s!"FAIL: testParserAllComparisonOperators(<=) - {err}"
                  | Sum.inr _ =>
                      match parseSQL "SELECT * FROM t WHERE a >= 1" with
                      | Sum.inl err => 
                          IO.println s!"FAIL: testParserAllComparisonOperators(>=) - {err}"
                      | Sum.inr _ =>
                          IO.println "PASS: testParserAllComparisonOperators"

-- Test case sensitivity with mixed case
def testMixedCaseKeywords : IO Unit := do
  match parseSQL "SeLeCt * FrOm UsErS wHeRe AgE > 18" with
  | Sum.inl err => 
      IO.println s!"FAIL: testMixedCaseKeywords - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some (TableRef.Table "UsErS" none)) (some _) _ _ _ _ _ =>
          IO.println "PASS: testMixedCaseKeywords"
      | _ => 
          IO.println s!"FAIL: testMixedCaseKeywords - Unexpected parse result: {repr stmt}"


-- Test empty SQL (error case)
def testEmptySQL : IO Unit := do
  match parseSQL "" with
  | Sum.inl _ => 
      IO.println "PASS: testEmptySQL"
  | Sum.inr stmt =>
      IO.println s!"FAIL: testEmptySQL - Should have failed but got: {repr stmt}"

-- Test missing SELECT columns (error case)
def testMissingSelectColumns : IO Unit := do
  match parseSQL "SELECT FROM users" with
  | Sum.inl _ => 
      IO.println "PASS: testMissingSelectColumns"
  | Sum.inr stmt =>
      IO.println s!"FAIL: testMissingSelectColumns - Should have failed but got: {repr stmt}"

-- Test missing WHERE expression (error case)
def testMissingWhereExpression : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE" with
  | Sum.inl _ => 
      IO.println "PASS: testMissingWhereExpression"
  | Sum.inr stmt =>
      IO.println s!"FAIL: testMissingWhereExpression - Should have failed but got: {repr stmt}"

-- Test invalid INSERT (error case)
def testInvalidInsert : IO Unit := do
  match parseSQL "INSERT INTO users" with
  | Sum.inl _ => 
      IO.println "PASS: testInvalidInsert"
  | Sum.inr stmt =>
      IO.println s!"FAIL: testInvalidInsert - Should have failed but got: {repr stmt}"

-- Test unclosed parenthesis (error case)
def testUnclosedParenthesis : IO Unit := do
  match parseSQL "INSERT INTO users VALUES (1, 'Alice'" with
  | Sum.inl _ =>
      IO.println "PASS: testUnclosedParenthesis"
  | Sum.inr stmt =>
      IO.println s!"FAIL: testUnclosedParenthesis - Should have failed but got: {repr stmt}"

-- Test INNER JOIN
def testInnerJoin : IO Unit := do
  match parseSQL "SELECT * FROM users INNER JOIN orders ON users.id = orders.user_id" with
  | Sum.inl err =>
      IO.println s!"FAIL: testInnerJoin - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some (TableRef.Join _ .Inner _ _)) _ _ _ _ _ _ =>
          IO.println "PASS: testInnerJoin"
      | _ =>
          IO.println s!"FAIL: testInnerJoin - Unexpected parse result: {repr stmt}"

-- Test LEFT JOIN
def testLeftJoin : IO Unit := do
  match parseSQL "SELECT * FROM users LEFT JOIN orders ON users.id = orders.user_id" with
  | Sum.inl err =>
      IO.println s!"FAIL: testLeftJoin - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some (TableRef.Join _ .Left _ _)) _ _ _ _ _ _ =>
          IO.println "PASS: testLeftJoin"
      | _ =>
          IO.println s!"FAIL: testLeftJoin - Unexpected parse result: {repr stmt}"

-- Test LEFT OUTER JOIN
def testLeftOuterJoin : IO Unit := do
  match parseSQL "SELECT * FROM users LEFT OUTER JOIN orders ON users.id = orders.user_id" with
  | Sum.inl err =>
      IO.println s!"FAIL: testLeftOuterJoin - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some (TableRef.Join _ .Left _ _)) _ _ _ _ _ _ =>
          IO.println "PASS: testLeftOuterJoin"
      | _ =>
          IO.println s!"FAIL: testLeftOuterJoin - Unexpected parse result: {repr stmt}"

-- Test RIGHT JOIN
def testRightJoin : IO Unit := do
  match parseSQL "SELECT * FROM users RIGHT JOIN orders ON users.id = orders.user_id" with
  | Sum.inl err =>
      IO.println s!"FAIL: testRightJoin - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some (TableRef.Join _ .Right _ _)) _ _ _ _ _ _ =>
          IO.println "PASS: testRightJoin"
      | _ =>
          IO.println s!"FAIL: testRightJoin - Unexpected parse result: {repr stmt}"

-- Test plain JOIN (defaults to INNER)
def testPlainJoin : IO Unit := do
  match parseSQL "SELECT * FROM users JOIN orders ON users.id = orders.user_id" with
  | Sum.inl err =>
      IO.println s!"FAIL: testPlainJoin - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some (TableRef.Join _ .Inner _ _)) _ _ _ _ _ _ =>
          IO.println "PASS: testPlainJoin"
      | _ =>
          IO.println s!"FAIL: testPlainJoin - Unexpected parse result: {repr stmt}"

-- Test JOIN with table aliases
def testJoinWithAliases : IO Unit := do
  match parseSQL "SELECT u.name, o.total FROM users AS u JOIN orders AS o ON u.id = o.user_id" with
  | Sum.inl err =>
      IO.println s!"FAIL: testJoinWithAliases - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ cols (some (TableRef.Join (TableRef.Table "users" (some "u")) .Inner (TableRef.Table "orders" (some "o")) _)) _ _ _ _ _ _ =>
          if cols.length == 2 then
            IO.println "PASS: testJoinWithAliases"
          else
            IO.println s!"FAIL: testJoinWithAliases - Expected 2 columns, got {cols.length}"
      | _ =>
          IO.println s!"FAIL: testJoinWithAliases - Unexpected parse result: {repr stmt}"

-- Test multiple JOINs
def testMultipleJoins : IO Unit := do
  match parseSQL "SELECT * FROM a JOIN b ON a.id = b.a_id JOIN c ON b.id = c.b_id" with
  | Sum.inl err =>
      IO.println s!"FAIL: testMultipleJoins - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some (TableRef.Join (TableRef.Join _ _ _ _) _ _ _)) _ _ _ _ _ _ =>
          IO.println "PASS: testMultipleJoins"
      | _ =>
          IO.println s!"FAIL: testMultipleJoins - Unexpected parse result: {repr stmt}"

-- Test JOIN with WHERE clause
def testJoinWithWhere : IO Unit := do
  match parseSQL "SELECT * FROM users u JOIN orders o ON u.id = o.user_id WHERE o.total > 100" with
  | Sum.inl err =>
      IO.println s!"FAIL: testJoinWithWhere - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some (TableRef.Join _ _ _ _)) (some _) _ _ _ _ _ =>
          IO.println "PASS: testJoinWithWhere"
      | _ =>
          IO.println s!"FAIL: testJoinWithWhere - Unexpected parse result: {repr stmt}"

-- Test FULL OUTER JOIN
def testFullOuterJoin : IO Unit := do
  match parseSQL "SELECT * FROM a FULL OUTER JOIN b ON a.id = b.a_id" with
  | Sum.inl err =>
      IO.println s!"FAIL: testFullOuterJoin - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some (TableRef.Join _ .Full _ _)) _ _ _ _ _ _ =>
          IO.println "PASS: testFullOuterJoin"
      | _ =>
          IO.println s!"FAIL: testFullOuterJoin - Unexpected parse result: {repr stmt}"

-- Test COUNT(*)
def testCountStar : IO Unit := do
  match parseSQL "SELECT COUNT(*) FROM users" with
  | Sum.inl err =>
      IO.println s!"FAIL: testCountStar - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ [SelectItem.Expr (Expr.Aggregate .Count .Star false) none] _ _ _ _ _ _ _ =>
          IO.println "PASS: testCountStar"
      | _ =>
          IO.println s!"FAIL: testCountStar - Unexpected parse result: {repr stmt}"

-- Test COUNT(column)
def testCountColumn : IO Unit := do
  match parseSQL "SELECT COUNT(id) FROM users" with
  | Sum.inl err =>
      IO.println s!"FAIL: testCountColumn - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ [SelectItem.Expr (Expr.Aggregate .Count (Expr.Identifier "id") false) none] _ _ _ _ _ _ _ =>
          IO.println "PASS: testCountColumn"
      | _ =>
          IO.println s!"FAIL: testCountColumn - Unexpected parse result: {repr stmt}"

-- Test COUNT(DISTINCT column)
def testCountDistinct : IO Unit := do
  match parseSQL "SELECT COUNT(DISTINCT email) FROM users" with
  | Sum.inl err =>
      IO.println s!"FAIL: testCountDistinct - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ [SelectItem.Expr (Expr.Aggregate .Count (Expr.Identifier "email") true) none] _ _ _ _ _ _ _ =>
          IO.println "PASS: testCountDistinct"
      | _ =>
          IO.println s!"FAIL: testCountDistinct - Unexpected parse result: {repr stmt}"

-- Test SUM
def testSum : IO Unit := do
  match parseSQL "SELECT SUM(amount) FROM orders" with
  | Sum.inl err =>
      IO.println s!"FAIL: testSum - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ [SelectItem.Expr (Expr.Aggregate .Sum _ false) none] _ _ _ _ _ _ _ =>
          IO.println "PASS: testSum"
      | _ =>
          IO.println s!"FAIL: testSum - Unexpected parse result: {repr stmt}"

-- Test AVG
def testAvg : IO Unit := do
  match parseSQL "SELECT AVG(price) FROM products" with
  | Sum.inl err =>
      IO.println s!"FAIL: testAvg - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ [SelectItem.Expr (Expr.Aggregate .Avg _ false) none] _ _ _ _ _ _ _ =>
          IO.println "PASS: testAvg"
      | _ =>
          IO.println s!"FAIL: testAvg - Unexpected parse result: {repr stmt}"

-- Test MIN and MAX
def testMinMax : IO Unit := do
  match parseSQL "SELECT MIN(price), MAX(price) FROM products" with
  | Sum.inl err =>
      IO.println s!"FAIL: testMinMax - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ [SelectItem.Expr (Expr.Aggregate .Min _ _) _, SelectItem.Expr (Expr.Aggregate .Max _ _) _] _ _ _ _ _ _ _ =>
          IO.println "PASS: testMinMax"
      | _ =>
          IO.println s!"FAIL: testMinMax - Unexpected parse result: {repr stmt}"

-- Test aggregate with alias
def testAggregateWithAlias : IO Unit := do
  match parseSQL "SELECT COUNT(*) AS total FROM users" with
  | Sum.inl err =>
      IO.println s!"FAIL: testAggregateWithAlias - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ [SelectItem.Expr (Expr.Aggregate .Count .Star false) (some "total")] _ _ _ _ _ _ _ =>
          IO.println "PASS: testAggregateWithAlias"
      | _ =>
          IO.println s!"FAIL: testAggregateWithAlias - Unexpected parse result: {repr stmt}"

-- Test multiple aggregates
def testMultipleAggregates : IO Unit := do
  match parseSQL "SELECT COUNT(*), SUM(amount), AVG(amount) FROM orders" with
  | Sum.inl err =>
      IO.println s!"FAIL: testMultipleAggregates - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ cols _ _ _ _ _ _ _ =>
          if cols.length == 3 then
            IO.println "PASS: testMultipleAggregates"
          else
            IO.println s!"FAIL: testMultipleAggregates - Expected 3 columns, got {cols.length}"
      | _ =>
          IO.println s!"FAIL: testMultipleAggregates - Unexpected parse result: {repr stmt}"

-- Test GROUP BY
def testGroupBy : IO Unit := do
  match parseSQL "SELECT category, COUNT(*) FROM products GROUP BY category" with
  | Sum.inl err =>
      IO.println s!"FAIL: testGroupBy - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ _ groupBy _ _ _ _ =>
          if groupBy.length == 1 then
            IO.println "PASS: testGroupBy"
          else
            IO.println s!"FAIL: testGroupBy - Expected 1 GROUP BY expr, got {groupBy.length}"
      | _ =>
          IO.println s!"FAIL: testGroupBy - Unexpected parse result: {repr stmt}"

-- Test GROUP BY with multiple columns
def testGroupByMultiple : IO Unit := do
  match parseSQL "SELECT category, brand, SUM(price) FROM products GROUP BY category, brand" with
  | Sum.inl err =>
      IO.println s!"FAIL: testGroupByMultiple - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ _ groupBy _ _ _ _ =>
          if groupBy.length == 2 then
            IO.println "PASS: testGroupByMultiple"
          else
            IO.println s!"FAIL: testGroupByMultiple - Expected 2 GROUP BY exprs, got {groupBy.length}"
      | _ =>
          IO.println s!"FAIL: testGroupByMultiple - Unexpected parse result: {repr stmt}"

-- Test GROUP BY with HAVING
def testGroupByHaving : IO Unit := do
  match parseSQL "SELECT category, COUNT(*) FROM products GROUP BY category HAVING COUNT(*) > 5" with
  | Sum.inl err =>
      IO.println s!"FAIL: testGroupByHaving - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ _ groupBy (some _) _ _ _ =>
          if groupBy.length == 1 then
            IO.println "PASS: testGroupByHaving"
          else
            IO.println s!"FAIL: testGroupByHaving - Expected 1 GROUP BY expr, got {groupBy.length}"
      | _ =>
          IO.println s!"FAIL: testGroupByHaving - Unexpected parse result: {repr stmt}"

-- Test full query with GROUP BY, HAVING, ORDER BY
def testGroupByFull : IO Unit := do
  match parseSQL "SELECT category, SUM(price) AS total FROM products WHERE active = 1 GROUP BY category HAVING SUM(price) > 100 ORDER BY total DESC LIMIT 10" with
  | Sum.inl err =>
      IO.println s!"FAIL: testGroupByFull - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some _) groupBy (some _) orderBy (some 10) _ =>
          if groupBy.length == 1 && orderBy.length == 1 then
            IO.println "PASS: testGroupByFull"
          else
            IO.println s!"FAIL: testGroupByFull - Unexpected groupBy/orderBy lengths"
      | _ =>
          IO.println s!"FAIL: testGroupByFull - Unexpected parse result: {repr stmt}"

-- Test IS NULL
def testIsNull : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE email IS NULL" with
  | Sum.inl err =>
      IO.println s!"FAIL: testIsNull - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.IsNull (Expr.Identifier "email") false)) _ _ _ _ _ =>
          IO.println "PASS: testIsNull"
      | _ =>
          IO.println s!"FAIL: testIsNull - Unexpected parse result: {repr stmt}"

-- Test IS NOT NULL
def testIsNotNull : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE email IS NOT NULL" with
  | Sum.inl err =>
      IO.println s!"FAIL: testIsNotNull - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.IsNull (Expr.Identifier "email") true)) _ _ _ _ _ =>
          IO.println "PASS: testIsNotNull"
      | _ =>
          IO.println s!"FAIL: testIsNotNull - Unexpected parse result: {repr stmt}"

-- Test IS NULL with qualified identifier
def testIsNullQualified : IO Unit := do
  match parseSQL "SELECT * FROM users u WHERE u.email IS NULL" with
  | Sum.inl err =>
      IO.println s!"FAIL: testIsNullQualified - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.IsNull (Expr.QualifiedIdentifier "u" "email") false)) _ _ _ _ _ =>
          IO.println "PASS: testIsNullQualified"
      | _ =>
          IO.println s!"FAIL: testIsNullQualified - Unexpected parse result: {repr stmt}"

-- Test IS NULL with AND
def testIsNullWithAnd : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE name IS NOT NULL AND age > 18" with
  | Sum.inl err =>
      IO.println s!"FAIL: testIsNullWithAnd - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.BinaryOp (Expr.IsNull _ true) .And _)) _ _ _ _ _ =>
          IO.println "PASS: testIsNullWithAnd"
      | _ =>
          IO.println s!"FAIL: testIsNullWithAnd - Unexpected parse result: {repr stmt}"

-- Test IS NULL with expression
def testIsNullExpression : IO Unit := do
  match parseSQL "SELECT * FROM t WHERE a + b IS NULL" with
  | Sum.inl err =>
      IO.println s!"FAIL: testIsNullExpression - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.IsNull (Expr.BinaryOp _ .Plus _) false)) _ _ _ _ _ =>
          IO.println "PASS: testIsNullExpression"
      | _ =>
          IO.println s!"FAIL: testIsNullExpression - Unexpected parse result: {repr stmt}"

-- Test LIKE operator
def testLike : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE name LIKE '%john%'" with
  | Sum.inl err =>
      IO.println s!"FAIL: testLike - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.BinaryOp (Expr.Identifier "name") .Like (Expr.Literal (Literal.String "%john%")))) _ _ _ _ _ =>
          IO.println "PASS: testLike"
      | _ =>
          IO.println s!"FAIL: testLike - Unexpected parse result: {repr stmt}"

-- Test LIKE with prefix pattern
def testLikePrefix : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE email LIKE '%@gmail.com'" with
  | Sum.inl err =>
      IO.println s!"FAIL: testLikePrefix - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.BinaryOp _ .Like _)) _ _ _ _ _ =>
          IO.println "PASS: testLikePrefix"
      | _ =>
          IO.println s!"FAIL: testLikePrefix - Unexpected parse result: {repr stmt}"

-- Test LIKE with AND
def testLikeWithAnd : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE name LIKE 'A%' AND active = 1" with
  | Sum.inl err =>
      IO.println s!"FAIL: testLikeWithAnd - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.BinaryOp (Expr.BinaryOp _ .Like _) .And _)) _ _ _ _ _ =>
          IO.println "PASS: testLikeWithAnd"
      | _ =>
          IO.println s!"FAIL: testLikeWithAnd - Unexpected parse result: {repr stmt}"

-- Test LIKE with qualified identifier
def testLikeQualified : IO Unit := do
  match parseSQL "SELECT * FROM users u WHERE u.name LIKE 'test%'" with
  | Sum.inl err =>
      IO.println s!"FAIL: testLikeQualified - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.BinaryOp (Expr.QualifiedIdentifier "u" "name") .Like _)) _ _ _ _ _ =>
          IO.println "PASS: testLikeQualified"
      | _ =>
          IO.println s!"FAIL: testLikeQualified - Unexpected parse result: {repr stmt}"

-- Test IN with integers
def testInIntegers : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE id IN (1, 2, 3)" with
  | Sum.inl err =>
      IO.println s!"FAIL: testInIntegers - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.In (Expr.Identifier "id") values false)) _ _ _ _ _ =>
          if values.length == 3 then
            IO.println "PASS: testInIntegers"
          else
            IO.println s!"FAIL: testInIntegers - Expected 3 values, got {values.length}"
      | _ =>
          IO.println s!"FAIL: testInIntegers - Unexpected parse result: {repr stmt}"

-- Test IN with strings
def testInStrings : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE status IN ('active', 'pending')" with
  | Sum.inl err =>
      IO.println s!"FAIL: testInStrings - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.In _ values false)) _ _ _ _ _ =>
          if values.length == 2 then
            IO.println "PASS: testInStrings"
          else
            IO.println s!"FAIL: testInStrings - Expected 2 values, got {values.length}"
      | _ =>
          IO.println s!"FAIL: testInStrings - Unexpected parse result: {repr stmt}"

-- Test NOT IN
def testNotIn : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE id NOT IN (1, 2, 3)" with
  | Sum.inl err =>
      IO.println s!"FAIL: testNotIn - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.In _ values true)) _ _ _ _ _ =>
          if values.length == 3 then
            IO.println "PASS: testNotIn"
          else
            IO.println s!"FAIL: testNotIn - Expected 3 values, got {values.length}"
      | _ =>
          IO.println s!"FAIL: testNotIn - Unexpected parse result: {repr stmt}"

-- Test IN with AND
def testInWithAnd : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE id IN (1, 2) AND active = 1" with
  | Sum.inl err =>
      IO.println s!"FAIL: testInWithAnd - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.BinaryOp (Expr.In _ _ false) .And _)) _ _ _ _ _ =>
          IO.println "PASS: testInWithAnd"
      | _ =>
          IO.println s!"FAIL: testInWithAnd - Unexpected parse result: {repr stmt}"

-- Test IN with single value
def testInSingleValue : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE id IN (42)" with
  | Sum.inl err =>
      IO.println s!"FAIL: testInSingleValue - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.In _ values false)) _ _ _ _ _ =>
          if values.length == 1 then
            IO.println "PASS: testInSingleValue"
          else
            IO.println s!"FAIL: testInSingleValue - Expected 1 value, got {values.length}"
      | _ =>
          IO.println s!"FAIL: testInSingleValue - Unexpected parse result: {repr stmt}"

-- Test BETWEEN with integers
def testBetweenIntegers : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE age BETWEEN 18 AND 65" with
  | Sum.inl err =>
      IO.println s!"FAIL: testBetweenIntegers - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.Between (Expr.Identifier "age") (Expr.Literal (Literal.Integer 18)) (Expr.Literal (Literal.Integer 65)) false)) _ _ _ _ _ =>
          IO.println "PASS: testBetweenIntegers"
      | _ =>
          IO.println s!"FAIL: testBetweenIntegers - Unexpected parse result: {repr stmt}"

-- Test BETWEEN with strings (dates)
def testBetweenStrings : IO Unit := do
  match parseSQL "SELECT * FROM orders WHERE created BETWEEN '2024-01-01' AND '2024-12-31'" with
  | Sum.inl err =>
      IO.println s!"FAIL: testBetweenStrings - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.Between _ _ _ false)) _ _ _ _ _ =>
          IO.println "PASS: testBetweenStrings"
      | _ =>
          IO.println s!"FAIL: testBetweenStrings - Unexpected parse result: {repr stmt}"

-- Test NOT BETWEEN
def testNotBetween : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE age NOT BETWEEN 0 AND 17" with
  | Sum.inl err =>
      IO.println s!"FAIL: testNotBetween - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.Between _ _ _ true)) _ _ _ _ _ =>
          IO.println "PASS: testNotBetween"
      | _ =>
          IO.println s!"FAIL: testNotBetween - Unexpected parse result: {repr stmt}"

-- Test BETWEEN with AND clause
def testBetweenWithAnd : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE age BETWEEN 18 AND 65 AND active = 1" with
  | Sum.inl err =>
      IO.println s!"FAIL: testBetweenWithAnd - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.BinaryOp (Expr.Between _ _ _ false) .And _)) _ _ _ _ _ =>
          IO.println "PASS: testBetweenWithAnd"
      | _ =>
          IO.println s!"FAIL: testBetweenWithAnd - Unexpected parse result: {repr stmt}"

-- Test BETWEEN with qualified identifier
def testBetweenQualified : IO Unit := do
  match parseSQL "SELECT * FROM users u WHERE u.score BETWEEN 0 AND 100" with
  | Sum.inl err =>
      IO.println s!"FAIL: testBetweenQualified - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ (some (Expr.Between (Expr.QualifiedIdentifier "u" "score") _ _ false)) _ _ _ _ _ =>
          IO.println "PASS: testBetweenQualified"
      | _ =>
          IO.println s!"FAIL: testBetweenQualified - Unexpected parse result: {repr stmt}"

-- Test SELECT DISTINCT
def testSelectDistinct : IO Unit := do
  match parseSQL "SELECT DISTINCT name FROM users" with
  | Sum.inl err =>
      IO.println s!"FAIL: testSelectDistinct - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select true [SelectItem.Expr (Expr.Identifier "name") none] _ _ _ _ _ _ _ =>
          IO.println "PASS: testSelectDistinct"
      | _ =>
          IO.println s!"FAIL: testSelectDistinct - Unexpected parse result: {repr stmt}"

-- Test SELECT DISTINCT with multiple columns
def testSelectDistinctMultiple : IO Unit := do
  match parseSQL "SELECT DISTINCT name, email FROM users" with
  | Sum.inl err =>
      IO.println s!"FAIL: testSelectDistinctMultiple - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select true cols _ _ _ _ _ _ _ =>
          if cols.length == 2 then
            IO.println "PASS: testSelectDistinctMultiple"
          else
            IO.println s!"FAIL: testSelectDistinctMultiple - Expected 2 columns, got {cols.length}"
      | _ =>
          IO.println s!"FAIL: testSelectDistinctMultiple - Unexpected parse result: {repr stmt}"

-- Test SELECT without DISTINCT (should be false)
def testSelectNotDistinct : IO Unit := do
  match parseSQL "SELECT name FROM users" with
  | Sum.inl err =>
      IO.println s!"FAIL: testSelectNotDistinct - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select false _ _ _ _ _ _ _ _ =>
          IO.println "PASS: testSelectNotDistinct"
      | _ =>
          IO.println s!"FAIL: testSelectNotDistinct - Unexpected parse result: {repr stmt}"

-- Test SELECT DISTINCT with WHERE
def testSelectDistinctWhere : IO Unit := do
  match parseSQL "SELECT DISTINCT status FROM orders WHERE total > 100" with
  | Sum.inl err =>
      IO.println s!"FAIL: testSelectDistinctWhere - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select true _ _ (some _) _ _ _ _ _ =>
          IO.println "PASS: testSelectDistinctWhere"
      | _ =>
          IO.println s!"FAIL: testSelectDistinctWhere - Unexpected parse result: {repr stmt}"

-- Run all extended parser tests
def runExtendedParserTests : IO Unit := do
  IO.println "=== Running Extended Parser Tests ==="
  testSelectWithAlias
  testSelectTableAlias
  testSelectOrderBy
  testSelectOrderByDesc
  testSelectOrderByMultiple
  testSelectLimit
  testSelectLimitOffset
  testSelectFull
  testComplexWhere
  testWhereOr
  testWhereNot
  testWhereString
  testWhereNull
  testParenthesizedExpression
  -- Qualified star and multiple INSERT rows not yet implemented
  testInsertWithColumns
  testDeleteAll
  testDeleteComplexWhere
  testSelectWithoutFrom
  testMultipleColumnTypes
  testArithmeticInSelect
  testParserAllComparisonOperators
  testMixedCaseKeywords
  testEmptySQL
  testMissingSelectColumns
  testMissingWhereExpression
  testInvalidInsert
  testUnclosedParenthesis
  testInnerJoin
  testLeftJoin
  testLeftOuterJoin
  testRightJoin
  testPlainJoin
  testJoinWithAliases
  testMultipleJoins
  testJoinWithWhere
  testFullOuterJoin
  testCountStar
  testCountColumn
  testCountDistinct
  testSum
  testAvg
  testMinMax
  testAggregateWithAlias
  testMultipleAggregates
  testGroupBy
  testGroupByMultiple
  testGroupByHaving
  testGroupByFull
  testIsNull
  testIsNotNull
  testIsNullQualified
  testIsNullWithAnd
  testIsNullExpression
  testLike
  testLikePrefix
  testLikeWithAnd
  testLikeQualified
  testInIntegers
  testInStrings
  testNotIn
  testInWithAnd
  testInSingleValue
  testBetweenIntegers
  testBetweenStrings
  testNotBetween
  testBetweenWithAnd
  testBetweenQualified
  testSelectDistinct
  testSelectDistinctMultiple
  testSelectNotDistinct
  testSelectDistinctWhere
  IO.println ""

end SQLinLean.Tests
