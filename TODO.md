
# SQLinLean TODO

Prioritized task list for the project.

## Immediate (This Week)

- [x] Merge PR #18 (Codespace setup + Claude skills) ✓
- [x] Merge PR #25 (Use case docs + testing infrastructure) ✓
- [x] Merge PR #29 (ORDER BY, LIMIT, OFFSET parsing) ✓
- [x] Download Spider dataset ✓
- [x] Run baseline parser test ✓
- [x] Document current parse success rate ✓

## Spider Corpus Results (2026-01-19)

**Success Rate: 100%** (500/500 queries)

| Fix | Success Rate |
|-----|--------------|
| Baseline | 76.2% |
| + Double-quoted strings | 93.4% |
| + Subqueries | 99.4% |
| + Multi-JOIN syntax | **100.0%** |

See: `tests/data/results/spider-100-percent-2026-01-19.md`
Run: `uv run scripts/test-spider.py --categorize`

## Known Bugs (Parser)

All previously documented bugs have been fixed:

- [x] ~~NULL keyword not handled~~ - Fixed in `parsePrimary`
- [x] ~~Table aliases not parsed~~ - Fixed in `parseSelect`
- [x] ~~NOT operator not parsed~~ - Fixed with `parseNot` function

## Short-Term (Parser Completion)

Based on ROADMAP.md Phase 1 and expected corpus failures:

### High Priority (Common in Real Queries)
- [x] JOIN parsing (INNER, LEFT, RIGHT, FULL OUTER)
- [x] ORDER BY parsing (PR #29)
- [x] LIMIT/OFFSET parsing (PR #29)
- [x] Aggregate functions (COUNT, SUM, AVG, MIN, MAX) (PR #31)
- [x] GROUP BY / HAVING
- [x] **Double-quoted strings** - Fixed: 76.2% → 93.4%

### Medium Priority
- [ ] UPDATE statement parser - AST exists
- [ ] CREATE TABLE parser - AST exists
- [x] DISTINCT keyword
- [x] IN operator
- [x] BETWEEN operator
- [x] LIKE operator
- [x] IS NULL / IS NOT NULL

### Lower Priority
- [x] Subqueries - 93.4% → 99.4%
- [ ] CASE expressions
- [ ] UNION / INTERSECT / EXCEPT
- [ ] Window functions

## Testing & Validation

- [x] Measure Spider corpus success rate (76.2% baseline)
- [ ] Measure WikiSQL corpus success rate
- [x] Categorize failures by feature
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
