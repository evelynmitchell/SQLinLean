-- Extended Parser Tests inspired by sqlglot test suite
import SQLinLean.Parser
import SQLinLean.AST
import SQLinLean.Token

namespace SQLinLean.Tests

open SQLinLean

-- Test helpers (same as ParserTests.lean)
def parseTest (name : String) (input : String) (validate : Statement → Bool) : IO Unit := do
  match parseSQL input with
  | Sum.inl err => IO.println s!"FAIL: {name} - {err}"
  | Sum.inr stmt =>
      if validate stmt then IO.println s!"PASS: {name}"
      else IO.println s!"FAIL: {name} - Got {repr stmt}"

def parseFailTest (name : String) (input : String) : IO Unit := do
  match parseSQL input with
  | Sum.inl _ => IO.println s!"PASS: {name}"
  | Sum.inr stmt => IO.println s!"FAIL: {name} - Should have failed but got: {repr stmt}"

-- Column alias tests
def testSelectWithAlias : IO Unit :=
  parseTest "testSelectWithAlias" "SELECT name AS user_name FROM users" fun
    | .Select _ [.Expr (.Identifier "name") (some "user_name")] _ _ _ _ _ _ _ => true
    | _ => false

def testSelectTableAlias : IO Unit :=
  parseTest "testSelectTableAlias" "SELECT u.name FROM users AS u" fun
    | .Select _ [.Expr (.QualifiedIdentifier "u" "name") none] (some (.Table "users" (some "u"))) _ _ _ _ _ _ => true
    | _ => false

-- ORDER BY tests
def testSelectOrderBy : IO Unit :=
  parseTest "testSelectOrderBy" "SELECT * FROM users ORDER BY name" fun
    | .Select _ _ _ _ _ _ orderBy _ _ => orderBy.length == 1
    | _ => false

def testSelectOrderByDesc : IO Unit :=
  parseTest "testSelectOrderByDesc" "SELECT * FROM users ORDER BY age DESC" fun
    | .Select _ _ _ _ _ _ [(_, false)] _ _ => true
    | _ => false

def testSelectOrderByMultiple : IO Unit :=
  parseTest "testSelectOrderByMultiple" "SELECT * FROM users ORDER BY name ASC, age DESC" fun
    | .Select _ _ _ _ _ _ orderBy _ _ => orderBy.length == 2
    | _ => false

-- LIMIT/OFFSET tests
def testSelectLimit : IO Unit :=
  parseTest "testSelectLimit" "SELECT * FROM users LIMIT 10" fun
    | .Select _ _ _ _ _ _ _ (some 10) _ => true
    | _ => false

def testSelectLimitOffset : IO Unit :=
  parseTest "testSelectLimitOffset" "SELECT * FROM users LIMIT 10 OFFSET 20" fun
    | .Select _ _ _ _ _ _ _ (some 10) (some 20) => true
    | _ => false

def testSelectFull : IO Unit :=
  parseTest "testSelectFull" "SELECT name, age FROM users WHERE active = 1 ORDER BY name LIMIT 10 OFFSET 5" fun
    | .Select _ cols (some _) (some _) _ _ orderBy (some 10) (some 5) => cols.length == 2 && orderBy.length == 1
    | _ => false

-- WHERE tests
def testComplexWhere : IO Unit :=
  parseTest "testComplexWhere" "SELECT * FROM users WHERE age > 18 AND status = 1 AND active = 1" fun
    | .Select _ _ _ (some _) _ _ _ _ _ => true
    | _ => false

def testWhereOr : IO Unit :=
  parseTest "testWhereOr" "SELECT * FROM users WHERE age < 18 OR age > 65" fun
    | .Select _ _ _ (some _) _ _ _ _ _ => true
    | _ => false

def testWhereNot : IO Unit :=
  parseTest "testWhereNot" "SELECT * FROM users WHERE NOT deleted" fun
    | .Select _ _ _ (some (.Not _)) _ _ _ _ _ => true
    | _ => false

def testWhereString : IO Unit :=
  parseTest "testWhereString" "SELECT * FROM users WHERE name = 'Alice'" fun
    | .Select _ _ _ (some (.BinaryOp _ _ (.Literal (.String "Alice")))) _ _ _ _ _ => true
    | _ => false

def testWhereNull : IO Unit :=
  parseTest "testWhereNull" "SELECT * FROM users WHERE email = NULL" fun
    | .Select _ _ _ (some (.BinaryOp _ _ (.Literal .Null))) _ _ _ _ _ => true
    | _ => false

