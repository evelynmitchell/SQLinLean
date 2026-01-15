# Bug: NOT operator not parsed

## Description

The AST defines `Expr.Not` for the unary NOT operator, but the parser never actually parses it. SQL statements like `SELECT * FROM users WHERE NOT deleted` will fail to parse correctly.

## Current Behavior

The parser treats `NOT` as an unexpected token in expressions, causing parse errors or incorrect AST construction.

## Expected Behavior

`SELECT * FROM users WHERE NOT deleted` should parse to:
```
Statement.Select _ _ (some (Expr.Not (Expr.Identifier "deleted"))) _ _ _
```

## Location

- `SQLinLean/Parser.lean` - The `parsePrimary` function (lines 57-79) and expression parsing chain need to handle the NOT keyword
- `SQLinLean/AST.lean:14` - `Expr.Not` is defined but never constructed by parser

## Suggested Fix

Add NOT handling in the expression parsing chain, likely between `parseComparison` and `parseAnd` (or as part of `parsePrimary` for unary operators):

```lean
partial def parseNot (s : ParserState) : ParserResult Expr :=
  match s.peek with
  | some (.Keyword .NOT) =>
    let s' := s.advance
    match parseNot s' with  -- Allow chained NOT
    | .error msg state => .error msg state
    | .ok expr state => .ok (.Not expr) state
  | _ => parseComparison s
```

## Test Case

There's already a test expecting this behavior in `Tests/ParserTestsExtended.lean:66-75`:
```lean
def testWhereNot : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE NOT deleted" with
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select _ _ (some (Expr.Not _)) _ _ _ =>
          IO.println "PASS: testWhereNot"
```

## Labels

`bug`, `parser`
