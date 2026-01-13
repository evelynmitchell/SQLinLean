-- Extended Lexer Tests inspired by sqlglot test suite
import SQLinLean.Lexer
import SQLinLean.Token

namespace SQLinLean.Tests

open SQLinLean

-- Test whitespace variations (spaces, tabs, newlines)
def testWhitespaceVariations : IO Unit := do
  match tokenizeString "SELECT  \t  *  \n  FROM\r\n  users" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testWhitespaceVariations - {msg}"
  | LexerResult.ok tokens _ =>
      let expected := [
        Token.Keyword Keyword.SELECT,
        Token.Star,
        Token.Keyword Keyword.FROM,
        Token.Identifier "users",
        Token.EOF
      ]
      if tokens == expected then
        IO.println "PASS: testWhitespaceVariations"
      else
        IO.println s!"FAIL: testWhitespaceVariations - Expected {repr expected}, got {repr tokens}"

-- Test multiple operators together
def testMultipleOperators : IO Unit := do
  match tokenizeString "<> <= >= !=" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testMultipleOperators - {msg}"
  | LexerResult.ok tokens _ =>
      let expected := [
        Token.Operator Operator.NotEquals,
        Token.Operator Operator.LessOrEqual,
        Token.Operator Operator.GreaterOrEqual,
        Token.Operator Operator.NotEquals,
        Token.EOF
      ]
      if tokens == expected then
        IO.println "PASS: testMultipleOperators"
      else
        IO.println s!"FAIL: testMultipleOperators - Expected {repr expected}, got {repr tokens}"

-- Test string with escape sequences
def testStringEscapes : IO Unit := do
  match tokenizeString "'hello\\nworld'" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testStringEscapes - {msg}"
  | LexerResult.ok tokens _ =>
      match tokens with
      | [Token.Literal (Literal.String s), Token.EOF] =>
          if s.contains '\n' then
            IO.println "PASS: testStringEscapes"
          else
            IO.println s!"FAIL: testStringEscapes - Escape sequence not processed: {repr s}"
      | _ => 
          IO.println s!"FAIL: testStringEscapes - Unexpected tokens: {repr tokens}"

-- Test empty string
def testEmptyString : IO Unit := do
  match tokenizeString "''" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testEmptyString - {msg}"
  | LexerResult.ok tokens _ =>
      match tokens with
      | [Token.Literal (Literal.String ""), Token.EOF] =>
          IO.println "PASS: testEmptyString"
      | _ => 
          IO.println s!"FAIL: testEmptyString - Expected empty string, got {repr tokens}"

-- Test unterminated string (error case)
def testUnterminatedString : IO Unit := do
  match tokenizeString "'unterminated" with
  | LexerResult.error _ _ => 
      IO.println "PASS: testUnterminatedString"
  | LexerResult.ok tokens _ =>
      IO.println s!"FAIL: testUnterminatedString - Should have failed but got: {repr tokens}"

-- Test semicolon token
def testSemicolon : IO Unit := do
  match tokenizeString "SELECT 1;" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testSemicolon - {msg}"
  | LexerResult.ok tokens _ =>
      match tokens with
      | [Token.Keyword Keyword.SELECT, Token.Literal (Literal.Integer 1), Token.Semicolon, Token.EOF] =>
          IO.println "PASS: testSemicolon"
      | _ => 
          IO.println s!"FAIL: testSemicolon - Got {repr tokens}"

-- Test multiple statements
def testMultipleStatements : IO Unit := do
  match tokenizeString "SELECT 1; SELECT 2;" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testMultipleStatements - {msg}"
  | LexerResult.ok tokens _ =>
      let expectedCount := 9  -- SELECT, 1, ;, SELECT, 2, ;, EOF
      if tokens.length == expectedCount then
        IO.println "PASS: testMultipleStatements"
      else
        IO.println s!"FAIL: testMultipleStatements - Expected {expectedCount} tokens, got {tokens.length}"

-- Test parentheses
def testParentheses : IO Unit := do
  match tokenizeString "SELECT (1, 2)" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testParentheses - {msg}"
  | LexerResult.ok tokens _ =>
      let expected := [
        Token.Keyword Keyword.SELECT,
        Token.LeftParen,
        Token.Literal (Literal.Integer 1),
        Token.Comma,
        Token.Literal (Literal.Integer 2),
        Token.RightParen,
        Token.EOF
      ]
      if tokens == expected then
        IO.println "PASS: testParentheses"
      else
        IO.println s!"FAIL: testParentheses - Expected {repr expected}, got {repr tokens}"

