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

-- Single source of truth: keyword string mappings
private def keywordTable : List (String × Keyword) :=
  [("SELECT", .SELECT), ("FROM", .FROM), ("WHERE", .WHERE), ("INSERT", .INSERT),
   ("INTO", .INTO), ("VALUES", .VALUES), ("UPDATE", .UPDATE), ("SET", .SET),
   ("DELETE", .DELETE), ("CREATE", .CREATE), ("TABLE", .TABLE), ("DROP", .DROP),
   ("ALTER", .ALTER), ("AND", .AND), ("OR", .OR), ("NOT", .NOT), ("NULL", .NULL),
   ("AS", .AS), ("JOIN", .JOIN), ("LEFT", .LEFT), ("RIGHT", .RIGHT),
   ("INNER", .INNER), ("OUTER", .OUTER), ("FULL", .FULL), ("ON", .ON),
   ("ORDER", .ORDER), ("BY", .BY), ("GROUP", .GROUP), ("HAVING", .HAVING),
   ("LIMIT", .LIMIT), ("OFFSET", .OFFSET), ("ASC", .ASC), ("DESC", .DESC),
   ("COUNT", .COUNT), ("SUM", .SUM), ("AVG", .AVG), ("MIN", .MIN), ("MAX", .MAX),
   ("DISTINCT", .DISTINCT), ("IS", .IS), ("LIKE", .LIKE), ("IN", .IN),
   ("BETWEEN", .BETWEEN)]

def Keyword.toString (kw : Keyword) : String :=
  match keywordTable.find? (·.2 == kw) with
  | some (s, _) => s
  | none => "" -- unreachable for valid keywords

def Keyword.fromString? (s : String) : Option Keyword :=
  keywordTable.find? (·.1 == s.toUpper) |>.map (·.2)

end SQLinLean
