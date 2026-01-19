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

-- JOIN types
inductive JoinType where
  | Inner
  | Left
  | Right
  | Full
  deriving Repr, BEq, Nonempty

-- Mutually recursive types for expressions, table refs, and statements
mutual
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
    | IsNull (expr : Expr) (negated : Bool)  -- IS NULL (negated=false) or IS NOT NULL (negated=true)
    | In (expr : Expr) (values : List Expr) (negated : Bool)  -- IN (1,2,3)
    | InSubquery (expr : Expr) (subquery : Statement) (negated : Bool)  -- IN (SELECT ...)
    | Between (expr : Expr) (low : Expr) (high : Expr) (negated : Bool)  -- BETWEEN low AND high
    | Subquery (stmt : Statement)  -- Scalar subquery: (SELECT ...)

  -- Column selection in SELECT
  inductive SelectItem where
    | Expr (expr : Expr) (alias : Option String)
    | AllColumns

  -- Table reference
  inductive TableRef where
    | Table (name : String) (alias : Option String)
    | Join (left : TableRef) (joinType : JoinType) (right : TableRef) (condition : Expr)

  -- SQL Statement types
  inductive Statement where
    | Select
        (distinct : Bool)               -- SELECT DISTINCT
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
end

-- Derive instances for mutually recursive types
deriving instance Repr for Expr, SelectItem, TableRef, Statement
deriving instance BEq for Expr, SelectItem, TableRef, Statement

instance : Nonempty Expr := ⟨.Star⟩
instance : Nonempty SelectItem := ⟨.AllColumns⟩
instance : Nonempty TableRef := ⟨.Table "" none⟩
instance : Nonempty Statement := ⟨.Delete "" none⟩

end SQLinLean
