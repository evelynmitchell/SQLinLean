# Property-Based Testing for SQL

## Overview

Use SlimCheck (Lean's PBT library, similar to Hypothesis/QuickCheck) to test SQL parser properties without needing a schema or comparison queries.

## SlimCheck Basics

SlimCheck requires:
1. **Generator** (`SampleableExt`): How to create random SQL ASTs
2. **Shrinker** (`Shrinkable`): How to simplify failing cases

```lean
import Mathlib.Testing.SlimCheck.Testable
open SlimCheck

-- Define generators for your AST
instance : SampleableExt SqlExpr :=
  SampleableExt.mkSelfContained do
    let choice ← Gen.chooseAny Bool
    if choice then
      let n ← Gen.elements ["col_A", "col_B", "id"]
      return SqlExpr.col n
    else
      let i ← Gen.chooseAny Int
      return SqlExpr.val i

-- Run property test
example (e : SqlExpr) : myParse (myPrint e) = some e := by
  slim_check
```

## Key Properties to Test

### 1. Round-Trip (Critical)

The most important property: parsing a printed AST should return the original.

```lean
-- Property: parse(print(ast)) == ast
theorem roundTrip (ast : Statement) :
  parse (print ast) = some ast := by
  slim_check
```

**What it catches:**
- Operator precedence bugs
- Missing parentheses
- Keyword formatting issues

### 2. Idempotence

Normalizing twice should equal normalizing once.

```lean
-- Property: normalize(normalize(sql)) == normalize(sql)
theorem normalizeIdempotent (sql : String) :
  normalize (normalize sql) = normalize sql := by
  slim_check
```

**What it catches:**
- Formatting instability
- Repeated transformations changing output

### 3. Structural Invariants

Properties that must hold for all valid SQL:

```lean
-- SELECT must have at least one column
theorem selectNonEmpty (s : SelectStmt) :
  s.columns.length > 0 := by
  slim_check

-- HAVING implies GROUP BY
theorem havingImpliesGroupBy (s : SelectStmt) :
  s.having.isSome → s.groupBy.isSome := by
  slim_check
```

### 4. Metamorphic Properties

Transformations with known effects:

```lean
-- Adding WHERE TRUE doesn't change semantics
theorem whereTrueIdentity (s : SelectStmt) :
  equivalent s (addWhereTrue s) := by
  slim_check

-- De Morgan's laws for predicates
theorem deMorgan (a b : Expr) :
  equivalent (Not (And a b)) (Or (Not a) (Not b)) := by
  slim_check
```

### 5. Crash Safety

Parser shouldn't crash on deeply nested input:

```lean
-- Deep nesting doesn't crash
theorem deepNestingSafe (depth : Nat) (h : depth < 1000) :
  (parse (generateNested depth)).isOk := by
  slim_check
```

## Property Summary

| Property | Difficulty | Value |
|----------|------------|-------|
| Round-Trip | Low | **Critical** |
| Idempotence | Low | High for formatters |
| Structural Invariants | Medium | High for validation |
| Metamorphic | High | High for optimizers |
| Crash Safety | Medium | High for robustness |

## Implementation Checklist

- [ ] Define `SampleableExt` for `Expr`
- [ ] Define `SampleableExt` for `Statement`
- [ ] Define `Shrinkable` instances
- [ ] Implement round-trip test
- [ ] Implement structural invariant tests
- [ ] Add to CI pipeline
