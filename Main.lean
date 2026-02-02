import SQLinLean

open SQLinLean

def runExamples : IO Unit := do
  let examples := [
    "SELECT * FROM users",
    "SELECT name, age FROM users WHERE age > 18",
    "INSERT INTO users VALUES (1, 'Alice')",
    "DELETE FROM users WHERE id = 5"
  ]

  for sql in examples do
    IO.println sql
    match parseSQL sql with
    | .inl err => IO.println s!"  Error: {err}"
    | .inr stmt => IO.println s!"  {repr stmt}"
    IO.println ""

def parseStdin : IO UInt32 := do
  let input ← IO.getStdin >>= (·.getLine)
  let sql := input.trim
  if sql.isEmpty then
    return 1  -- Empty input is invalid SQL
  match parseSQL sql with
  | .inl _ => return 1
  | .inr _ => return 0

def main (args : List String) : IO UInt32 := do
  if args.contains "--parse" then
    parseStdin
  else
    runExamples
    return 0
