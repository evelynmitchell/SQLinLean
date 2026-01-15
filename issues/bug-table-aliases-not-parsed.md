# Bug: Table aliases not parsed in FROM clause

## Description

The parser does not handle table aliases in the FROM clause. SQL statements like `SELECT * FROM users AS u` or `SELECT * FROM users u` should parse the alias, but currently the alias is always `none`.

## Current Behavior

```lean
-- Parser.lean:219-220
let fromTable := some (TableRef.Table tableName none)  -- alias is always none
```

The parser only reads the table name and ignores any following `AS alias` or implicit alias.

## Expected Behavior

`SELECT u.name FROM users AS u` should parse to:
```
Statement.Select
  [SelectItem.Expr (Expr.QualifiedIdentifier "u" "name") none]
  (some (TableRef.Table "users" (some "u")))  -- alias should be "u"
  none _ _ _
```

## Location

- `SQLinLean/Parser.lean:212-233` - `parseSelect` function, specifically the FROM clause parsing

## Suggested Fix

After parsing the table name, check for `AS` keyword or an identifier:

```lean
match parseIdentifier (s''.advance) with
| .error msg state => .error msg state
| .ok tableName s''' =>
    -- Parse optional table alias
    let (tableAlias, s'''') :=
      match s'''.peek with
      | some (.Keyword .AS) =>
        match parseIdentifier (s'''.advance) with
        | .ok alias st => (some alias, st)
        | .error _ _ => (none, s''')
      | some (.Identifier alias) =>
        (some alias, s'''.advance)
      | _ => (none, s''')
    let fromTable := some (TableRef.Table tableName tableAlias)
    -- Continue with WHERE parsing using s''''
```

## Test Case

There's already a test expecting this behavior in `Tests/ParserTestsExtended.lean:23-33`:
```lean
def testSelectTableAlias : IO Unit := do
  match parseSQL "SELECT u.name FROM users AS u" with
  | Sum.inr stmt =>
      match stmt with
      | Statement.Select [SelectItem.Expr (Expr.QualifiedIdentifier "u" "name") none]
                        (some (TableRef.Table "users" (some "u"))) none _ _ _ =>
          IO.println "PASS: testSelectTableAlias"
```

## Labels

`bug`, `parser`
