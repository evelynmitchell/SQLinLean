# Technical Documentation

Implementation approaches, design patterns, and architectural decisions for SQLinLean.

## Documents

| Document | Description |
|----------|-------------|
| [Two-Phase Architecture](two-phase-architecture.md) | Raw AST + Schema Validation approach |
| [Property-Based Testing](property-based-testing.md) | Using SlimCheck for SQL testing |
| [Dependent Types for SQL](dependent-types.md) | Schema-aware types with proofs |
| [NULL Semantics](null-semantics.md) | Handling SQL's 3-valued logic |

## Key Architectural Decisions

### Why Two Phases?

1. **Phase 1 (Parser → Raw AST)**: Schema-agnostic, always succeeds for valid syntax
2. **Phase 2 (Raw AST → Typed AST)**: Schema-dependent validation

This allows the library to be useful even without a schema (linting, formatting, transpilation).

### Why Lean Over LSP?

| Feature | Standard LSP | Lean 4 |
|---------|--------------|--------|
| Syntax Checking | ✅ Best | Overkill |
| Autocomplete | ✅ Best | Limited |
| Type Checking | Partial | ✅ Guaranteed |
| Logic Verification | ❌ | ✅ Primary use |
| Refactoring Safety | ❌ | ✅ Provable |

**Use LSP** for writing (autocomplete, highlighting).
**Use Lean** for committing (CI/CD, verification).
