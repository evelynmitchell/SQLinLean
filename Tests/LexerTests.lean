-- Tests for SQL Lexer
import SQLinLean.Lexer
import SQLinLean.Token

namespace SQLinLean.Tests

open SQLinLean

-- Test tokenizing simple SELECT
def testSelectTokens : IO Unit := do
  match tokenizeString "SELECT * FROM users" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testSelectTokens - {msg}"
  | LexerResult.ok tokens _ =>
      let expected := [
        Token.Keyword Keyword.SELECT,
        Token.Star,
        Token.Keyword Keyword.FROM,
        Token.Identifier "users",
        Token.EOF
      ]
      if tokens == expected then
        IO.println "PASS: testSelectTokens"
      else
        IO.println s!"FAIL: testSelectTokens - Expected {repr expected}, got {repr tokens}"

-- Test tokenizing numbers
def testNumbers : IO Unit := do
  match tokenizeString "42 100" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testNumbers - {msg}"
  | LexerResult.ok tokens _ =>
      match tokens with
      | [Token.Literal (Literal.Integer 42), Token.Literal (Literal.Integer 100), Token.EOF] =>
          IO.println "PASS: testNumbers"
      | _ => 
          IO.println s!"FAIL: testNumbers - Got {repr tokens}"

-- Test tokenizing float literals
def testFloats : IO Unit := do
  match tokenizeString "3.14 2.5" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testFloats - {msg}"
  | LexerResult.ok tokens _ =>
      match tokens with
      | [Token.Literal (Literal.Float _), Token.Literal (Literal.Float _), Token.EOF] =>
          IO.println "PASS: testFloats"
      | _ => 
          IO.println s!"FAIL: testFloats - Got {repr tokens}"

-- Test tokenizing strings
def testStrings : IO Unit := do
  match tokenizeString "'hello' 'world'" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testStrings - {msg}"
  | LexerResult.ok tokens _ =>
      let expected := [
        Token.Literal (Literal.String "hello"),
        Token.Literal (Literal.String "world"),
        Token.EOF
      ]
      if tokens == expected then
        IO.println "PASS: testStrings"
      else
        IO.println s!"FAIL: testStrings - Expected {repr expected}, got {repr tokens}"

-- Test tokenizing operators
def testOperators : IO Unit := do
  match tokenizeString "= != < > <= >= + - * /" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testOperators - {msg}"
  | LexerResult.ok tokens _ =>
      let expected := [
        Token.Operator Operator.Equals,
        Token.Operator Operator.NotEquals,
        Token.Operator Operator.LessThan,
        Token.Operator Operator.GreaterThan,
        Token.Operator Operator.LessOrEqual,
        Token.Operator Operator.GreaterOrEqual,
        Token.Operator Operator.Plus,
        Token.Operator Operator.Minus,
        Token.Star,
        Token.Operator Operator.Divide,
        Token.EOF
      ]
      if tokens == expected then
        IO.println "PASS: testOperators"
      else
        IO.println s!"FAIL: testOperators - Expected {repr expected}, got {repr tokens}"

-- Test tokenizing keywords
def testKeywords : IO Unit := do
  match tokenizeString "SELECT INSERT UPDATE DELETE WHERE FROM" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testKeywords - {msg}"
  | LexerResult.ok tokens _ =>
      let expected := [
        Token.Keyword Keyword.SELECT,
        Token.Keyword Keyword.INSERT,
        Token.Keyword Keyword.UPDATE,
        Token.Keyword Keyword.DELETE,
        Token.Keyword Keyword.WHERE,
        Token.Keyword Keyword.FROM,
        Token.EOF
      ]
      if tokens == expected then
        IO.println "PASS: testKeywords"
      else
        IO.println s!"FAIL: testKeywords - Expected {repr expected}, got {repr tokens}"

-- Test case insensitivity
def testCaseInsensitivity : IO Unit := do
  match tokenizeString "select SELECT SeLeCt" with
  | LexerResult.error msg _ => 
      IO.println s!"FAIL: testCaseInsensitivity - {msg}"
  | LexerResult.ok tokens _ =>
      let expected := [
        Token.Keyword Keyword.SELECT,
        Token.Keyword Keyword.SELECT,
        Token.Keyword Keyword.SELECT,
        Token.EOF
      ]
      if tokens == expected then
        IO.println "PASS: testCaseInsensitivity"
      else
        IO.println s!"FAIL: testCaseInsensitivity - Expected {repr expected}, got {repr tokens}"

-- Run all lexer tests
def runLexerTests : IO Unit := do
  IO.println "=== Running Lexer Tests ==="
  testSelectTokens
  testNumbers
  testFloats
  testStrings
  testOperators
  testKeywords
  testCaseInsensitivity
  IO.println ""

end SQLinLean.Tests
