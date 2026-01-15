# SQLinLean Roadmap

## Current State

SQLinLean is a SQL parser in Lean4 that supports:
- SELECT, INSERT, DELETE statements
- Expressions with proper operator precedence
- WHERE clauses, table aliases, qualified identifiers

This document outlines potential directions for the project.

---

## Use Cases (Detailed)

### 1. Verified Query Optimizer

**The Problem**: Query optimizers transform SQL into equivalent but faster forms. Bugs in optimizers can silently return wrong results - one of the worst kinds of bugs in database systems.

**How Lean4 Helps**: You can *prove* that transformations preserve query semantics.

**Concrete Example**:
```lean
-- Define what a query means (denotational semantics)
def eval (q : Statement) (db : Database) : Table := ...

-- A rewrite rule: push predicates through joins
def pushPredicateIntoJoin (q : Statement) : Statement := ...

-- PROVE it's correct - this is checked by Lean's type system
theorem pushPredicate_correct (q : Statement) (db : Database) :
  eval (pushPredicateIntoJoin q) db = eval q db := by
  -- proof goes here
```

**Real-World Value**:
- Cockroach Labs and others have found optimizer bugs that returned wrong data
- Microsoft Research has explored verified query optimization
- Could be used in safety-critical systems (medical, financial)

---

### 2. SQL Linter / Static Analyzer

**The Problem**: SQL queries can have subtle issues - performance problems, potential NULL bugs, injection vulnerabilities - that are hard to catch in code review.

**How Lean4 Helps**: Build analysis passes with strong type safety, potentially proving properties about the analysis itself.

**Concrete Examples**:

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

**Real-World Value**:
- Integrate into CI/CD pipelines
- Catch bugs before they hit production
- Enforce SQL style guidelines

---

### 3. Type-Safe Database Access Layer

**The Problem**: SQL queries in application code are typically strings - no compile-time checking that they're valid or match your schema.

**How Lean4 Helps**: Validate queries at compile time against a schema.

**Concrete Example**:
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

**Real-World Value**:
- Catch schema mismatches at compile time, not runtime
- Refactor database schemas with confidence
- Similar to what sqlx does for Rust, but with stronger guarantees

---

### 4. Query Equivalence Checking

**The Problem**: "Is this optimized query equivalent to the original?" or "Do these two queries return the same results?"

**How Lean4 Helps**: Formally prove or disprove query equivalence.

**Concrete Example**:
```lean
-- Are these equivalent?
def q1 := sql! "SELECT * FROM users WHERE age > 18 AND age < 65"
def q2 := sql! "SELECT * FROM users WHERE age BETWEEN 19 AND 64"

-- Prove equivalence (or find counterexample)
theorem q1_equiv_q2 : equivalent q1 q2 := by ...
```

**Real-World Value**:
- Verify query rewrites are correct
- Test query optimizer correctness
- Academic research in database theory

---

### 5. SQL-to-X Transpiler

**The Problem**: Migrate queries between database dialects (PostgreSQL to MySQL), or compile SQL to other languages.

**How Lean4 Helps**: Type-safe AST transformations with optional correctness proofs.

**Concrete Example**:
```lean
-- Convert SQL to a DataFrame DSL
def sqlToDataFrame (q : Statement) : DataFrameExpr := ...

-- Convert between SQL dialects
def postgresqlToMysql (q : Statement) : Statement := ...

-- Prove the transpilation preserves semantics
theorem transpile_correct (q : Statement) :
  evalPostgres q = evalMysql (postgresqlToMysql q) := by ...
```

---

### 6. Educational Platform

**The Problem**: Learning SQL semantics, parsing, and formal methods is difficult without hands-on tools.

**How Lean4 Helps**: Interactive environment where students can:
- See how SQL is parsed step-by-step
- Write simple query transformations
- Learn formal verification with a familiar domain

---

## Development Roadmap

### Phase 1: Complete the Parser (Current)
**Goal**: Full SQL parsing coverage

**Tasks**:
- [ ] UPDATE statement parser (AST `Statement.Update` already defined)
- [ ] CREATE TABLE parser (AST `Statement.CreateTable` already defined)
- [ ] JOIN parser (AST `JoinType`, `TableRef.Join` already defined)
- [ ] ORDER BY, GROUP BY, HAVING parser (AST fields exist in `Statement.Select`)
- [ ] LIMIT, OFFSET parser (AST fields exist in `Statement.Select`)
- [ ] Subqueries
- [ ] Aggregate functions (COUNT, SUM, AVG, MIN, MAX)
- [ ] DISTINCT
- [ ] CASE expressions
- [ ] IN, BETWEEN, LIKE operators
- [ ] IS NULL / IS NOT NULL

**Enables**: Basic SQL tooling, formatting, syntax validation

---