def testParenthesizedExpression : IO Unit :=
  parseTest "testParenthesizedExpression" "SELECT * FROM items WHERE (price + tax) > 100" fun
    | .Select _ _ _ (some _) _ _ _ _ _ => true
    | _ => false

-- INSERT/DELETE tests
def testInsertWithColumns : IO Unit :=
  parseTest "testInsertWithColumns" "INSERT INTO users (name, age) VALUES ('Alice', 30)" fun
    | .Insert "users" ["name", "age"] _ => true
    | _ => false

def testDeleteAll : IO Unit :=
  parseTest "testDeleteAll" "DELETE FROM users" fun
    | .Delete "users" none => true
    | _ => false

def testDeleteComplexWhere : IO Unit :=
  parseTest "testDeleteComplexWhere" "DELETE FROM users WHERE age > 100 AND status = 0" fun
    | .Delete "users" (some _) => true
    | _ => false

-- Edge cases
def testSelectWithoutFrom : IO Unit :=
  parseTest "testSelectWithoutFrom" "SELECT 1" fun
    | .Select _ [.Expr (.Literal (.Integer 1)) none] none _ _ _ _ _ _ => true
    | _ => false

def testMultipleColumnTypes : IO Unit :=
  parseTest "testMultipleColumnTypes" "SELECT id, name, 3.14, 'text', NULL FROM users" fun
    | .Select _ cols _ _ _ _ _ _ _ => cols.length == 5
    | _ => false

def testArithmeticInSelect : IO Unit :=
  parseTest "testArithmeticInSelect" "SELECT price * 1.1, quantity + 1 FROM products" fun
    | .Select _ cols _ _ _ _ _ _ _ => cols.length == 2
    | _ => false

def testParserAllComparisonOperators : IO Unit := do
  let ops := ["=", "!=", "<", ">", "<=", ">="]
  for op in ops do
    match parseSQL s!"SELECT * FROM t WHERE a {op} 1" with
    | Sum.inl err => IO.println s!"FAIL: testParserAllComparisonOperators({op}) - {err}"; return
    | Sum.inr _ => pure ()
  IO.println "PASS: testParserAllComparisonOperators"

def testMixedCaseKeywords : IO Unit :=
  parseTest "testMixedCaseKeywords" "SeLeCt * FrOm UsErS wHeRe AgE > 18" fun
    | .Select _ _ (some (.Table "UsErS" none)) (some _) _ _ _ _ _ => true
    | _ => false

-- Error cases
def testEmptySQL : IO Unit := parseFailTest "testEmptySQL" ""
def testMissingSelectColumns : IO Unit := parseFailTest "testMissingSelectColumns" "SELECT FROM users"
def testMissingWhereExpression : IO Unit := parseFailTest "testMissingWhereExpression" "SELECT * FROM users WHERE"
def testInvalidInsert : IO Unit := parseFailTest "testInvalidInsert" "INSERT INTO users"
def testUnclosedParenthesis : IO Unit := parseFailTest "testUnclosedParenthesis" "INSERT INTO users VALUES (1, 'Alice'"

-- JOIN tests
def testInnerJoin : IO Unit :=
  parseTest "testInnerJoin" "SELECT * FROM users INNER JOIN orders ON users.id = orders.user_id" fun
    | .Select _ _ (some (.Join _ .Inner _ _)) _ _ _ _ _ _ => true
    | _ => false

def testLeftJoin : IO Unit :=
  parseTest "testLeftJoin" "SELECT * FROM users LEFT JOIN orders ON users.id = orders.user_id" fun
    | .Select _ _ (some (.Join _ .Left _ _)) _ _ _ _ _ _ => true
    | _ => false

def testLeftOuterJoin : IO Unit :=
  parseTest "testLeftOuterJoin" "SELECT * FROM users LEFT OUTER JOIN orders ON users.id = orders.user_id" fun
    | .Select _ _ (some (.Join _ .Left _ _)) _ _ _ _ _ _ => true
    | _ => false

def testRightJoin : IO Unit :=
  parseTest "testRightJoin" "SELECT * FROM users RIGHT JOIN orders ON users.id = orders.user_id" fun
    | .Select _ _ (some (.Join _ .Right _ _)) _ _ _ _ _ _ => true
    | _ => false

