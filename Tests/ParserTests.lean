-- Tests for SQL Parser
import SQLinLean.Parser
import SQLinLean.AST
import SQLinLean.Token

namespace SQLinLean.Tests

open SQLinLean

-- Test parsing simple SELECT
def testSimpleSelect : IO Unit := do
  match parseSQL "SELECT * FROM users" with
  | Sum.inl err => 
      IO.println s!"FAIL: testSimpleSelect - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select [SelectItem.AllColumns] (some (TableRef.Table "users" none)) none [] none [] none none =>
          IO.println "PASS: testSimpleSelect"
      | _ => 
          IO.println s!"FAIL: testSimpleSelect - Unexpected parse result: {repr stmt}"

-- Test parsing SELECT with columns
def testSelectColumns : IO Unit := do
  match parseSQL "SELECT name, age FROM users" with
  | Sum.inl err => 
      IO.println s!"FAIL: testSelectColumns - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select cols (some (TableRef.Table "users" none)) none [] none [] none none =>
          match cols with
          | [SelectItem.Expr (Expr.Identifier "name") none, 
             SelectItem.Expr (Expr.Identifier "age") none] =>
              IO.println "PASS: testSelectColumns"
          | _ => 
              IO.println s!"FAIL: testSelectColumns - Unexpected columns: {repr cols}"
      | _ => 
          IO.println s!"FAIL: testSelectColumns - Unexpected parse result: {repr stmt}"

-- Test parsing SELECT with WHERE
def testSelectWhere : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE age > 18" with
  | Sum.inl err => 
      IO.println s!"FAIL: testSelectWhere - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some whereClause) _ _ _ _ _ =>
          match whereClause with
          | Expr.BinaryOp (Expr.Identifier "age") Operator.GreaterThan (Expr.Literal (Literal.Integer 18)) =>
              IO.println "PASS: testSelectWhere"
          | _ => 
              IO.println s!"FAIL: testSelectWhere - Unexpected WHERE clause: {repr whereClause}"
      | _ => 
          IO.println s!"FAIL: testSelectWhere - Unexpected parse result: {repr stmt}"

-- Test parsing INSERT
def testInsert : IO Unit := do
  match parseSQL "INSERT INTO users VALUES (1, 'Alice')" with
  | Sum.inl err => 
      IO.println s!"FAIL: testInsert - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Insert "users" [] [[Expr.Literal (Literal.Integer 1), Expr.Literal (Literal.String "Alice")]] =>
          IO.println "PASS: testInsert"
      | _ => 
          IO.println s!"FAIL: testInsert - Unexpected parse result: {repr stmt}"

-- Test parsing DELETE
def testDelete : IO Unit := do
  match parseSQL "DELETE FROM users WHERE id = 5" with
  | Sum.inl err => 
      IO.println s!"FAIL: testDelete - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Delete "users" (some whereClause) =>
          match whereClause with
          | Expr.BinaryOp (Expr.Identifier "id") Operator.Equals (Expr.Literal (Literal.Integer 5)) =>
              IO.println "PASS: testDelete"
          | _ => 
              IO.println s!"FAIL: testDelete - Unexpected WHERE clause: {repr whereClause}"
      | _ => 
          IO.println s!"FAIL: testDelete - Unexpected parse result: {repr stmt}"

-- Test parsing SELECT with qualified identifiers
def testQualifiedIdentifier : IO Unit := do
  match parseSQL "SELECT users.name FROM users" with
  | Sum.inl err => 
      IO.println s!"FAIL: testQualifiedIdentifier - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select [SelectItem.Expr (Expr.QualifiedIdentifier "users" "name") none] _ _ _ _ _ _ _ =>
          IO.println "PASS: testQualifiedIdentifier"
      | _ => 
          IO.println s!"FAIL: testQualifiedIdentifier - Unexpected parse result: {repr stmt}"

-- Test parsing SELECT with multiple WHERE conditions
def testMultipleWhere : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE age > 18 AND status = 1" with
  | Sum.inl err => 
      IO.println s!"FAIL: testMultipleWhere - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some _) _ _ _ _ _ =>
          IO.println "PASS: testMultipleWhere"
      | _ => 
          IO.println s!"FAIL: testMultipleWhere - Unexpected parse result: {repr stmt}"

-- Test error handling
def testInvalidSQL : IO Unit := do
  match parseSQL "INVALID SQL SYNTAX" with
  | Sum.inl _ => 
      IO.println "PASS: testInvalidSQL"
  | Sum.inr stmt =>
      IO.println s!"FAIL: testInvalidSQL - Should have failed but got: {repr stmt}"

-- Test error handling: incomplete SELECT
def testIncompleteSelect : IO Unit := do
  match parseSQL "SELECT * FROM" with
  | Sum.inl _ => 
      IO.println "PASS: testIncompleteSelect"
  | Sum.inr stmt =>
      IO.println s!"FAIL: testIncompleteSelect - Should have failed but got: {repr stmt}"

-- Test error handling: incomplete WHERE
def testIncompleteWhere : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE" with
  | Sum.inl _ => 
      IO.println "PASS: testIncompleteWhere"
  | Sum.inr stmt =>
      IO.println s!"FAIL: testIncompleteWhere - Should have failed but got: {repr stmt}"

-- Test error handling: malformed INSERT
def testMalformedInsert : IO Unit := do
  match parseSQL "INSERT INTO users (name VALUES (1)" with
  | Sum.inl _ => 
      IO.println "PASS: testMalformedInsert"
  | Sum.inr stmt =>
      IO.println s!"FAIL: testMalformedInsert - Should have failed but got: {repr stmt}"

-- Test parsing arithmetic expressions
def testArithmetic : IO Unit := do
  match parseSQL "SELECT * FROM products WHERE price * quantity > 100" with
  | Sum.inl err => 
      IO.println s!"FAIL: testArithmetic - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some _) _ _ _ _ _ =>
          IO.println "PASS: testArithmetic"
      | _ => 
          IO.println s!"FAIL: testArithmetic - Unexpected parse result: {repr stmt}"

-- Test parsing complex arithmetic with precedence
def testArithmeticPrecedence : IO Unit := do
  match parseSQL "SELECT * FROM items WHERE price + tax * rate > 50" with
  | Sum.inl err => 
      IO.println s!"FAIL: testArithmeticPrecedence - {err}"
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some _) _ _ _ _ _ =>
          IO.println "PASS: testArithmeticPrecedence"
      | _ => 
          IO.println s!"FAIL: testArithmeticPrecedence - Unexpected parse result: {repr stmt}"

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
  IO.println ""

end SQLinLean.Tests
