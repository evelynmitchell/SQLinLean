# Dependent Types for SQL

## Overview

Lean's dependent types allow types to depend on values. This enables compile-time validation of SQL against schemas.

## The Mechanism: Types as Functions

In standard languages, functions take data and return data:
```
Function: Int → Int
```

In Lean, functions can take **data** and return a **type**:
```
Function: Schema → Type
```

This means `ValidQuery MySchema` is a completely different type from `ValidQuery YourSchema`.

## Basic Example: Typed Columns

```lean
-- 1. Define a schema as a list of column names
def UserSchema : List String := ["id", "email", "age"]

-- 2. Define a Column that requires PROOF of existence
structure Column (s : List String) where
  name : String
  h : name ∈ s

-- 3. Create columns with compile-time validation
def emailCol : Column UserSchema :=
  ⟨"email", by simp⟩  -- ✅ SUCCEEDS: "email" is in the list

-- This won't compile:
-- def phoneCol : Column UserSchema :=
--   ⟨"phone", by simp⟩  -- ❌ FAILS: Tactic checking failed
```

## How It Works

When you write `Column.mk "email"`, Lean:

1. Looks at the proof obligation `(name ∈ s)`
2. Runs a tactic (`by simp`) to check if `"email" ∈ ["id", "email", "age"]`
3. If the tactic succeeds → code compiles
4. If the tactic fails → compile error with location

## Full Schema Example

```lean
namespace SQLDemo

abbrev Schema := List String

structure Column (s : Schema) where
  name : String
  h : name ∈ s
deriving Repr

def UserTable : Schema := ["id", "username", "email", "created_at"]

-- ✅ VALID: Compiles because "email" is in UserTable
def validCol : Column UserTable :=
  { name := "email", h := by simp }

-- ❌ INVALID: Build error - "phone" not in UserTable
-- def invalidCol : Column UserTable :=
--   { name := "phone", h := by simp }

-- Function that ONLY accepts UserTable columns
def generateSelect (c : Column UserTable) : String :=
  s!"SELECT {c.name} FROM users"

#eval generateSelect validCol
-- Output: "SELECT email FROM users"

end SQLDemo
```

## Automatic Proof Generation (Elaboration)

You don't need to write proofs manually for every column. Lean's elaboration phase can:

1. Parse raw syntax (untyped)
2. Look up schema (from file or definition)
3. Generate proofs automatically

```lean
-- Macro that auto-generates proofs
macro "col!" name:str : term => do
  -- During compilation, check if name is in schema
  -- Generate the proof term automatically
  ...
```

## Why This Beats LSP

| Aspect | LSP | Lean Dependent Types |
|--------|-----|---------------------|
| Type of "age" | `String` (just the name) | `Column UserSchema` (proof-carrying) |
| When it fails | Runtime (DB error) | Compile time (type error) |
| Mechanism | String comparison | Logical proof (`name ∈ schema`) |
| Refactoring | "Might miss it" | Build fails immediately |

## Advanced: Query Types

```lean
-- A query that's valid for a specific schema
structure ValidQuery (s : Schema) where
  columns : List (Column s)
  table : String
  whereClause : Option (Expr s)

-- Type-safe query construction
def myQuery : ValidQuery UserTable := {
  columns := [⟨"id", by simp⟩, ⟨"email", by simp⟩],
  table := "users",
  whereClause := none
}
```

## Implementation Checklist

- [ ] Define `Schema` type
- [ ] Define `Column (s : Schema)` with membership proof
- [ ] Define `Expr (s : Schema)` for typed expressions
- [ ] Define `ValidQuery (s : Schema)`
- [ ] Create elaboration macros for ergonomics
- [ ] Add error message customization
