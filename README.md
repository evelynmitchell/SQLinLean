# SQLinLean

A SQL Parser implemented in Lean4 with tests and documentation.

## Overview

SQLinLean is a comprehensive SQL parser library written in Lean4. It provides:
- **Lexical Analysis**: Tokenization of SQL statements
- **Parsing**: Conversion of tokens into Abstract Syntax Trees (AST)
- **Type Safety**: Full type checking at compile time using Lean4's dependent types
- **Test Suite**: Comprehensive unit tests for lexer and parser

## Features

### Supported SQL Keywords
- `SELECT`, `FROM`, `WHERE`
- `INSERT`, `INTO`, `VALUES`
- `UPDATE`, `SET`
- `DELETE`
- `CREATE`, `TABLE`, `DROP`, `ALTER`
- `AND`, `OR`, `NOT`, `NULL`
- `AS`, `JOIN`, `LEFT`, `RIGHT`, `INNER`, `OUTER`, `ON`
- `ORDER`, `BY`, `GROUP`, `HAVING`, `LIMIT`, `OFFSET`

### Supported Operators
- Comparison: `=`, `!=`, `<>`, `<`, `>`, `<=`, `>=`
- Arithmetic: `+`, `-`, `*`, `/`

### Supported SQL Statements
1. **SELECT**: Query data with columns, FROM clause, WHERE conditions
2. **INSERT**: Insert data with VALUES clause
3. **DELETE**: Delete data with WHERE conditions
4. **UPDATE**: (partial support)

## Architecture

The parser is built in layers:

### 1. Token Module (`SQLinLean/Token.lean`)
Defines the token types used by the lexer:
- `Keyword`: SQL keywords
- `Identifier`: Table and column names
- `Operator`: Comparison and arithmetic operators
- `Literal`: String, Integer, Float, Boolean, and NULL literals

### 2. Lexer Module (`SQLinLean/Lexer.lean`)
Tokenizes SQL strings into a list of tokens. Features:
- Case-insensitive keyword recognition
- String literals with escape sequences
- Number literals (integers and floats)
- Whitespace handling

### 3. AST Module (`SQLinLean/AST.lean`)
Defines the Abstract Syntax Tree structures:
- `Expr`: SQL expressions (identifiers, literals, binary operations)
- `SelectItem`: Column selections in SELECT statements
- `TableRef`: Table references with optional aliases
- `Statement`: SQL statement types

### 4. Parser Module (`SQLinLean/Parser.lean`)
Converts token lists into AST statements using recursive descent parsing with mutual recursion for expression precedence.

## Installation

### Prerequisites
- Lean4 (via elan)
- Lake (Lean's build tool)

### Installing Lean4
```bash
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh
```

### Building the Project
```bash
lake build
```

## Usage

### As a Library
```lean
import SQLinLean

open SQLinLean

def example : IO Unit := do
  match parseSQL "SELECT * FROM users WHERE age > 18" with
  | Sum.inl err => IO.println s!"Error: {err}"
  | Sum.inr stmt => IO.println s!"Success: {repr stmt}"
```

### Running the Demo
```bash
lake build
./.lake/build/bin/sqlinlean
```

Output:
```
Welcome to SQLinLean - SQL Parser in Lean4!

Example 1: Parsing 'SELECT * FROM users'
Success: SQLinLean.Statement.Select ...

Example 2: Parsing 'SELECT name, age FROM users WHERE age > 18'
Success: SQLinLean.Statement.Select ...

...
```

### Running Tests
```bash
lake build tests
./.lake/build/bin/tests
```

## Examples

### Simple SELECT
```sql
SELECT * FROM users
```

### SELECT with Columns
```sql
SELECT name, age FROM users
```

### SELECT with WHERE Clause
```sql
SELECT * FROM users WHERE age > 18
```

### Qualified Column Names
```sql
SELECT users.name, users.email FROM users
```

### Multiple WHERE Conditions
```sql
SELECT * FROM users WHERE age > 18 AND status = 1
```

### INSERT Statement
```sql
INSERT INTO users VALUES (1, 'Alice')
```

### DELETE Statement
```sql
DELETE FROM users WHERE id = 5
```

## API Reference

### Main Functions

#### `parseSQL : String → String ⊕ Statement`
Parse a SQL string into a Statement or return an error message.

#### `tokenizeString : String → LexerResult (List Token)`
Tokenize a SQL string into a list of tokens.

### Data Types

#### `Statement`
```lean
inductive Statement where
  | Select (columns : List SelectItem) (fromTable : Option TableRef) 
           (whereClause : Option Expr) (orderBy : List (Expr × Bool))
           (limit : Option Nat) (offset : Option Nat)
  | Insert (table : String) (columns : List String) (values : List (List Expr))
  | Update (table : String) (assignments : List (String × Expr)) 
           (whereClause : Option Expr)
  | Delete (table : String) (whereClause : Option Expr)
  | CreateTable (table : String) (columns : List (String × String))
```

#### `Expr`
```lean
inductive Expr where
  | Literal (lit : Literal)
  | Identifier (name : String)
  | QualifiedIdentifier (table : String) (column : String)
  | Star
  | QualifiedStar (table : String)
  | BinaryOp (left : Expr) (op : Operator) (right : Expr)
  | UnaryOp (op : Keyword) (expr : Expr)
```

## References

- SQL Standard: [Wikipedia - SQL](https://en.wikipedia.org/wiki/SQL)
- PostgreSQL Parser: [PostgreSQL Documentation](https://www.postgresql.org/docs/current/parser-stage.html)
- SQLite Parser: [SQLite Lemon Parser](https://sqlite.org/lemon.html)
- Lean4 Standard Library: [Std.Time.Format](https://leanprover-community.github.io/mathlib4_docs/Std/Time/Format.html#Std.Time.PlainDate.toSQLDateString)
- Lean4 Language Reference: [Loogle - SQL Search](https://loogle.lean-lang.org/?q=%22sql%22)

## Testing

The project includes comprehensive tests:
- **Lexer Tests**: Token generation, keyword recognition, operator parsing
- **Parser Tests**: Statement parsing, expression handling, error cases

All tests are located in the `Tests/` directory and can be run with:
```bash
lake build tests && ./.lake/build/bin/tests
```

## Contributing

Contributions are welcome! Areas for improvement:
- Support for more SQL statements (UPDATE with full features, CREATE TABLE, ALTER, etc.)
- JOIN support (syntax is defined but parsing not fully implemented)
- Subqueries
- Aggregate functions (COUNT, SUM, AVG, etc.)
- DISTINCT, GROUP BY, HAVING clauses
- Better error messages with line/column numbers

## License

This project is open source. See LICENSE file for details.

## Author

Evelyn Mitchell

## Acknowledgments

Built with Lean4, leveraging its powerful type system and theorem proving capabilities to create a robust SQL parser.