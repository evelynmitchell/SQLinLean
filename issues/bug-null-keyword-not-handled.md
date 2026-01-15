# Bug: NULL keyword not handled in expression parsing

## Description

The `NULL` keyword is defined as `Keyword.NULL` in the token types, and `Literal.Null` exists in the AST, but the parser's `parsePrimary` function doesn't handle the NULL keyword. This means expressions like `WHERE email = NULL` may not work correctly.

## Current Behavior

The lexer produces `Token.Keyword Keyword.NULL` for the `NULL` keyword, but `parsePrimary` only handles `Token.Literal`:

```lean
-- Parser.lean:59
| some (.Literal lit) => ParserResult.ok (.Literal lit) (s.advance)
```

When encountering `Token.Keyword Keyword.NULL`, it falls through to the error case:
```lean
| some t => ParserResult.error s!"Unexpected token in expression: {repr t}" s
```

## Expected Behavior

`SELECT * FROM users WHERE email = NULL` should parse successfully with the WHERE clause being:
```
Expr.BinaryOp (Expr.Identifier "email") Operator.Equals (Expr.Literal Literal.Null)
```

## Location

- `SQLinLean/Parser.lean:57-79` - `parsePrimary` function

## Suggested Fix

Add a case for `Keyword.NULL` in `parsePrimary`:

```lean
partial def parsePrimary (s : ParserState) : ParserResult Expr :=
  match s.peek with
  | some (.Literal lit) => ParserResult.ok (.Literal lit) (s.advance)
  | some (.Keyword .NULL) => ParserResult.ok (.Literal .Null) (s.advance)  -- Add this
  | some .Star => ParserResult.ok .Star (s.advance)
  -- ... rest of cases
```

## Test Case

There's a test in `Tests/ParserTestsExtended.lean:90-99` that relies on this:
```lean
def testWhereNull : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE email = NULL" with
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some (Expr.BinaryOp _ _ (Expr.Literal Literal.Null))) _ _ _ =>
          IO.println "PASS: testWhereNull"
```

## Notes

Consider also adding `TRUE` and `FALSE` keywords to support `Literal.Boolean`, which is defined in the AST but currently has no way to be produced.

## Labels

`bug`, `parser`
