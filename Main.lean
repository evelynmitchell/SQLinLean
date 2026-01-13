import SQLinLean

open SQLinLean

def main : IO Unit := do
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
