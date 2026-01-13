-- SQL Lexer/Tokenizer
import SQLinLean.Token

namespace SQLinLean

-- Lexer state
structure LexerState where
  input : String
  position : Nat := 0
  deriving Repr, Nonempty

-- Lexer result type
inductive LexerResult (α : Type) where
  | ok (value : α) (state : LexerState)
  | error (msg : String) (state : LexerState)
  deriving Repr, Nonempty

-- Helper functions
def LexerState.peek (s : LexerState) : Option Char :=
  s.input.get? ⟨s.position⟩

def LexerState.advance (s : LexerState) (n : Nat := 1) : LexerState :=
  { s with position := s.position + n }

def LexerState.isEOF (s : LexerState) : Bool :=
  s.position >= s.input.length

def isWhitespace (c : Char) : Bool :=
  c = ' ' || c = '\t' || c = '\n' || c = '\r'

def isDigit (c : Char) : Bool :=
  c.val >= '0'.val && c.val <= '9'.val

def isAlpha (c : Char) : Bool :=
  (c.val >= 'a'.val && c.val <= 'z'.val) ||
  (c.val >= 'A'.val && c.val <= 'Z'.val)

def isAlphaNumeric (c : Char) : Bool :=
  isAlpha c || isDigit c || c = '_'

-- Skip whitespace
partial def skipWhitespace (s : LexerState) : LexerState :=
  match s.peek with
  | none => s
  | some c =>
    if isWhitespace c then
      skipWhitespace (s.advance)
    else
      s

-- Read while a predicate holds
partial def readWhile (s : LexerState) (pred : Char → Bool) : String × LexerState :=
  match s.peek with
  | none => ("", s)
  | some c =>
    if pred c then
      let (rest, finalState) := readWhile (s.advance) pred
      (String.ofList [c] ++ rest, finalState)
    else
      ("", s)

-- Simple float parser (since toFloat? doesn't exist in Lean 4)
def parseFloat (s : String) : Option Float :=
  match s.toInt? with
  | some i => some (Float.ofInt i)
  | none => none  -- Simplified: just handle integers as floats

-- Tokenize a number
def tokenizeNumber (s : LexerState) : LexerResult Token :=
  let (numStr, newState) := readWhile s (fun c => isDigit c || c = '.')
  if numStr.contains '.' then
    match parseFloat numStr with
    | some f => .ok (.Literal (.Float f)) newState
    | none => .error "Invalid float literal" newState
  else
    match numStr.toInt? with
    | some i => .ok (.Literal (.Integer i)) newState
    | none => .error "Invalid integer literal" newState

-- Tokenize a string literal (single-quoted) - helper function
partial def readStringContent (acc : String) (state : LexerState) : LexerResult Token :=
  match state.peek with
  | none => .error "Unterminated string literal" state
  | some c =>
    if c = '\'' then
      .ok (.Literal (.String acc)) (state.advance)
    else if c = '\\' then
      -- Simple escape handling
      let state := state.advance
      match state.peek with
      | none => .error "Unterminated string literal" state
      | some escapeChar =>
        readStringContent (acc ++ String.ofList [escapeChar]) (state.advance)
    else
      readStringContent (acc ++ String.ofList [c]) (state.advance)

-- Tokenize a string literal (single-quoted)
def tokenizeStringLit (s : LexerState) : LexerResult Token :=
  -- Skip opening quote
  readStringContent "" (s.advance)

-- Tokenize an identifier or keyword
def tokenizeIdentifier (s : LexerState) : LexerResult Token :=
  let (ident, newState) := readWhile s isAlphaNumeric
  match Keyword.fromString? ident with
  | some kw => .ok (.Keyword kw) newState
  | none => .ok (.Identifier ident) newState

-- Tokenize a single token
def tokenizeOne (s : LexerState) : LexerResult Token :=
  let s := skipWhitespace s
  match s.peek with
  | none => .ok .EOF s
  | some c =>
    if isDigit c then
      tokenizeNumber s
    else if isAlpha c || c = '_' then
      tokenizeIdentifier s
    else if c = '\'' then
      tokenizeStringLit s
    else if c = '(' then
      .ok .LeftParen (s.advance)
    else if c = ')' then
      .ok .RightParen (s.advance)
    else if c = ',' then
      .ok .Comma (s.advance)
    else if c = ';' then
      .ok .Semicolon (s.advance)
    else if c = '*' then
      .ok .Star (s.advance)
    else if c = '.' then
      .ok .Dot (s.advance)
    else if c = '=' then
      .ok (.Operator .Equals) (s.advance)
    else if c = '<' then
      let s' := s.advance
      match s'.peek with
      | some '=' => .ok (.Operator .LessOrEqual) (s'.advance)
      | some '>' => .ok (.Operator .NotEquals) (s'.advance)
      | _ => .ok (.Operator .LessThan) s'
    else if c = '>' then
      let s' := s.advance
      match s'.peek with
      | some '=' => .ok (.Operator .GreaterOrEqual) (s'.advance)
      | _ => .ok (.Operator .GreaterThan) s'
    else if c = '!' then
      let s' := s.advance
      match s'.peek with
      | some '=' => .ok (.Operator .NotEquals) (s'.advance)
      | _ => .error s!"Unexpected character: {c}" s
    else if c = '+' then
      .ok (.Operator .Plus) (s.advance)
    else if c = '-' then
      .ok (.Operator .Minus) (s.advance)
    else if c = '/' then
      .ok (.Operator .Divide) (s.advance)
    else
      .error s!"Unexpected character: {c}" s

-- Tokenize entire input
partial def tokenize (s : LexerState) : LexerResult (List Token) :=
  match tokenizeOne s with
  | .error msg state => .error msg state
  | .ok token newState =>
    match token with
    | .EOF => .ok [.EOF] newState
    | _ =>
      match tokenize newState with
      | .error msg state => .error msg state
      | .ok tokens state => .ok (token :: tokens) state

-- Convenience function to tokenize a string
def tokenizeString (input : String) : LexerResult (List Token) :=
  tokenize { input := input }

end SQLinLean
