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
      | Statement.Select [SelectItem.Expr (Expr.Identifier "name") (some "user_name")] _ _ _ _ _ =>
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
      | Statement.Select [SelectItem.Expr (Expr.QualifiedIdentifier "u" "name") none] 
                        (some (TableRef.Table "users" (some "u"))) none _ _ _ =>
          IO.println "PASS: testSelectTableAlias"
      | _ => 
          IO.println s!"FAIL: testSelectTableAlias - Unexpected parse result: {repr stmt}"

-- Test SELECT with ORDER BY
def testSelectOrderBy : IO Unit := do
  match parseSQL "SELECT name FROM users ORDER BY name" with
  | Sum.inl err => 
      IO.println s!"FAIL: testSelectOrderBy - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ orderBy _ _ =>
          if orderBy.length > 0 then
            IO.println "PASS: testSelectOrderBy"
          else
            IO.println s!"FAIL: testSelectOrderBy - No ORDER BY clause found"
      | _ => 
          IO.println s!"FAIL: testSelectOrderBy - Not a SELECT statement: {repr stmt}"

-- Test SELECT with LIMIT
def testSelectLimit : IO Unit := do
  match parseSQL "SELECT * FROM users LIMIT 10" with
  | Sum.inl err => 
      IO.println s!"FAIL: testSelectLimit - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ _ (some 10) _ =>
          IO.println "PASS: testSelectLimit"
      | _ => 
          IO.println s!"FAIL: testSelectLimit - Unexpected parse result: {repr stmt}"

-- Test SELECT with LIMIT and OFFSET
def testSelectLimitOffset : IO Unit := do
  match parseSQL "SELECT * FROM users LIMIT 10 OFFSET 20" with
  | Sum.inl err => 
      IO.println s!"FAIL: testSelectLimitOffset - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ _ (some 10) (some 20) =>
          IO.println "PASS: testSelectLimitOffset"
      | _ => 
          IO.println s!"FAIL: testSelectLimitOffset - Unexpected parse result: {repr stmt}"

-- Test SELECT with complex WHERE (multiple ANDs)
def testComplexWhere : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE age > 18 AND status = 1 AND active = 1" with
  | Sum.inl err => 
      IO.println s!"FAIL: testComplexWhere - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some _) _ _ _ =>
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
      | Statement.Select _ _ (some _) _ _ _ =>
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
      | Statement.Select _ _ (some (Expr.Not _)) _ _ _ =>
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
      | Statement.Select _ _ (some (Expr.BinaryOp _ _ (Expr.Literal (Literal.String "Alice")))) _ _ _ =>
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
      | Statement.Select _ _ (some (Expr.BinaryOp _ _ (Expr.Literal Literal.Null))) _ _ _ =>
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
      | Statement.Select _ _ (some _) _ _ _ =>
          IO.println "PASS: testParenthesizedExpression"
      | _ => 
          IO.println s!"FAIL: testParenthesizedExpression - Unexpected parse result: {repr stmt}"

-- Test SELECT with qualified star (table.*)
def testQualifiedStar : IO Unit := do
  match parseSQL "SELECT users.* FROM users" with
  | Sum.inl err => 
      IO.println s!"FAIL: testQualifiedStar - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select [SelectItem.Expr (Expr.QualifiedStar "users") none] _ _ _ _ _ =>
          IO.println "PASS: testQualifiedStar"
      | _ => 
          IO.println s!"FAIL: testQualifiedStar - Unexpected parse result: {repr stmt}"

-- Test INSERT with multiple rows
def testInsertMultipleRows : IO Unit := do
  match parseSQL "INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob')" with
  | Sum.inl err => 
      IO.println s!"FAIL: testInsertMultipleRows - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Insert "users" [] values =>
          if values.length == 2 then
            IO.println "PASS: testInsertMultipleRows"
          else
            IO.println s!"FAIL: testInsertMultipleRows - Expected 2 rows, got {values.length}"
      | _ => 
          IO.println s!"FAIL: testInsertMultipleRows - Unexpected parse result: {repr stmt}"

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
      | Statement.Select [SelectItem.Expr (Expr.Literal (Literal.Integer 1)) none] none _ _ _ _ =>
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
      | Statement.Select cols _ _ _ _ _ =>
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
      | Statement.Select cols _ _ _ _ _ =>
          if cols.length == 2 then
            IO.println "PASS: testArithmeticInSelect"
          else
            IO.println s!"FAIL: testArithmeticInSelect - Expected 2 columns, got {cols.length}"
      | _ => 
          IO.println s!"FAIL: testArithmeticInSelect - Not a SELECT: {repr stmt}"