def testPlainJoin : IO Unit :=
  parseTest "testPlainJoin" "SELECT * FROM users JOIN orders ON users.id = orders.user_id" fun
    | .Select _ _ (some (.Join _ .Inner _ _)) _ _ _ _ _ _ => true
    | _ => false

def testJoinWithAliases : IO Unit :=
  parseTest "testJoinWithAliases" "SELECT u.name, o.total FROM users AS u JOIN orders AS o ON u.id = o.user_id" fun
    | .Select _ cols (some (.Join (.Table "users" (some "u")) .Inner (.Table "orders" (some "o")) _)) _ _ _ _ _ _ => cols.length == 2
    | _ => false

def testMultipleJoins : IO Unit :=
  parseTest "testMultipleJoins" "SELECT * FROM a JOIN b ON a.id = b.a_id JOIN c ON b.id = c.b_id" fun
    | .Select _ _ (some (.Join (.Join _ _ _ _) _ _ _)) _ _ _ _ _ _ => true
    | _ => false

def testJoinWithWhere : IO Unit :=
  parseTest "testJoinWithWhere" "SELECT * FROM users u JOIN orders o ON u.id = o.user_id WHERE o.total > 100" fun
    | .Select _ _ (some (.Join _ _ _ _)) (some _) _ _ _ _ _ => true
    | _ => false

def testFullOuterJoin : IO Unit :=
  parseTest "testFullOuterJoin" "SELECT * FROM a FULL OUTER JOIN b ON a.id = b.a_id" fun
    | .Select _ _ (some (.Join _ .Full _ _)) _ _ _ _ _ _ => true
    | _ => false

-- Aggregate tests
def testCountStar : IO Unit :=
  parseTest "testCountStar" "SELECT COUNT(*) FROM users" fun
    | .Select _ [.Expr (.Aggregate .Count .Star false) none] _ _ _ _ _ _ _ => true
    | _ => false

def testCountColumn : IO Unit :=
  parseTest "testCountColumn" "SELECT COUNT(id) FROM users" fun
    | .Select _ [.Expr (.Aggregate .Count (.Identifier "id") false) none] _ _ _ _ _ _ _ => true
    | _ => false

def testCountDistinct : IO Unit :=
  parseTest "testCountDistinct" "SELECT COUNT(DISTINCT email) FROM users" fun
    | .Select _ [.Expr (.Aggregate .Count (.Identifier "email") true) none] _ _ _ _ _ _ _ => true
    | _ => false

def testSum : IO Unit :=
  parseTest "testSum" "SELECT SUM(amount) FROM orders" fun
    | .Select _ [.Expr (.Aggregate .Sum _ false) none] _ _ _ _ _ _ _ => true
    | _ => false

def testAvg : IO Unit :=
  parseTest "testAvg" "SELECT AVG(price) FROM products" fun
    | .Select _ [.Expr (.Aggregate .Avg _ false) none] _ _ _ _ _ _ _ => true
    | _ => false

def testMinMax : IO Unit :=
  parseTest "testMinMax" "SELECT MIN(price), MAX(price) FROM products" fun
    | .Select _ [.Expr (.Aggregate .Min _ _) _, .Expr (.Aggregate .Max _ _) _] _ _ _ _ _ _ _ => true
    | _ => false

def testAggregateWithAlias : IO Unit :=
  parseTest "testAggregateWithAlias" "SELECT COUNT(*) AS total FROM users" fun
    | .Select _ [.Expr (.Aggregate .Count .Star false) (some "total")] _ _ _ _ _ _ _ => true
    | _ => false

def testMultipleAggregates : IO Unit :=
  parseTest "testMultipleAggregates" "SELECT COUNT(*), SUM(amount), AVG(price) FROM orders" fun
    | .Select _ cols _ _ _ _ _ _ _ => cols.length == 3
    | _ => false

-- GROUP BY tests
def testGroupBy : IO Unit :=
  parseTest "testGroupBy" "SELECT status, COUNT(*) FROM orders GROUP BY status" fun
    | .Select _ _ _ _ groupBy _ _ _ _ => groupBy.length == 1
    | _ => false

def testGroupByMultiple : IO Unit :=
  parseTest "testGroupByMultiple" "SELECT year, month, SUM(amount) FROM orders GROUP BY year, month" fun
    | .Select _ _ _ _ groupBy _ _ _ _ => groupBy.length == 2
    | _ => false

