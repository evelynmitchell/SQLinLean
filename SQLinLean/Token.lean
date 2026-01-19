-- SQL Token types for lexical analysis
namespace SQLinLean

-- SQL Keywords
inductive Keyword where
  | SELECT
  | FROM
  | WHERE
  | INSERT
  | INTO
  | VALUES
  | UPDATE
  | SET
  | DELETE
  | CREATE
  | TABLE
  | DROP
  | ALTER
  | AND
  | OR
  | NOT
  | NULL
  | AS
  | JOIN
  | LEFT
  | RIGHT
  | INNER
  | OUTER
  | FULL
  | ON
  | ORDER
  | BY
  | GROUP
  | HAVING
  | LIMIT
  | OFFSET
  | ASC
  | DESC
  | COUNT
  | SUM
  | AVG
  | MIN
  | MAX
  | DISTINCT
  | IS
  | LIKE
  | IN
  | BETWEEN
  deriving Repr, BEq, DecidableEq, Nonempty

-- SQL Operators
inductive Operator where
  | Equals         -- =
  | NotEquals      -- !=, <>
  | LessThan       -- <
  | GreaterThan    -- >
  | LessOrEqual    -- <=
  | GreaterOrEqual -- >=
  | Plus           -- +
  | Minus          -- -
  | Multiply       -- *
  | Divide         -- /
  | And            -- AND logical operator
  | Or             -- OR logical operator
  | Like           -- LIKE pattern matching
  deriving Repr, BEq, DecidableEq, Nonempty

-- SQL Literal types
inductive Literal where
  | String (val : String)
  | Integer (val : Int)
  | Float (val : Float)
  | Boolean (val : Bool)
  | Null
  deriving Repr, BEq, Nonempty

-- SQL Token type
inductive Token where
  | Keyword (kw : Keyword)
  | Identifier (name : String)
  | Operator (op : Operator)
  | Literal (lit : Literal)
  | LeftParen
  | RightParen
  | Comma
  | Semicolon
  | Star         -- * (for SELECT *)
  | Dot          -- . (for table.column)
  | EOF
  deriving Repr, BEq, Nonempty

-- Helper functions
def Keyword.toString : Keyword → String
  | .SELECT => "SELECT"
  | .FROM => "FROM"
  | .WHERE => "WHERE"
  | .INSERT => "INSERT"
  | .INTO => "INTO"
  | .VALUES => "VALUES"
  | .UPDATE => "UPDATE"
  | .SET => "SET"
  | .DELETE => "DELETE"
  | .CREATE => "CREATE"
  | .TABLE => "TABLE"
  | .DROP => "DROP"
  | .ALTER => "ALTER"
  | .AND => "AND"
  | .OR => "OR"
  | .NOT => "NOT"
  | .NULL => "NULL"
  | .AS => "AS"
  | .JOIN => "JOIN"
  | .LEFT => "LEFT"
  | .RIGHT => "RIGHT"
  | .INNER => "INNER"
  | .OUTER => "OUTER"
  | .FULL => "FULL"
  | .ON => "ON"
  | .ORDER => "ORDER"
  | .BY => "BY"
  | .GROUP => "GROUP"
  | .HAVING => "HAVING"
  | .LIMIT => "LIMIT"
  | .OFFSET => "OFFSET"
  | .ASC => "ASC"
  | .DESC => "DESC"
  | .COUNT => "COUNT"
  | .SUM => "SUM"
  | .AVG => "AVG"
  | .MIN => "MIN"
  | .MAX => "MAX"
  | .DISTINCT => "DISTINCT"
  | .IS => "IS"
  | .LIKE => "LIKE"
  | .IN => "IN"
  | .BETWEEN => "BETWEEN"

def Keyword.fromString? (s : String) : Option Keyword :=
  match s.toUpper with
  | "SELECT" => some .SELECT
  | "FROM" => some .FROM
  | "WHERE" => some .WHERE
  | "INSERT" => some .INSERT
  | "INTO" => some .INTO
  | "VALUES" => some .VALUES
  | "UPDATE" => some .UPDATE
  | "SET" => some .SET
  | "DELETE" => some .DELETE
  | "CREATE" => some .CREATE
  | "TABLE" => some .TABLE
  | "DROP" => some .DROP
  | "ALTER" => some .ALTER
  | "AND" => some .AND
  | "OR" => some .OR
  | "NOT" => some .NOT
  | "NULL" => some .NULL
  | "AS" => some .AS
  | "JOIN" => some .JOIN
  | "LEFT" => some .LEFT
  | "RIGHT" => some .RIGHT
  | "INNER" => some .INNER
  | "OUTER" => some .OUTER
  | "FULL" => some .FULL
  | "ON" => some .ON
  | "ORDER" => some .ORDER
  | "BY" => some .BY
  | "GROUP" => some .GROUP
  | "HAVING" => some .HAVING
  | "LIMIT" => some .LIMIT
  | "OFFSET" => some .OFFSET
  | "ASC" => some .ASC
  | "DESC" => some .DESC
  | "COUNT" => some .COUNT
  | "SUM" => some .SUM
  | "AVG" => some .AVG
  | "MIN" => some .MIN
  | "MAX" => some .MAX
  | "DISTINCT" => some .DISTINCT
  | "IS" => some .IS
  | "LIKE" => some .LIKE
  | "IN" => some .IN
  | "BETWEEN" => some .BETWEEN
  | _ => none

end SQLinLean
