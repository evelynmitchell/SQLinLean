# Use Case: SQL-to-X Transpiler

## Overview

Migrate queries between database dialects or compile SQL to other languages, with optional correctness proofs.

## Problem Statement

- Database migrations require converting queries between dialects
- Integrating SQL with other systems (DataFrames, ORMs) requires translation
- Manual translation is error-prone

## How Lean4 Helps

- Type-safe AST transformations
- Optional proofs that transpilation preserves semantics
- Exhaustive pattern matching prevents missing cases

## Research & References

- sqlglot: https://github.com/tobymao/sqlglot
- Apache Calcite: https://calcite.apache.org/
- Presto/Trino SQL dialects

## Implementation Ideas

```lean
-- Convert SQL to a DataFrame DSL
def sqlToDataFrame (q : Statement) : DataFrameExpr := ...

-- Convert between SQL dialects
def postgresqlToMysql (q : Statement) : Statement := ...

-- Prove the transpilation preserves semantics
theorem transpile_correct (q : Statement) :
  evalPostgres q = evalMysql (postgresqlToMysql q) := by ...
```

## Target Dialects/Languages

### SQL Dialects
- [ ] PostgreSQL
- [ ] MySQL
- [ ] SQLite
- [ ] SQL Server
- [ ] Oracle

### Other Targets
- [ ] Pandas DataFrame operations
- [ ] Polars
- [ ] Spark SQL
- [ ] LINQ expressions
- [ ] Lean4 code (for embedding)

## Dialect Differences to Handle

- String concatenation (|| vs CONCAT vs +)
- LIMIT/OFFSET vs TOP vs FETCH
- Date/time functions
- Type casting syntax
- Boolean literals
- NULL handling nuances
- Window function syntax

## Open Questions

- How to handle features that don't exist in target?
- Semantic differences (e.g., collation, NULL sorting)
- Round-trip preservation?

## Notes & Ideas

<!-- Add your thoughts, discoveries, and explorations here -->

