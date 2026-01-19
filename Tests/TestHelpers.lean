-- Shared test helper functions
import SQLinLean.Lexer
import SQLinLean.Parser
import SQLinLean.Token
import SQLinLean.AST

namespace SQLinLean.Tests

open SQLinLean

-- Lexer test helpers

/-- Tokenize and compare expected tokens -/
def lexTest (name : String) (input : String) (expected : List Token) : IO Unit := do
  match tokenizeString input with
  | LexerResult.error msg _ => IO.println s!"FAIL: {name} - {msg}"
  | LexerResult.ok tokens _ =>
      if tokens == expected then IO.println s!"PASS: {name}"
      else IO.println s!"FAIL: {name} - Expected {repr expected}, got {repr tokens}"

/-- Tokenize and validate with custom predicate -/
def lexTestWith (name : String) (input : String) (validate : List Token → Bool) : IO Unit := do
  match tokenizeString input with
  | LexerResult.error msg _ => IO.println s!"FAIL: {name} - {msg}"
  | LexerResult.ok tokens _ =>
      if validate tokens then IO.println s!"PASS: {name}"
      else IO.println s!"FAIL: {name} - Got {repr tokens}"

/-- Expect tokenization to fail -/
def lexFailTest (name : String) (input : String) : IO Unit := do
  match tokenizeString input with
  | LexerResult.error _ _ => IO.println s!"PASS: {name}"
  | LexerResult.ok tokens _ => IO.println s!"FAIL: {name} - Should have failed but got: {repr tokens}"

-- Parser test helpers

/-- Parse and validate with custom predicate -/
def parseTest (name : String) (input : String) (validate : Statement → Bool) : IO Unit := do
  match parseSQL input with
  | Sum.inl err => IO.println s!"FAIL: {name} - {err}"
  | Sum.inr stmt =>
      if validate stmt then IO.println s!"PASS: {name}"
      else IO.println s!"FAIL: {name} - Got {repr stmt}"

/-- Expect parse to fail -/
def parseFailTest (name : String) (input : String) : IO Unit := do
  match parseSQL input with
  | Sum.inl _ => IO.println s!"PASS: {name}"
  | Sum.inr stmt => IO.println s!"FAIL: {name} - Should have failed but got: {repr stmt}"

end SQLinLean.Tests
