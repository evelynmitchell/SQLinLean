-- Extended Lexer Tests inspired by sqlglot test suite
import SQLinLean.Lexer
import SQLinLean.Token

namespace SQLinLean.Tests

open SQLinLean

-- Test helpers (same as LexerTests.lean)
def lexTest (name : String) (input : String) (expected : List Token) : IO Unit := do
  match tokenizeString input with
  | LexerResult.error msg _ => IO.println s!"FAIL: {name} - {msg}"
  | LexerResult.ok tokens _ =>
      if tokens == expected then IO.println s!"PASS: {name}"
      else IO.println s!"FAIL: {name} - Expected {repr expected}, got {repr tokens}"

def lexTestWith (name : String) (input : String) (validate : List Token → Bool) : IO Unit := do
  match tokenizeString input with
  | LexerResult.error msg _ => IO.println s!"FAIL: {name} - {msg}"
  | LexerResult.ok tokens _ =>
      if validate tokens then IO.println s!"PASS: {name}"
      else IO.println s!"FAIL: {name} - Got {repr tokens}"

def lexFailTest (name : String) (input : String) : IO Unit := do
  match tokenizeString input with
  | LexerResult.error _ _ => IO.println s!"PASS: {name}"
  | LexerResult.ok tokens _ => IO.println s!"FAIL: {name} - Should have failed but got: {repr tokens}"

def testWhitespaceVariations : IO Unit :=
  lexTest "testWhitespaceVariations" "SELECT  \t  *  \n  FROM\r\n  users"
    [.Keyword .SELECT, .Star, .Keyword .FROM, .Identifier "users", .EOF]

def testMultipleOperators : IO Unit :=
  lexTest "testMultipleOperators" "<> <= >= !="
    [.Operator .NotEquals, .Operator .LessOrEqual, .Operator .GreaterOrEqual, .Operator .NotEquals, .EOF]

def testStringEscapes : IO Unit :=
  lexTestWith "testStringEscapes" "'hello\\nworld'" fun
    | [.Literal (.String s), .EOF] => s.contains '\n'
    | _ => false

def testEmptyString : IO Unit :=
  lexTest "testEmptyString" "''" [.Literal (.String ""), .EOF]

def testUnterminatedString : IO Unit := lexFailTest "testUnterminatedString" "'unterminated"

def testSemicolon : IO Unit :=
  lexTest "testSemicolon" "SELECT 1;"
    [.Keyword .SELECT, .Literal (.Integer 1), .Semicolon, .EOF]

def testMultipleStatements : IO Unit :=
  lexTestWith "testMultipleStatements" "SELECT 1; SELECT 2;" fun tokens => tokens.length == 7

def testParentheses : IO Unit :=
  lexTest "testParentheses" "SELECT (1, 2)"
    [.Keyword .SELECT, .LeftParen, .Literal (.Integer 1), .Comma, .Literal (.Integer 2), .RightParen, .EOF]

def testDotOperator : IO Unit :=
  lexTest "testDotOperator" "users.name"
    [.Identifier "users", .Dot, .Identifier "name", .EOF]

def testUnderscoreIdentifier : IO Unit :=
  lexTest "testUnderscoreIdentifier" "user_name _id _"
    [.Identifier "user_name", .Identifier "_id", .Identifier "_", .EOF]

def testFloatFormats : IO Unit :=
  lexTestWith "testFloatFormats" "3.14 0.5 1.0" fun
    | [.Literal (.Float _), .Literal (.Float _), .Literal (.Float _), .EOF] => true
    | _ => false

def testZero : IO Unit :=
  lexTest "testZero" "0" [.Literal (.Integer 0), .EOF]

def testMixedKeywordsIdentifiers : IO Unit :=
  lexTest "testMixedKeywordsIdentifiers" "select_column FROM select"
    [.Identifier "select_column", .Keyword .FROM, .Keyword .SELECT, .EOF]

def testComplexExpression : IO Unit :=
  lexTestWith "testComplexExpression" "price * (1 + tax_rate) >= 100.00" fun tokens => tokens.length == 10

def testAllComparisonOperators : IO Unit :=
  lexTestWith "testAllComparisonOperators" "a = b AND c != d AND e < f AND g > h AND i <= j AND k >= l" fun tokens =>
    tokens.any (· == .Operator .Equals) && tokens.any (· == .Operator .NotEquals) &&
    tokens.any (· == .Operator .LessThan) && tokens.any (· == .Operator .GreaterThan) &&
    tokens.any (· == .Operator .LessOrEqual) && tokens.any (· == .Operator .GreaterOrEqual)

def testInvalidCharacter : IO Unit := lexFailTest "testInvalidCharacter" "SELECT @"
def testInvalidExclamation : IO Unit := lexFailTest "testInvalidExclamation" "SELECT !"

-- Run all extended lexer tests
def runExtendedLexerTests : IO Unit := do
  IO.println "=== Running Extended Lexer Tests ==="
  testWhitespaceVariations
  testMultipleOperators
  testStringEscapes
  testEmptyString
  testUnterminatedString
  testSemicolon
  testMultipleStatements
  testParentheses
  testDotOperator
  testUnderscoreIdentifier
  testFloatFormats
  testZero
  testMixedKeywordsIdentifiers
  testComplexExpression
  testAllComparisonOperators
  testInvalidCharacter
  testInvalidExclamation
  IO.println ""

end SQLinLean.Tests
