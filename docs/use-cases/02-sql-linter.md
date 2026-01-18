# Use Case: SQL Linter / Static Analyzer

## Overview

Build analysis passes over SQL with strong type safety, catching bugs before production.

## Problem Statement

SQL queries can have subtle issues - performance problems, potential NULL bugs, injection vulnerabilities - that are hard to catch in code review.

## How Lean4 Helps

- Type-safe analysis passes
- Potentially prove properties about the analysis itself
- Exhaustive pattern matching ensures all cases handled

## Research & References

- sqlfluff: https://sqlfluff.com/
- pganalyze: https://pganalyze.com/
- SonarQube SQL rules

## Implementation Ideas

```lean
-- Detect SELECT * in production code
def detectSelectStar (q : Statement) : List Warning := ...

-- Find unindexed column access (given schema info)
def findUnindexedAccess (q : Statement) (schema : Schema) : List Warning := ...

-- Detect potential NULL comparison bugs (x = NULL instead of x IS NULL)
def detectNullComparison (q : Statement) : List Warning := ...

-- Detect tautologies in WHERE clauses (WHERE 1=1 AND ...)
def detectTautology (expr : Expr) : Bool := ...
```

## Lint Rules to Implement

### Style
- [ ] SELECT * detection
- [ ] Missing table aliases in JOINs
- [ ] Inconsistent identifier casing

### Performance
- [ ] Unindexed column access (requires schema)
- [ ] Cartesian products (missing JOIN conditions)
- [ ] LIKE with leading wildcard

### Correctness
- [ ] NULL comparison bugs (= NULL vs IS NULL)
- [ ] Tautologies/contradictions in WHERE
- [ ] Type mismatches (requires schema)

### Security
- [ ] Potential SQL injection patterns
- [ ] Overly permissive queries

## Integration Ideas

- CI/CD pipeline integration
- IDE/editor plugins
- Pre-commit hooks

## Open Questions

- Output format (JSON, SARIF, plain text)?
- Severity levels?
- Configuration for rule enable/disable?

## Notes & Ideas

<!-- Add your thoughts, discoveries, and explorations here -->

