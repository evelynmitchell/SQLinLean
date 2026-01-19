
# SQLinLean TODO

Prioritized task list for the project.

## Immediate (This Week)

- [x] Merge PR #18 (Codespace setup + Claude skills) ✓
- [x] Merge PR #25 (Use case docs + testing infrastructure) ✓
- [ ] Merge PR #29 (ORDER BY, LIMIT, OFFSET parsing)
- [ ] Download Spider dataset: `./scripts/download-spider.sh`
- [ ] Run baseline parser test: `./scripts/test-corpus.sh spider`
- [ ] Document current parse success rate

## Known Bugs (Parser)

All previously documented bugs have been fixed:

- [x] ~~NULL keyword not handled~~ - Fixed in `parsePrimary`
- [x] ~~Table aliases not parsed~~ - Fixed in `parseSelect`
- [x] ~~NOT operator not parsed~~ - Fixed with `parseNot` function

## Short-Term (Parser Completion)

Based on ROADMAP.md Phase 1 and expected corpus failures:

### High Priority (Common in Real Queries)
- [ ] JOIN parsing (INNER, LEFT, RIGHT, OUTER) - AST exists
- [x] ORDER BY parsing (PR #29)
- [x] LIMIT/OFFSET parsing (PR #29)
- [ ] Aggregate functions (COUNT, SUM, AVG, MIN, MAX)
- [ ] GROUP BY / HAVING

### Medium Priority
- [ ] UPDATE statement parser - AST exists
- [ ] CREATE TABLE parser - AST exists
- [ ] DISTINCT keyword
- [ ] IN operator
- [ ] BETWEEN operator
- [ ] LIKE operator
- [ ] IS NULL / IS NOT NULL

### Lower Priority
- [ ] Subqueries
- [ ] CASE expressions
- [ ] UNION / INTERSECT / EXCEPT
- [ ] Window functions

## Testing & Validation

- [ ] Measure Spider corpus success rate (Issue #28)
- [ ] Measure WikiSQL corpus success rate
- [ ] Categorize failures by feature
- [ ] Add round-trip property test (parse → print → parse)
- [ ] Set up CI to run subset of corpus tests

## Documentation

- [ ] Add usage examples to README
- [ ] Document supported SQL subset
- [ ] Add contributor guide

## Longer-Term (Use Cases)

See `docs/use-cases/` and GitHub issues #19-#27:

| Priority | Use Case | Issue |
|----------|----------|-------|
| High | SQL Linter | #20 |
| High | Type-Safe Database Access | #21 |
| Medium | Query Equivalence | #22 |
| Medium | Verified Query Optimizer | #19 |
| Medium | Schema Migration Safety | #26 |
| Lower | SQL Transpiler | #23 |
| Lower | RLS Verification | #27 |
| Lower | Educational Platform | #24 |

## Research

- [ ] Review `provenance-lean` repo for Lean4 SQL patterns
- [ ] Explore SlimCheck for property-based testing
- [ ] Investigate Cosette for equivalence checking approaches

---

*Last updated: 2026-01-19*