-- Test WHERE with all comparison operators
def testAllComparisonOperators : IO Unit := do
  match parseSQL "SELECT * FROM t WHERE a = 1" with
  | Sum.inl err => 
      IO.println s!"FAIL: testAllComparisonOperators(=) - {err}"
  | Sum.inr _ =>
      match parseSQL "SELECT * FROM t WHERE a != 1" with
      | Sum.inl err => 
          IO.println s!"FAIL: testAllComparisonOperators(!=) - {err}"
      | Sum.inr _ =>
          match parseSQL "SELECT * FROM t WHERE a < 1" with
          | Sum.inl err => 
              IO.println s!"FAIL: testAllComparisonOperators(<) - {err}"
          | Sum.inr _ =>
              match parseSQL "SELECT * FROM t WHERE a > 1" with
              | Sum.inl err => 
                  IO.println s!"FAIL: testAllComparisonOperators(>) - {err}"
              | Sum.inr _ =>
                  match parseSQL "SELECT * FROM t WHERE a <= 1" with
                  | Sum.inl err => 
                      IO.println s!"FAIL: testAllComparisonOperators(<=) - {err}"
                  | Sum.inr _ =>
                      match parseSQL "SELECT * FROM t WHERE a >= 1" with
                      | Sum.inl err => 
                          IO.println s!"FAIL: testAllComparisonOperators(>=) - {err}"
                      | Sum.inr _ =>
                          IO.println "PASS: testAllComparisonOperators"

-- Test case sensitivity with mixed case
def testMixedCaseKeywords : IO Unit := do
  match parseSQL "SeLeCt * FrOm UsErS wHeRe AgE > 18" with
  | Sum.inl err => 
      IO.println s!"FAIL: testMixedCaseKeywords - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ (some (TableRef.Table "UsErS" none)) (some _) _ _ _ =>
          IO.println "PASS: testMixedCaseKeywords"
      | _ => 
          IO.println s!"FAIL: testMixedCaseKeywords - Unexpected parse result: {repr stmt}"

-- Test ORDER BY with DESC
def testOrderByDesc : IO Unit := do
  match parseSQL "SELECT * FROM users ORDER BY age DESC" with
  | Sum.inl err => 
      IO.println s!"FAIL: testOrderByDesc - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ orderBy _ _ =>
          match orderBy with
          | [(_, false)] =>  -- false = descending
              IO.println "PASS: testOrderByDesc"
          | _ => 
              IO.println s!"FAIL: testOrderByDesc - Expected DESC order: {repr orderBy}"
      | _ => 
          IO.println s!"FAIL: testOrderByDesc - Not a SELECT: {repr stmt}"

-- Test ORDER BY with multiple columns
def testOrderByMultiple : IO Unit := do
  match parseSQL "SELECT * FROM users ORDER BY age DESC, name" with
  | Sum.inl err => 
      IO.println s!"FAIL: testOrderByMultiple - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ _ orderBy _ _ =>
          if orderBy.length == 2 then
            IO.println "PASS: testOrderByMultiple"
          else
            IO.println s!"FAIL: testOrderByMultiple - Expected 2 order columns, got {orderBy.length}"
      | _ => 
          IO.println s!"FAIL: testOrderByMultiple - Not a SELECT: {repr stmt}"

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

-- Run all extended parser tests
def runExtendedParserTests : IO Unit := do
  IO.println "=== Running Extended Parser Tests ==="
  testSelectWithAlias
  testSelectTableAlias
  testSelectOrderBy
  testSelectLimit
  testSelectLimitOffset
  testComplexWhere
  testWhereOr
  testWhereNot
  testWhereString
  testWhereNull
  testParenthesizedExpression
  testQualifiedStar
  testInsertMultipleRows
  testInsertWithColumns
  testDeleteAll
  testDeleteComplexWhere
  testSelectWithoutFrom
  testMultipleColumnTypes
  testArithmeticInSelect
  testAllComparisonOperators
  testMixedCaseKeywords
  testOrderByDesc
  testOrderByMultiple
  testEmptySQL
  testMissingSelectColumns
  testMissingWhereExpression
  testInvalidInsert
  testUnclosedParenthesis
  IO.println ""

end SQLinLean.Tests