def testGroupByHaving : IO Unit :=
  parseTest "testGroupByHaving" "SELECT status, COUNT(*) FROM orders GROUP BY status HAVING COUNT(*) > 10" fun
    | .Select _ _ _ _ groupBy (some _) _ _ _ => groupBy.length == 1
    | _ => false

def testGroupByFull : IO Unit :=
  parseTest "testGroupByFull" "SELECT status, COUNT(*) FROM orders WHERE year > 2020 GROUP BY status HAVING COUNT(*) > 5 ORDER BY status LIMIT 10" fun
    | .Select _ _ _ (some _) groupBy (some _) orderBy (some 10) _ => groupBy.length == 1 && orderBy.length == 1
    | _ => false

-- IS NULL tests
def testIsNull : IO Unit :=
  parseTest "testIsNull" "SELECT * FROM users WHERE email IS NULL" fun
    | .Select _ _ _ (some (.IsNull (.Identifier "email") false)) _ _ _ _ _ => true
    | _ => false

def testIsNotNull : IO Unit :=
  parseTest "testIsNotNull" "SELECT * FROM users WHERE email IS NOT NULL" fun
    | .Select _ _ _ (some (.IsNull (.Identifier "email") true)) _ _ _ _ _ => true
    | _ => false

def testIsNullQualified : IO Unit :=
  parseTest "testIsNullQualified" "SELECT * FROM users u WHERE u.email IS NULL" fun
    | .Select _ _ _ (some (.IsNull (.QualifiedIdentifier "u" "email") false)) _ _ _ _ _ => true
    | _ => false

def testIsNullWithAnd : IO Unit :=
  parseTest "testIsNullWithAnd" "SELECT * FROM users WHERE email IS NULL AND status = 1" fun
    | .Select _ _ _ (some _) _ _ _ _ _ => true
    | _ => false

def testIsNullExpression : IO Unit :=
  parseTest "testIsNullExpression" "SELECT * FROM users WHERE (first_name IS NULL) OR (last_name IS NULL)" fun
    | .Select _ _ _ (some _) _ _ _ _ _ => true
    | _ => false

-- LIKE tests
def testLike : IO Unit :=
  parseTest "testLike" "SELECT * FROM users WHERE name LIKE '%john%'" fun
    | .Select _ _ _ (some (.BinaryOp (.Identifier "name") .Like (.Literal (.String "%john%")))) _ _ _ _ _ => true
    | _ => false

def testLikePrefix : IO Unit :=
  parseTest "testLikePrefix" "SELECT * FROM products WHERE name LIKE 'Apple%'" fun
    | .Select _ _ _ (some (.BinaryOp _ .Like _)) _ _ _ _ _ => true
    | _ => false

def testLikeWithAnd : IO Unit :=
  parseTest "testLikeWithAnd" "SELECT * FROM users WHERE name LIKE '%john%' AND status = 1" fun
    | .Select _ _ _ (some _) _ _ _ _ _ => true
    | _ => false

def testLikeQualified : IO Unit :=
  parseTest "testLikeQualified" "SELECT * FROM users u WHERE u.name LIKE '%test%'" fun
    | .Select _ _ _ (some (.BinaryOp (.QualifiedIdentifier "u" "name") .Like _)) _ _ _ _ _ => true
    | _ => false

-- IN tests
def testInIntegers : IO Unit :=
  parseTest "testInIntegers" "SELECT * FROM users WHERE id IN (1, 2, 3)" fun
    | .Select _ _ _ (some (.In (.Identifier "id") values false)) _ _ _ _ _ => values.length == 3
    | _ => false

def testInStrings : IO Unit :=
  parseTest "testInStrings" "SELECT * FROM users WHERE status IN ('active', 'pending')" fun
    | .Select _ _ _ (some (.In (.Identifier "status") values false)) _ _ _ _ _ => values.length == 2
    | _ => false

def testNotIn : IO Unit :=
  parseTest "testNotIn" "SELECT * FROM users WHERE status NOT IN ('deleted', 'banned')" fun
    | .Select _ _ _ (some (.In (.Identifier "status") _ true)) _ _ _ _ _ => true
    | _ => false

def testInWithAnd : IO Unit :=
  parseTest "testInWithAnd" "SELECT * FROM users WHERE id IN (1, 2) AND status = 1" fun
    | .Select _ _ _ (some _) _ _ _ _ _ => true
    | _ => false

def testInSingleValue : IO Unit :=
  parseTest "testInSingleValue" "SELECT * FROM users WHERE id IN (42)" fun
    | .Select _ _ _ (some (.In _ values false)) _ _ _ _ _ => values.length == 1
    | _ => false

