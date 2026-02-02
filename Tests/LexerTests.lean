-- Tests for SQL Lexer
import SQLinLean.Token
import Tests.TestHelpers

namespace SQLinLean.Tests.Lexer

open SQLinLean SQLinLean.Tests

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

def testDoubleQuotedStrings : IO Unit :=
  lexTest "testDoubleQuotedStrings" "\"hello\" \"world\""
    [.Literal (.String "hello"), .Literal (.String "world"), .EOF]

def testMixedQuoteStrings : IO Unit :=
  lexTest "testMixedQuoteStrings" "'single' \"double\""
    [.Literal (.String "single"), .Literal (.String "double"), .EOF]

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
  testDoubleQuotedStrings
  testMixedQuoteStrings
  testOperators
  testKeywords
  testCaseInsensitivity
  IO.println ""

end SQLinLean.Tests.Lexer
