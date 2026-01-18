# NULL Semantics in SQL

## Overview

SQL uses 3-valued logic (`TRUE`, `FALSE`, `NULL/UNKNOWN`), which is a frequent source of bugs. Lean can model this precisely.

## The Problem

SQL's NULL handling is counterintuitive:

```sql
-- This returns NO rows, even if some ages are NULL
SELECT * FROM users WHERE age = NULL

-- Because NULL = NULL evaluates to NULL (unknown), not TRUE
```

Common bugs:
- `x = NULL` instead of `x IS NULL`
- `NOT (x > 5)` doesn't include NULLs
- Aggregations silently ignore NULLs

## 3-Valued Logic

| A | B | A AND B | A OR B | NOT A |
|---|---|---------|--------|-------|
| T | T | T | T | F |
| T | F | F | T | F |
| T | N | N | T | F |
| F | F | F | F | T |
| F | N | F | N | T |
| N | N | N | N | N |

## Modeling in Lean

```lean
-- 3-valued logic type
inductive Trilean where
  | true
  | false
  | null
deriving Repr, DecidableEq

namespace Trilean

def and : Trilean → Trilean → Trilean
  | true, true => true
  | false, _ => false
  | _, false => false
  | _, _ => null

def or : Trilean → Trilean → Trilean
  | true, _ => true
  | _, true => true
  | false, false => false
  | _, _ => null

def not : Trilean → Trilean
  | true => false
  | false => true
  | null => null

-- Equality in SQL (NULL = anything is NULL)
def sqlEq (a b : Option Value) : Trilean :=
  match a, b with
  | some x, some y => if x == y then true else false
  | _, _ => null

end Trilean
```

## Query Equivalence with NULLs

These queries are NOT equivalent due to NULL:

```sql
-- Query A: Rows where age is known and > 18
SELECT * FROM users WHERE age > 18

-- Query B: Rows where NOT (age <= 18)
-- Does NOT include rows where age IS NULL!
SELECT * FROM users WHERE NOT (age <= 18)
```

In Lean:
```lean
theorem notEquivalent :
  ¬(∀ row, eval (age > 18) row = eval (NOT (age <= 18)) row) := by
  -- Counterexample: row with age = NULL
  use { age := none }
  simp [eval, Trilean.not]
  -- age > 18 evaluates to NULL
  -- NOT (age <= 18) evaluates to NOT NULL = NULL
  -- But we need TRUE to return the row!
```

## Safe NULL Handling

### Detecting NULL Comparison Bugs

```lean
def detectNullComparison (expr : Expr) : List Warning :=
  match expr with
  | .eq left (.literal .null) =>
      [Warning.mk "Use IS NULL instead of = NULL"]
  | .eq (.literal .null) right =>
      [Warning.mk "Use IS NULL instead of = NULL"]
  | .binOp op left right =>
      detectNullComparison left ++ detectNullComparison right
  | _ => []
```

### Forcing NULL Handling

```lean
-- A "safe" comparison that forces explicit NULL handling
structure SafeComparison where
  expr : Expr
  nullHandled : NullHandlingProof expr

-- User must prove they've handled NULL cases
def safeWhere (col : Column s) (val : Value)
    (h : col.nullable = false ∨ hasCoalesce expr) : SafeComparison := ...
```

## Aggregation and NULLs

```lean
-- COUNT(*) vs COUNT(column)
-- COUNT(*) counts all rows
-- COUNT(column) ignores NULLs

def countStar (rows : List Row) : Nat := rows.length

def countColumn (col : String) (rows : List Row) : Nat :=
  rows.filter (fun r => r.get col |>.isSome) |>.length

-- These can differ!
example : countStar [r1, r2] ≠ countColumn "age" [r1, r2] := by
  -- When r1.age = NULL, r2.age = 25
  ...
```

## Implementation Checklist

- [ ] Define `Trilean` type
- [ ] Implement 3-valued AND, OR, NOT
- [ ] Define `sqlEq` with NULL handling
- [ ] Implement expression evaluation with Trilean
- [ ] Add NULL comparison lint rule
- [ ] Prove NULL-related query non-equivalences
- [ ] Document common NULL pitfalls