### Phase 2: Schema Representation
**Goal**: Represent database schemas in Lean4

**Tasks**:
- [ ] Define Schema type (tables, columns, types)
- [ ] Define Column types (Integer, String, Float, Boolean, Date, etc.)
- [ ] Primary key / foreign key constraints
- [ ] NOT NULL constraints
- [ ] Schema validation functions
- [ ] Schema parser (from SQL CREATE statements)

**New Types**:
```lean
inductive ColumnType where
  | Integer | String | Float | Boolean | Date | Timestamp | Nullable (t : ColumnType)

structure Column where
  name : String
  type : ColumnType
  isPrimaryKey : Bool := false

structure Table where
  name : String
  columns : List Column

structure Schema where
  tables : List Table
  foreignKeys : List (String × String × String × String)  -- (table, col, refTable, refCol)
```

**Enables**: Schema-aware analysis, type checking queries against schemas

---

### Phase 3: Semantic Model
**Goal**: Define what SQL queries *mean* mathematically

**Tasks**:
- [ ] Define Table as a type (List of Rows, or Set of Rows)
- [ ] Define Database as a mapping from table names to Tables
- [ ] Define evaluation function: `eval : Statement → Database → Table`
- [ ] Handle NULL semantics (three-valued logic)
- [ ] Define expression evaluation
- [ ] Define filtering (WHERE)
- [ ] Define projection (SELECT columns)
- [ ] Define joins

**Core Definition**:
```lean
-- A row is a mapping from column names to values
def Row := String → Option Value

-- A table is a list of rows (bag semantics) or set of rows (set semantics)
def Table := List Row

-- A database is a mapping from table names to tables
def Database := String → Option Table

-- The denotational semantics of SQL
def eval : Statement → Database → Option Table
  | .Select cols from where_ _ _ _, db => do
    -- Note: orderBy, limit, offset handling omitted for brevity
    let baseTable ← evalFrom from db
    let filtered := evalWhere where_ baseTable
    let projected := evalSelect cols filtered
    return projected
  | .Insert tableName _ values, db => ...
  | .Delete tableName where_, db => ...
  | ...
```

**Enables**: Reasoning about query behavior, equivalence proofs

---

### Phase 4: Query Analysis
**Goal**: Build analysis passes over SQL

**Tasks**:
- [ ] Collect referenced tables/columns
- [ ] Detect SELECT *
- [ ] Detect NULL comparisons (= NULL vs IS NULL)
- [ ] Detect always-true/false conditions
- [ ] Estimate selectivity (simple heuristics)
- [ ] Detect missing indexes (given schema)
- [ ] Type inference for expressions

**Enables**: SQL linter, IDE integration, query insights

---

### Phase 5: Query Transformations
**Goal**: Transform queries while (optionally) preserving semantics

**Tasks**:
- [ ] Constant folding (1 + 1 → 2)
- [ ] Predicate simplification (x AND true → x)
- [ ] Predicate pushdown
- [ ] Join reordering
- [ ] Subquery unnesting
- [ ] Common subexpression elimination

**With Proofs** (optional but valuable):
```lean
def constantFold (e : Expr) : Expr := ...

theorem constantFold_preserves_semantics (e : Expr) (env : Row) :
  evalExpr (constantFold e) env = evalExpr e env := by
  induction e <;> simp [constantFold, evalExpr, *]
```

**Enables**: Verified query optimizer, safe query rewriting

---

### Phase 6: Compile-Time Query Validation
**Goal**: Validate SQL queries against schemas at compile time

**Tasks**:
- [ ] Macro for SQL literals: `sql! "SELECT ..."`
- [ ] Schema-aware type checking
- [ ] Column existence validation
- [ ] Type compatibility checking
- [ ] Good error messages for invalid queries

**Enables**: Type-safe database access in Lean4 applications

---

## Suggested Starting Points

Depending on your interests:

| Interest | Start With |
|----------|------------|
| Finish the parser | Phase 1 - complete SQL coverage |
| Build a linter | Phase 2 + Phase 4 |
| Explore formal verification | Phase 3 (semantic model) |
| Practical tooling | Phase 1 + Phase 4 |
| Research project | Phase 3 + Phase 5 with proofs |

---

## Resources

- **Lean4 Documentation**: https://lean-lang.org/documentation/
- **Cosette** (SQL equivalence verifier): https://cosette.cs.washington.edu/
- **SQL Semantics Papers**:
  - "Semantics of SQL" by Guagliardo & Libkin
  - "Formal Semantics of SQL Queries" (various)
- **Verified Query Optimization**:
  - "Verified Query Optimization" (CIDR 2019)
  - HoTTSQL: Proving Query Rewrites with Univalent SQL Semantics

---

## Contributing

If you're interested in contributing to any of these phases, please open an issue to discuss!
