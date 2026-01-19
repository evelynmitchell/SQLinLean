# Use Case: Schema Migration Safety

## Overview

Model schema migrations as functions between database states and prove they preserve data invariants or that existing queries remain valid.

## Problem Statement

"Breaking changes" in databases are often discovered at runtime. A migration might:
- Drop a column still referenced by active queries
- Change a type in a way that breaks existing code
- Violate data invariants (e.g., orphaned foreign keys)

## How Lean4 Helps

- Model migrations as functions `Schema A → Schema B`
- Prove queries valid for Schema A remain valid for Schema B
- Verify data invariants are preserved
- Catch breaking changes at compile time

## Research & References

- Database refactoring patterns
- Rails migrations, Flyway, Liquibase
- Formal verification of state machines

## Implementation Ideas

### Migration as Schema Transform
```lean
-- Define schemas
def SchemaV1 : Schema := ["id", "name", "age"]
def SchemaV2 : Schema := ["id", "name", "birthdate"]  -- age → birthdate

-- Migration function
def migrate_v1_to_v2 : SchemaV1 → SchemaV2 := ...

-- Prove a query is safe across migration
theorem query_safe_after_migration
  (q : Query SchemaV1)
  (h : onlyReferences q ["id", "name"]) :
  validQuery SchemaV2 (transformQuery q) := by ...
```

### Checking Query Compatibility
```lean
-- Given a set of active queries, prove migration is safe
def migrationSafe (queries : List RawQuery) (old new : Schema) : Bool :=
  queries.all fun q =>
    (referencedColumns q).all (· ∈ new)

-- Example: Prove DROP COLUMN is safe
example : migrationSafe activeQueries SchemaV1 SchemaV2 := by
  -- Only succeeds if no query references "age"
  ...
```

## Key Scenarios

### Safe Migrations
- [ ] ADD COLUMN (always safe for existing queries)
- [ ] RENAME COLUMN (with query rewriting)
- [ ] ADD INDEX (no query impact)

### Breaking Migrations
- [ ] DROP COLUMN - verify no references
- [ ] CHANGE TYPE - verify type compatibility
- [ ] DROP TABLE - verify no foreign keys or queries

### Invariant Preservation
- [ ] Foreign key integrity after migration
- [ ] NOT NULL constraints preserved
- [ ] Unique constraints maintained

## Integration Ideas

- CI/CD check before applying migrations
- Generate "impact report" for proposed migrations
- Automatic query rewriting suggestions

## Open Questions

- How to discover "active queries" in a codebase?
- Handling dynamic/generated SQL?
- Multiple migration steps (composition)?

## Notes & Ideas

<!-- Add your thoughts, discoveries, and explorations here -->

