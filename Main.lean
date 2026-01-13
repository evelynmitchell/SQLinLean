import SQLinLean

open SQLinLean

def main : IO Unit := do
  IO.println s!"Welcome to {hello}!"
  IO.println ""
  
  -- Example 1: Simple SELECT
  IO.println "Example 1: Parsing 'SELECT * FROM users'"
  match parseSQL "SELECT * FROM users" with
  | .inl err => IO.println s!"Error: {err}"
  | .inr stmt => IO.println s!"Success: {repr stmt}"
  IO.println ""
  
  -- Example 2: SELECT with WHERE
  IO.println "Example 2: Parsing 'SELECT name, age FROM users WHERE age > 18'"
  match parseSQL "SELECT name, age FROM users WHERE age > 18" with
  | .inl err => IO.println s!"Error: {err}"
  | .inr stmt => IO.println s!"Success: {repr stmt}"
  IO.println ""
  
  -- Example 3: INSERT
  IO.println "Example 3: Parsing 'INSERT INTO users VALUES (1, 'Alice')'"
  match parseSQL "INSERT INTO users VALUES (1, 'Alice')" with
  | .inl err => IO.println s!"Error: {err}"
  | .inr stmt => IO.println s!"Success: {repr stmt}"
  IO.println ""
  
  -- Example 4: DELETE
  IO.println "Example 4: Parsing 'DELETE FROM users WHERE id = 5'"
  match parseSQL "DELETE FROM users WHERE id = 5" with
  | .inl err => IO.println s!"Error: {err}"
  | .inr stmt => IO.println s!"Success: {repr stmt}"
