-- Tests for SQL Parser
import SQLinLean.AST
import Tests.TestHelpers

namespace SQLinLean.Tests.Parser

open SQLinLean SQLinLean.Tests

def testSimpleSelect : IO Unit :=
  parseTest "testSimpleSelect" "SELECT * FROM users" fun
    | .Select _ [.AllColumns] (some (.Table "users" none)) none [] none [] none none => true
    | _ => false

def testSelectColumns : IO Unit :=
  parseTest "testSelectColumns" "SELECT name, age FROM users" fun
    | .Select _ [.Expr (.Identifier "name") none, .Expr (.Identifier "age") none]
        (some (.Table "users" none)) none [] none [] none none => true
    | _ => false

def testSelectWhere : IO Unit :=
  parseTest "testSelectWhere" "SELECT * FROM users WHERE age > 18" fun
    | .Select _ _ _ (some (.BinaryOp (.Identifier "age") .GreaterThan (.Literal (.Integer 18)))) _ _ _ _ _ => true
    | _ => false

def testInsert : IO Unit :=
  parseTest "testInsert" "INSERT INTO users VALUES (1, 'Alice')" fun
    | .Insert "users" [] [[.Literal (.Integer 1), .Literal (.String "Alice")]] => true
    | _ => false

def testDelete : IO Unit :=
  parseTest "testDelete" "DELETE FROM users WHERE id = 5" fun
    | .Delete "users" (some (.BinaryOp (.Identifier "id") .Equals (.Literal (.Integer 5)))) => true
    | _ => false

def testQualifiedIdentifier : IO Unit :=
  parseTest "testQualifiedIdentifier" "SELECT users.name FROM users" fun
    | .Select _ [.Expr (.QualifiedIdentifier "users" "name") none] _ _ _ _ _ _ _ => true
    | _ => false

def testMultipleWhere : IO Unit :=
  parseTest "testMultipleWhere" "SELECT * FROM users WHERE age > 18 AND status = 1" fun
    | .Select _ _ _ (some _) _ _ _ _ _ => true
    | _ => false

def testInvalidSQL : IO Unit := parseFailTest "testInvalidSQL" "INVALID SQL SYNTAX"
def testIncompleteSelect : IO Unit := parseFailTest "testIncompleteSelect" "SELECT * FROM"
def testIncompleteWhere : IO Unit := parseFailTest "testIncompleteWhere" "SELECT * FROM users WHERE"
def testMalformedInsert : IO Unit := parseFailTest "testMalformedInsert" "INSERT INTO users (name VALUES (1)"

def testArithmetic : IO Unit :=
  parseTest "testArithmetic" "SELECT * FROM products WHERE price * quantity > 100" fun
    | .Select _ _ _ (some _) _ _ _ _ _ => true
    | _ => false

def testArithmeticPrecedence : IO Unit :=
  parseTest "testArithmeticPrecedence" "SELECT * FROM items WHERE price + tax * rate > 50" fun
    | .Select _ _ _ (some _) _ _ _ _ _ => true
    | _ => false

-- Subquery tests
def testScalarSubquery : IO Unit :=
  parseTest "testScalarSubquery" "SELECT (SELECT MAX(age) FROM users) AS max_age" fun
    | .Select _ [.Expr (.Subquery _) (some "max_age")] none _ _ _ _ _ _ => true
    | _ => false

def testInSubquery : IO Unit :=
  parseTest "testInSubquery" "SELECT * FROM users WHERE id IN (SELECT user_id FROM orders)" fun
    | .Select _ _ _ (some (.InSubquery (.Identifier "id") _ false)) _ _ _ _ _ => true
    | _ => false

def testNotInSubquery : IO Unit :=
  parseTest "testNotInSubquery" "SELECT * FROM users WHERE id NOT IN (SELECT banned_id FROM banned)" fun
    | .Select _ _ _ (some (.InSubquery (.Identifier "id") _ true)) _ _ _ _ _ => true
    | _ => false

def testNestedSubquery : IO Unit :=
  parseTest "testNestedSubquery" "SELECT * FROM users WHERE age > (SELECT AVG(age) FROM users)" fun
    | .Select _ _ _ (some (.BinaryOp (.Identifier "age") .GreaterThan (.Subquery _))) _ _ _ _ _ => true
    | _ => false

-- Run all parser tests
def runParserTests : IO Unit := do
  IO.println "=== Running Parser Tests ==="
  testSimpleSelect
  testSelectColumns
  testSelectWhere
  testInsert
  testDelete
  testQualifiedIdentifier
  testMultipleWhere
  testInvalidSQL
  testIncompleteSelect
  testIncompleteWhere
  testMalformedInsert
  testArithmetic
  testArithmeticPrecedence
  -- Subquery tests
  testScalarSubquery
  testInSubquery
  testNotInSubquery
  testNestedSubquery
  IO.println ""

end SQLinLean.Tests.Parser