-- Test qualified identifiers (table.column)
def testDotOperator : IO Unit := do
  match tokenizeString "users.name" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testDotOperator - {msg}"
  | LexerResult.ok tokens _ =>
      let expected := [
        Token.Identifier "users",
        Token.Dot,
        Token.Identifier "name",
        Token.EOF
      ]
      if tokens == expected then
        IO.println "PASS: testDotOperator"
      else
        IO.println s!"FAIL: testDotOperator - Expected {repr expected}, got {repr tokens}"

-- Test underscore in identifiers
def testUnderscoreIdentifier : IO Unit := do
  match tokenizeString "user_name _id _" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testUnderscoreIdentifier - {msg}"
  | LexerResult.ok tokens _ =>
      let expected := [
        Token.Identifier "user_name",
        Token.Identifier "_id",
        Token.Identifier "_",
        Token.EOF
      ]
      if tokens == expected then
        IO.println "PASS: testUnderscoreIdentifier"
      else
        IO.println s!"FAIL: testUnderscoreIdentifier - Expected {repr expected}, got {repr tokens}"

-- Test float literals with decimal point
def testFloatFormats : IO Unit := do
  match tokenizeString "3.14 0.5 1.0" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testFloatFormats - {msg}"
  | LexerResult.ok tokens _ =>
      match tokens with
      | [Token.Literal (Literal.Float _), Token.Literal (Literal.Float _), 
         Token.Literal (Literal.Float _), Token.EOF] =>
          IO.println "PASS: testFloatFormats"
      | _ => 
          IO.println s!"FAIL: testFloatFormats - Got {repr tokens}"

-- Test zero
def testZero : IO Unit := do
  match tokenizeString "0" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testZero - {msg}"
  | LexerResult.ok tokens _ =>
      match tokens with
      | [Token.Literal (Literal.Integer 0), Token.EOF] =>
          IO.println "PASS: testZero"
      | _ => 
          IO.println s!"FAIL: testZero - Got {repr tokens}"

-- Test mixed keywords and identifiers
def testMixedKeywordsIdentifiers : IO Unit := do
  match tokenizeString "select_column FROM select" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testMixedKeywordsIdentifiers - {msg}"
  | LexerResult.ok tokens _ =>
      let expected := [
        Token.Identifier "select_column",
        Token.Keyword Keyword.FROM,
        Token.Keyword Keyword.SELECT,
        Token.EOF
      ]
      if tokens == expected then
        IO.println "PASS: testMixedKeywordsIdentifiers"
      else
        IO.println s!"FAIL: testMixedKeywordsIdentifiers - Expected {repr expected}, got {repr tokens}"

-- Test complex SQL expression tokenization
def testComplexExpression : IO Unit := do
  match tokenizeString "price * (1 + tax_rate) >= 100.00" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testComplexExpression - {msg}"
  | LexerResult.ok tokens _ =>
      if tokens.length == 12 then  -- All tokens including operators and parentheses
        IO.println "PASS: testComplexExpression"
      else
        IO.println s!"FAIL: testComplexExpression - Expected 12 tokens, got {tokens.length}: {repr tokens}"

-- Test all comparison operators
def testAllComparisonOperators : IO Unit := do
  match tokenizeString "a = b AND c != d AND e < f AND g > h AND i <= j AND k >= l" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testAllComparisonOperators - {msg}"
  | LexerResult.ok tokens _ =>
      let hasEquals := tokens.any (fun t => t == Token.Operator Operator.Equals)
      let hasNotEquals := tokens.any (fun t => t == Token.Operator Operator.NotEquals)
      let hasLess := tokens.any (fun t => t == Token.Operator Operator.LessThan)
      let hasGreater := tokens.any (fun t => t == Token.Operator Operator.GreaterThan)
      let hasLessOrEq := tokens.any (fun t => t == Token.Operator Operator.LessOrEqual)
      let hasGreaterOrEq := tokens.any (fun t => t == Token.Operator Operator.GreaterOrEqual)
      if hasEquals && hasNotEquals && hasLess && hasGreater && hasLessOrEq && hasGreaterOrEq then
        IO.println "PASS: testAllComparisonOperators"
      else
        IO.println s!"FAIL: testAllComparisonOperators - Some operators missing"

-- Test invalid character (error case)
def testInvalidCharacter : IO Unit := do
  match tokenizeString "SELECT @" with
  | LexerResult.error _ _ => 
      IO.println "PASS: testInvalidCharacter"
  | LexerResult.ok tokens _ =>
      IO.println s!"FAIL: testInvalidCharacter - Should have failed but got: {repr tokens}"

-- Test exclamation without equals (error case)
def testInvalidExclamation : IO Unit := do
  match tokenizeString "SELECT !" with
  | LexerResult.error _ _ => 
      IO.println "PASS: testInvalidExclamation"
  | LexerResult.ok tokens _ =>
      IO.println s!"FAIL: testInvalidExclamation - Should have failed but got: {repr tokens}"

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
