# Two-Phase Architecture

## Overview

SQLinLean uses a two-phase approach to SQL processing:

1. **Phase 1: Parsing** - Convert SQL text to Raw AST (schema-agnostic)
2. **Phase 2: Validation** - Convert Raw AST to Typed AST (schema-dependent)

## Why Two Phases?

Most general-purpose SQL parsers (PostgreSQL, sqlglot) don't know the schema during parsing. This is intentional:

- **Flexibility**: Works with any database
- **No dependencies**: Doesn't require database connection
- **Partial validation**: Useful even without schema

## Phase 1: Raw AST

The Raw AST treats identifiers as plain strings. It validates syntax, not semantics.

```lean
-- Schema-agnostic AST
inductive RawValue
  | int (i : Int)
  | str (s : String)
  | null

inductive RawExpr
  | col (name : String)      -- Just a string, no validation
  | val (v : RawValue)
  | eq (left right : RawExpr)

structure RawSelect where
  table   : String           -- Just a string
  columns : List String      -- Just strings
  where_  : Option RawExpr
```

### What You Can Do With Raw AST

Even without schema:
- **Linting**: "You forgot WHERE on DELETE"
- **Formatting**: Auto-indentation, pretty-printing
- **Transpilation**: PostgreSQL → SQLite
- **Sanitization**: Injection prevention

## Phase 2: Typed AST

Given a schema, upgrade the Raw AST to a Typed AST with proofs.

```lean
-- A schema is a list of column names
def Schema := List String

-- Typed expression requires proof of column existence
inductive TypedExpr (s : Schema)
  | col (name : String) (h : name ∈ s) : TypedExpr s
  | val (v : RawValue) : TypedExpr s
  | eq (left right : TypedExpr s) : TypedExpr s
```

### The Validation Function

```lean
def validate (s : Schema) (raw : RawExpr) : Except String (TypedExpr s) :=
  match raw with
  | .col name =>
      if h : name ∈ s then
        -- Found! Construct typed node with proof
        return TypedExpr.col name h
      else
        throw s!"Error: Column '{name}' not found in schema."
  | .val v =>
      return TypedExpr.val v
  | .eq left right => do
      let left' ← validate s left
      let right' ← validate s right
      return TypedExpr.eq left' right'
```

## Benefits

| Phase | Schema Required | Use Cases |
|-------|-----------------|-----------|
| Phase 1 | No | Linting, formatting, transpilation |
| Phase 2 | Yes | Type checking, compile-time validation |

## Implementation Status

- [x] Phase 1: Raw AST (`SQLinLean/AST.lean`)
- [x] Phase 1: Parser (`SQLinLean/Parser.lean`)
- [ ] Phase 2: Schema representation
- [ ] Phase 2: Validation function
- [ ] Phase 2: Typed AST
