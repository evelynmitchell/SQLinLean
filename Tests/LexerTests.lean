-- Tests for SQL Lexer
import SQLinLean.Lexer
import SQLinLean.Token

namespace SQLinLean.Tests

open SQLinLean

-- Test helper: tokenize and compare expected tokens
def lexTest (name : String) (input : String) (expected : List Token) : IO Unit := do
  match tokenizeString input with
  | LexerResult.error msg _ => IO.println s!"FAIL: {name} - {msg}"
  | LexerResult.ok tokens _ =>
      if tokens == expected then IO.println s!"PASS: {name}"
      else IO.println s!"FAIL: {name} - Expected {repr expected}, got {repr tokens}"

-- Test helper: tokenize and validate with custom predicate
def lexTestWith (name : String) (input : String) (validate : List Token → Bool) : IO Unit := do
  match tokenizeString input with
  | LexerResult.error msg _ => IO.println s!"FAIL: {name} - {msg}"
  | LexerResult.ok tokens _ =>
      if validate tokens then IO.println s!"PASS: {name}"
      else IO.println s!"FAIL: {name} - Got {repr tokens}"

def testSelectTokens : IO Unit :=
  lexTest "testSelectTokens" "SELECT * FROM users"
    [.Keyword .SELECT, .Star, .Keyword .FROM, .Identifier "users", .EOF]

def testNumbers : IO Unit :=
  lexTest "testNumbers" "42 100"
    [.Literal (.Integer 42), .Literal (.Integer 100), .EOF]

def testFloats : IO Unit :=
  lexTestWith "testFloats" "3.14 2.5" fun
    | [.Literal (.Float _), .Literal (.Float _), .EOF] => true
    | _ => false

def testNegativeNumbers : IO Unit :=
  lexTestWith "testNegativeNumbers" "-5 -3.14" fun
    | [.Operator .Minus, .Literal (.Integer 5), .Operator .Minus, .Literal (.Float _), .EOF] => true
    | _ => false

def testStrings : IO Unit :=
  lexTest "testStrings" "'hello' 'world'"
    [.Literal (.String "hello"), .Literal (.String "world"), .EOF]

def testOperators : IO Unit :=
  lexTest "testOperators" "= != < > <= >= + - * /"
    [.Operator .Equals, .Operator .NotEquals, .Operator .LessThan, .Operator .GreaterThan,
     .Operator .LessOrEqual, .Operator .GreaterOrEqual, .Operator .Plus, .Operator .Minus,
     .Star, .Operator .Divide, .EOF]

def testKeywords : IO Unit :=
  lexTest "testKeywords" "SELECT INSERT UPDATE DELETE WHERE FROM"
    [.Keyword .SELECT, .Keyword .INSERT, .Keyword .UPDATE,
     .Keyword .DELETE, .Keyword .WHERE, .Keyword .FROM, .EOF]

def testCaseInsensitivity : IO Unit :=
  lexTest "testCaseInsensitivity" "select SELECT SeLeCt"
    [.Keyword .SELECT, .Keyword .SELECT, .Keyword .SELECT, .EOF]

-- Run all lexer tests
def runLexerTests : IO Unit := do
  IO.println "=== Running Lexer Tests ==="
  testSelectTokens
  testNumbers
  testFloats
  testNegativeNumbers
  testStrings
  testOperators
  testKeywords
  testCaseInsensitivity
  IO.println ""

end SQLinLean.Tests