-- BETWEEN tests
def testBetweenIntegers : IO Unit :=
  parseTest "testBetweenIntegers" "SELECT * FROM users WHERE age BETWEEN 18 AND 65" fun
    | .Select _ _ _ (some (.Between (.Identifier "age") (.Literal (.Integer 18)) (.Literal (.Integer 65)) false)) _ _ _ _ _ => true
    | _ => false

def testBetweenStrings : IO Unit :=
  parseTest "testBetweenStrings" "SELECT * FROM products WHERE name BETWEEN 'A' AND 'M'" fun
    | .Select _ _ _ (some (.Between _ _ _ false)) _ _ _ _ _ => true
    | _ => false

def testNotBetween : IO Unit :=
  parseTest "testNotBetween" "SELECT * FROM users WHERE age NOT BETWEEN 0 AND 17" fun
    | .Select _ _ _ (some (.Between _ _ _ true)) _ _ _ _ _ => true
    | _ => false

def testBetweenWithAnd : IO Unit :=
  parseTest "testBetweenWithAnd" "SELECT * FROM users WHERE age BETWEEN 18 AND 65 AND status = 1" fun
    | .Select _ _ _ (some _) _ _ _ _ _ => true
    | _ => false

def testBetweenQualified : IO Unit :=
  parseTest "testBetweenQualified" "SELECT * FROM users u WHERE u.age BETWEEN 18 AND 65" fun
    | .Select _ _ _ (some (.Between (.QualifiedIdentifier "u" "age") _ _ false)) _ _ _ _ _ => true
    | _ => false

-- DISTINCT tests
def testSelectDistinct : IO Unit :=
  parseTest "testSelectDistinct" "SELECT DISTINCT status FROM orders" fun
    | .Select true _ _ _ _ _ _ _ _ => true
    | _ => false

def testSelectDistinctMultiple : IO Unit :=
  parseTest "testSelectDistinctMultiple" "SELECT DISTINCT status, category FROM orders" fun
    | .Select true cols _ _ _ _ _ _ _ => cols.length == 2
    | _ => false

def testSelectNotDistinct : IO Unit :=
  parseTest "testSelectNotDistinct" "SELECT status FROM orders" fun
    | .Select false _ _ _ _ _ _ _ _ => true
    | _ => false

def testSelectDistinctWhere : IO Unit :=
  parseTest "testSelectDistinctWhere" "SELECT DISTINCT status FROM orders WHERE total > 100" fun
    | .Select true _ _ (some _) _ _ _ _ _ => true
    | _ => false

-- Run all extended parser tests
def runExtendedParserTests : IO Unit := do
  IO.println "=== Running Extended Parser Tests ==="
  testSelectWithAlias; testSelectTableAlias
  testSelectOrderBy; testSelectOrderByDesc; testSelectOrderByMultiple
  testSelectLimit; testSelectLimitOffset; testSelectFull
  testComplexWhere; testWhereOr; testWhereNot; testWhereString; testWhereNull
  testParenthesizedExpression
  testInsertWithColumns; testDeleteAll; testDeleteComplexWhere
  testSelectWithoutFrom; testMultipleColumnTypes; testArithmeticInSelect
  testParserAllComparisonOperators; testMixedCaseKeywords
  testEmptySQL; testMissingSelectColumns; testMissingWhereExpression
  testInvalidInsert; testUnclosedParenthesis
  testInnerJoin; testLeftJoin; testLeftOuterJoin; testRightJoin; testPlainJoin
  testJoinWithAliases; testMultipleJoins; testJoinWithWhere; testFullOuterJoin
  testCountStar; testCountColumn; testCountDistinct; testSum; testAvg
  testMinMax; testAggregateWithAlias; testMultipleAggregates
  testGroupBy; testGroupByMultiple; testGroupByHaving; testGroupByFull
  testIsNull; testIsNotNull; testIsNullQualified; testIsNullWithAnd; testIsNullExpression
  testLike; testLikePrefix; testLikeWithAnd; testLikeQualified
  testInIntegers; testInStrings; testNotIn; testInWithAnd; testInSingleValue
  testBetweenIntegers; testBetweenStrings; testNotBetween; testBetweenWithAnd; testBetweenQualified
  testSelectDistinct; testSelectDistinctMultiple; testSelectNotDistinct; testSelectDistinctWhere
  IO.println ""

end SQLinLean.Tests
