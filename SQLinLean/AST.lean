-- Abstract Syntax Tree for SQL statements
import SQLinLean.Token

namespace SQLinLean

-- Aggregate function types
inductive AggregateFunc where
  | Count
  | Sum
  | Avg
  | Min
  | Max
  deriving Repr, BEq, Nonempty

-- SQL Expression types
inductive Expr where
  | Literal (lit : Literal)
  | Identifier (name : String)
  | QualifiedIdentifier (table : String) (column : String)
  | Star
  | QualifiedStar (table : String)
  | BinaryOp (left : Expr) (op : Operator) (right : Expr)
  | Not (expr : Expr)  -- NOT unary operator
  | Aggregate (func : AggregateFunc) (arg : Expr) (distinct : Bool)  -- COUNT(x), SUM(DISTINCT x), etc.
  deriving Repr, BEq, Nonempty

-- Column selection in SELECT
inductive SelectItem where
  | Expr (expr : Expr) (alias : Option String)
  | AllColumns
  deriving Repr, BEq, Nonempty

-- JOIN types
inductive JoinType where
  | Inner
  | Left
  | Right
  | Full
  deriving Repr, BEq, Nonempty

-- Table reference
inductive TableRef where
  | Table (name : String) (alias : Option String)
  | Join (left : TableRef) (joinType : JoinType) (right : TableRef) (condition : Expr)
  deriving Repr, BEq, Nonempty

-- SQL Statement types
inductive Statement where
  | Select
      (columns : List SelectItem)
      (fromTable : Option TableRef)
      (whereClause : Option Expr)
      (groupBy : List Expr)           -- GROUP BY expressions
      (having : Option Expr)          -- HAVING condition
      (orderBy : List (Expr × Bool))  -- (expression, isAscending)
      (limit : Option Nat)
      (offset : Option Nat)
  | Insert
      (table : String)
      (columns : List String)
      (values : List (List Expr))
  | Update
      (table : String)
      (assignments : List (String × Expr))
      (whereClause : Option Expr)
  | Delete
      (table : String)
      (whereClause : Option Expr)
  | CreateTable
      (table : String)
      (columns : List (String × String))  -- (column_name, data_type)
  deriving Repr, BEq, Nonempty

end SQLinLean
