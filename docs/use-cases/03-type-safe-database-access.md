# Use Case: Type-Safe Database Access Layer

## Overview

Validate SQL queries at compile time against a schema, catching errors before runtime.

## Problem Statement

SQL queries in application code are typically strings - no compile-time checking that they're valid or match your schema.

## How Lean4 Helps

- Dependent types can encode schema information
- Compile-time validation of queries against schemas
- Refactor schemas with confidence

## Research & References

- sqlx (Rust): https://github.com/launchbadge/sqlx
- jOOQ (Java): https://www.jooq.org/
- Prisma: https://www.prisma.io/
- Type Providers (F#)

## Implementation Ideas

### Basic Schema-Aware Query
```lean
-- Define your schema in Lean
def mySchema : Schema := {
  tables := [
    { name := "users",
      columns := [("id", .Integer), ("name", .String), ("age", .Integer)] },
    { name := "orders",
      columns := [("id", .Integer), ("user_id", .Integer), ("total", .Float)] }
  ]
}

-- This compiles - query is valid for schema
def validQuery : ValidQuery mySchema :=
  query! "SELECT name, age FROM users WHERE age > 18"

-- This would FAIL to compile - 'email' column doesn't exist
def invalidQuery : ValidQuery mySchema :=
  query! "SELECT email FROM users"  -- Compile error!
```

### Dependent Types for Column Validation
```lean
-- A schema is a list of column names
def Schema := List String

-- A Column requires a PROOF that the name exists in the schema
structure Column (s : Schema) where
  name : String
  h    : name ∈ s

def UserTable : Schema := ["id", "username", "email", "created_at"]

-- ✅ VALID: Compiles because "email" is in UserTable
def validCol : Column UserTable :=
  { name := "email", h := by simp }

-- ❌ INVALID: Won't compile - "phone" not in UserTable
-- def invalidCol : Column UserTable :=
--   { name := "phone", h := by simp }  -- Tactic failure!
```

### Two-Phase Strategy
1. **Layer 1 (Parser):** Parse to Raw AST (schema-agnostic, always succeeds for valid syntax)
2. **Layer 2 (Validator):** Upgrade Raw AST to Typed AST given a schema

```lean
def validate (s : Schema) (raw : RawExpr) : Except String (TypedExpr s) :=
  match raw with
  | .col name =>
      if h : name ∈ s then
        return TypedExpr.col name h
      else
        throw s!"Error: Column '{name}' not found in schema."
  | ...
```

## Features to Implement

### Schema Representation
- [ ] Table definitions
- [ ] Column types (Integer, String, Float, Boolean, Date, etc.)
- [ ] Primary keys
- [ ] Foreign keys
- [ ] NOT NULL constraints
- [ ] Default values

### Compile-Time Checks
- [ ] Column existence
- [ ] Table existence
- [ ] Type compatibility in expressions
- [ ] JOIN validity (foreign keys)
- [ ] Result type inference

### Developer Experience
- [ ] Good error messages
- [ ] Schema from CREATE TABLE statements
- [ ] Schema from database introspection

## Open Questions

- How to handle schema migrations?
- Dynamic queries (user-provided filters)?
- Performance of compile-time checking?

## Notes & Ideas

<!-- Add your thoughts, discoveries, and explorations here -->

