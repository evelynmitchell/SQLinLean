-- SQL Parser
import SQLinLean.Token
import SQLinLean.AST
import SQLinLean.Lexer

namespace SQLinLean

-- Parser state
structure ParserState where
  tokens : List Token
  position : Nat := 0
  deriving Repr, Nonempty

-- Parser result type
inductive ParserResult (α : Type) where
  | ok (value : α) (state : ParserState)
  | error (msg : String) (state : ParserState)
  deriving Repr, Nonempty

-- Helper functions
def ParserState.peek (s : ParserState) : Option Token :=
  s.tokens[s.position]?

def ParserState.advance (s : ParserState) (n : Nat := 1) : ParserState :=
  { s with position := s.position + n }

def ParserState.isEOF (s : ParserState) : Bool :=
  match s.peek with
  | some .EOF => true
  | none => true
  | _ => false

-- Expect a specific token
def expect (token : Token) (s : ParserState) : ParserResult Unit :=
  match s.peek with
  | none => .error s!"Expected {repr token}, got EOF" s
  | some t =>
    if t == token then
      .ok () (s.advance)
    else
      .error s!"Expected {repr token}, got {repr t}" s

-- Expect a keyword
def expectKeyword (kw : Keyword) (s : ParserState) : ParserResult Unit :=
  expect (.Keyword kw) s

-- Parse an identifier
def parseIdentifier (s : ParserState) : ParserResult String :=
  match s.peek with
  | some (.Identifier name) => .ok name (s.advance)
  | some t => .error s!"Expected identifier, got {repr t}" s
  | none => .error "Expected identifier, got EOF" s

-- Aggregate function keyword mapping
private def aggregateFuncTable : List (Keyword × AggregateFunc) :=
  [(.COUNT, .Count), (.SUM, .Sum), (.AVG, .Avg), (.MIN, .Min), (.MAX, .Max)]

-- Expression parsing with mutual recursion and proper precedence
mutual
  -- Try to parse an aggregate function keyword, returns the function type if found
  partial def tryParseAggregateFunc (s : ParserState) : Option AggregateFunc × ParserState :=
    match s.peek with
    | some (.Keyword kw) =>
      match aggregateFuncTable.find? (·.1 == kw) with
      | some (_, func) => (some func, s.advance)
      | none => (none, s)
    | _ => (none, s)

  -- Parse aggregate function: FUNC ( [DISTINCT] expr )
  partial def parseAggregate (func : AggregateFunc) (s : ParserState) : ParserResult Expr :=
    match expect .LeftParen s with
    | .error msg state => .error msg state
    | .ok _ s' =>
      -- Check for DISTINCT
      let (distinct, s'') := match s'.peek with
        | some (.Keyword .DISTINCT) => (true, s'.advance)
        | _ => (false, s')
      -- Parse the argument expression (can be * for COUNT)
      match s''.peek with
      | some .Star =>
        let s''' := s''.advance
        match expect .RightParen s''' with
        | .error msg state => .error msg state
        | .ok _ s'''' => .ok (.Aggregate func .Star distinct) s''''
      | _ =>
        match parseOr s'' with
        | .error msg state => .error msg state
        | .ok expr s''' =>
          match expect .RightParen s''' with
          | .error msg state => .error msg state
          | .ok _ s'''' => .ok (.Aggregate func expr distinct) s''''

  -- Parse a primary expression (literals, identifiers, aggregates, parenthesized expressions)
  partial def parsePrimary (s : ParserState) : ParserResult Expr :=
    -- First check for aggregate functions
    let (aggFunc, s') := tryParseAggregateFunc s
    match aggFunc with
    | some func => parseAggregate func s'
    | none =>
      match s.peek with
      | some (.Literal lit) => ParserResult.ok (.Literal lit) (s.advance)
      | some (.Keyword .NULL) => ParserResult.ok (.Literal .Null) (s.advance)
      | some .Star => ParserResult.ok .Star (s.advance)
      | some (.Identifier name) =>
        let s' := s.advance
        match s'.peek with
        | some .Dot =>
          let s'' := s'.advance
          match parseIdentifier s'' with
          | ParserResult.ok colName s''' => ParserResult.ok (.QualifiedIdentifier name colName) s'''
          | ParserResult.error msg state => ParserResult.error msg state
        | _ => ParserResult.ok (.Identifier name) s'
      | some .LeftParen =>
        let s' := s.advance
        -- Check if it's a subquery (SELECT ...)
        match s'.peek with
        | some (.Keyword .SELECT) =>
          match parseSubquerySelect s' with
          | ParserResult.error msg state => ParserResult.error msg state
          | ParserResult.ok stmt s'' =>
            match expect .RightParen s'' with
            | ParserResult.error msg state => ParserResult.error msg state
            | ParserResult.ok _ s''' => ParserResult.ok (.Subquery stmt) s'''
        | _ =>
          -- Regular parenthesized expression
          match parseOr s' with
          | ParserResult.error msg state => ParserResult.error msg state
          | ParserResult.ok expr s'' =>
            match expect .RightParen s'' with
            | ParserResult.error msg state => ParserResult.error msg state
            | ParserResult.ok _ s''' => ParserResult.ok expr s'''
      | some t => ParserResult.error s!"Unexpected token in expression: {repr t}" s
      | none => ParserResult.error "Unexpected EOF in expression" s

  -- Parse multiplicative expressions: *, /
  partial def parseMultiplicative (s : ParserState) : ParserResult Expr :=
    let rec loop (left : Expr) (state : ParserState) : ParserResult Expr :=
      match state.peek with
      | some (.Operator op) =>
        match op with
        | .Multiply | .Divide =>
          let state' := state.advance
          match parsePrimary state' with
          | ParserResult.error msg st => ParserResult.error msg st
          | ParserResult.ok right st =>
            loop (.BinaryOp left op right) st
        | _ => ParserResult.ok left state
      | some .Star =>
        -- Handle * as multiplication operator in expression context
        let state' := state.advance
        match parsePrimary state' with
        | ParserResult.error msg st => ParserResult.error msg st
        | ParserResult.ok right st =>
          loop (.BinaryOp left .Multiply right) st
      | _ => ParserResult.ok left state
    match parsePrimary s with
    | ParserResult.error msg st => ParserResult.error msg st
    | ParserResult.ok left st => loop left st

  -- Parse additive expressions: +, -
  partial def parseAdditive (s : ParserState) : ParserResult Expr :=
    let rec loop (left : Expr) (state : ParserState) : ParserResult Expr :=
      match state.peek with
      | some (.Operator op) =>
        match op with
        | .Plus | .Minus =>
          let state' := state.advance
          match parseMultiplicative state' with
          | ParserResult.error msg st => ParserResult.error msg st
          | ParserResult.ok right st =>
            loop (.BinaryOp left op right) st
        | _ => ParserResult.ok left state
      | _ => ParserResult.ok left state
    match parseMultiplicative s with
    | ParserResult.error msg st => ParserResult.error msg st
    | ParserResult.ok left st => loop left st

  -- Parse IS NULL / IS NOT NULL (postfix unary operator)
  partial def parseIsNull (s : ParserState) : ParserResult Expr :=
    match parseAdditive s with
    | ParserResult.error msg state => ParserResult.error msg state
    | ParserResult.ok expr s' =>
      match s'.peek with
      | some (.Keyword .IS) =>
        let s'' := s'.advance
        match s''.peek with
        | some (.Keyword .NOT) =>
          let s''' := s''.advance
          match s'''.peek with
          | some (.Keyword .NULL) =>
            ParserResult.ok (.IsNull expr true) (s'''.advance)
          | _ => ParserResult.error "Expected NULL after IS NOT" s'''
        | some (.Keyword .NULL) =>
          ParserResult.ok (.IsNull expr false) (s''.advance)
        | _ => ParserResult.error "Expected NULL or NOT after IS" s''
      | _ => ParserResult.ok expr s'

  -- Parse column list for subquery SELECT
  -- Note: This duplicates some logic from parseSelectItem (defined after mutual block)
  -- because we need to call parseOr directly within the mutual block.
  partial def parseSubqueryColumns (s : ParserState) : ParserResult (List SelectItem) :=
    let rec loop (state : ParserState) : ParserResult (List SelectItem) :=
      match state.peek with
      | some .Star =>
        let item := SelectItem.AllColumns
        let state' := state.advance
        match state'.peek with
        | some .Comma => match loop (state'.advance) with
          | .ok rest st => .ok (item :: rest) st
          | .error msg st => .error msg st
        | _ => .ok [item] state'
      | _ =>
        match parseOr state with
        | .error msg st => .error msg st
        | .ok expr st =>
          -- Check for alias (AS name or just name)
          let (alias, st') := match st.peek with
            | some (.Keyword .AS) =>
              let st'' := st.advance
              match st''.peek with
              | some (.Identifier name) => (some name, st''.advance)
              | _ => (none, st)
            | some (.Identifier name) => (some name, st.advance)
            | _ => (none, st)
          let item := SelectItem.Expr expr alias
          match st'.peek with
          | some .Comma => match loop (st'.advance) with
            | .ok rest st'' => .ok (item :: rest) st''
            | .error msg st'' => .error msg st''
          | _ => .ok [item] st'
    loop s

  -- Parse simple table reference for subquery (table [AS alias])
  -- Note: This duplicates parseTableRefSimple (defined after mutual block)
  -- because we need access to parseOr for JOIN conditions.
  partial def parseSubqueryTableSimple (s : ParserState) : ParserResult TableRef :=
    match s.peek with
    | some (.Identifier name) =>
      let s' := s.advance
      let (alias, s'') := match s'.peek with
        | some (.Keyword .AS) =>
          let s'' := s'.advance
          match s''.peek with
          | some (.Identifier a) => (some a, s''.advance)
          | _ => (none, s')
        | some (.Identifier a) => (some a, s'.advance)
        | _ => (none, s')
      .ok (.Table name alias) s''
    | _ => .error "Expected table name in subquery" s

  -- Try to parse JOIN type keyword in subquery context
  partial def tryParseSubqueryJoinType (s : ParserState) : Option JoinType × ParserState :=
    match s.peek with
    | some (.Keyword .INNER) =>
      let s' := s.advance
      match s'.peek with
      | some (.Keyword .JOIN) => (some .Inner, s'.advance)
      | _ => (none, s)
    | some (.Keyword .LEFT) =>
      let s' := s.advance
      match s'.peek with
      | some (.Keyword .OUTER) =>
        let s'' := s'.advance
        match s''.peek with
        | some (.Keyword .JOIN) => (some .Left, s''.advance)
        | _ => (none, s)
      | some (.Keyword .JOIN) => (some .Left, s'.advance)
      | _ => (none, s)
    | some (.Keyword .RIGHT) =>
      let s' := s.advance
      match s'.peek with
      | some (.Keyword .OUTER) =>
        let s'' := s'.advance
        match s''.peek with
        | some (.Keyword .JOIN) => (some .Right, s''.advance)
        | _ => (none, s)
      | some (.Keyword .JOIN) => (some .Right, s'.advance)
      | _ => (none, s)
    | some (.Keyword .JOIN) => (some .Inner, s.advance)
    | _ => (none, s)

  -- Parse table reference with JOINs for subquery
  partial def parseSubqueryTable (s : ParserState) : ParserResult TableRef :=
    match parseSubqueryTableSimple s with
    | .error msg state => .error msg state
    | .ok left sAfterLeft =>
      -- Try to parse JOINs
      let rec parseJoins (currentRef : TableRef) (state : ParserState) : ParserResult TableRef :=
        let (joinType, sAfterJoinKw) := tryParseSubqueryJoinType state
        match joinType with
        | none => .ok currentRef state
        | some jt =>
          match parseSubqueryTableSimple sAfterJoinKw with
          | .error msg st => .error msg st
          | .ok rightTable sAfterRight =>
            match sAfterRight.peek with
            | some (.Keyword .ON) =>
              match parseOr (sAfterRight.advance) with
              | .error msg st => .error msg st
              | .ok cond sAfterCond =>
                let joined := TableRef.Join currentRef jt rightTable cond
                parseJoins joined sAfterCond
            | _ => .error "Expected ON after JOIN" sAfterRight
      parseJoins left sAfterLeft

  -- Parse a SELECT subquery (covers full SELECT syntax for subqueries)
  -- Note: This function duplicates parseSelect logic because it must be in the
  -- mutual block to allow parseOr/parsePrimary to parse (SELECT ...) subqueries.
  -- Lean's mutual recursion requires all mutually recursive functions in one block.
  partial def parseSubquerySelect (s : ParserState) : ParserResult Statement :=
    match s.peek with
    | some (.Keyword .SELECT) =>
      let s' := s.advance
      -- Check for DISTINCT
      let (distinct, s'') := match s'.peek with
        | some (.Keyword .DISTINCT) => (true, s'.advance)
        | _ => (false, s')
      -- Parse columns
      match parseSubqueryColumns s'' with
      | .error msg state => .error msg state
      | .ok columns s''' =>
        -- Parse FROM
        match s'''.peek with
        | some (.Keyword .FROM) =>
          match parseSubqueryTable (s'''.advance) with
          | .error msg state => .error msg state
          | .ok table sAfterFrom =>
            -- Parse optional WHERE
            let (whereClause, sAfterWhere) := match sAfterFrom.peek with
              | some (.Keyword .WHERE) =>
                match parseOr (sAfterFrom.advance) with
                | .ok expr st => (some expr, st)
                | .error _ _ => (none, sAfterFrom)
              | _ => (none, sAfterFrom)
            -- Parse optional GROUP BY
            let (groupBy, sAfterGroup) := match sAfterWhere.peek with
              | some (.Keyword .GROUP) =>
                let sg := sAfterWhere.advance
                match sg.peek with
                | some (.Keyword .BY) =>
                  let rec parseGroupExprs (state : ParserState) : List Expr × ParserState :=
                    match parseOr state with
                    | .ok expr st =>
                      match st.peek with
                      | some .Comma =>
                        let (rest, st') := parseGroupExprs (st.advance)
                        (expr :: rest, st')
                      | _ => ([expr], st)
                    | .error _ _ => ([], state)
                  parseGroupExprs (sg.advance)
                | _ => ([], sAfterWhere)
              | _ => ([], sAfterWhere)
            -- Parse optional HAVING
            let (having, sAfterHaving) := match sAfterGroup.peek with
              | some (.Keyword .HAVING) =>
                match parseOr (sAfterGroup.advance) with
                | .ok expr st => (some expr, st)
                | .error _ _ => (none, sAfterGroup)
              | _ => (none, sAfterGroup)
            -- Parse optional ORDER BY
            let (orderBy, sAfterOrder) := match sAfterHaving.peek with
              | some (.Keyword .ORDER) =>
                let so := sAfterHaving.advance
                match so.peek with
                | some (.Keyword .BY) =>
                  let rec parseOrderExprs (state : ParserState) : List (Expr × Bool) × ParserState :=
                    match parseOr state with
                    | .ok expr st =>
                      let (asc, st') := match st.peek with
                        | some (.Keyword .ASC) => (true, st.advance)
                        | some (.Keyword .DESC) => (false, st.advance)
                        | _ => (true, st)
                      match st'.peek with
                      | some .Comma =>
                        let (rest, st'') := parseOrderExprs (st'.advance)
                        ((expr, asc) :: rest, st'')
                      | _ => ([(expr, asc)], st')
                    | .error _ _ => ([], state)
                  parseOrderExprs (so.advance)
                | _ => ([], sAfterHaving)
              | _ => ([], sAfterHaving)
            -- Parse optional LIMIT
            let (limit, sAfterLimit) := match sAfterOrder.peek with
              | some (.Keyword .LIMIT) =>
                let sl := sAfterOrder.advance
                match sl.peek with
                | some (.Literal (.Integer n)) => (some n.toNat, sl.advance)
                | _ => (none, sAfterOrder)
              | _ => (none, sAfterOrder)
            -- Parse optional OFFSET
            let (offset, sAfterOffset) := match sAfterLimit.peek with
              | some (.Keyword .OFFSET) =>
                let so := sAfterLimit.advance
                match so.peek with
                | some (.Literal (.Integer n)) => (some n.toNat, so.advance)
                | _ => (none, sAfterLimit)
              | _ => (none, sAfterLimit)
            .ok (.Select distinct columns (some table) whereClause groupBy having orderBy limit offset) sAfterOffset
        | _ =>
          -- SELECT without FROM
          .ok (.Select distinct columns none none [] none [] none none) s'''
    | _ => .error "Expected SELECT in subquery" s

  -- Parse IN values or subquery: (SELECT ...) or (expr, expr, ...)
  -- Returns either In or InSubquery expression
  partial def parseInOrSubquery (left : Expr) (negated : Bool) (s : ParserState) : ParserResult Expr :=
    match expect .LeftParen s with
    | .error msg state => .error msg state
    | .ok _ s' =>
      match s'.peek with
      | some (.Keyword .SELECT) =>
        -- Parse subquery
        match parseSubquerySelect s' with
        | .error msg state => .error msg state
        | .ok stmt s'' =>
          match expect .RightParen s'' with
          | .error msg state => .error msg state
          | .ok _ s''' => .ok (.InSubquery left stmt negated) s'''
      | _ =>
        -- Parse expression list
        let rec parseExprList (state : ParserState) : ParserResult (List Expr) :=
          match parseOr state with
          | .error msg st => .error msg st
          | .ok expr st =>
            match st.peek with
            | some .Comma =>
              match parseExprList (st.advance) with
              | .error msg st' => .error msg st'
              | .ok rest st' => .ok (expr :: rest) st'
            | _ => .ok [expr] st
        match parseExprList s' with
        | .error msg state => .error msg state
        | .ok values s'' =>
          match expect .RightParen s'' with
          | .error msg state => .error msg state
          | .ok _ s''' => .ok (.In left values negated) s'''

  -- Parse BETWEEN: expr BETWEEN low AND high
  partial def parseBetween (left : Expr) (negated : Bool) (s : ParserState) : ParserResult Expr :=
    match parseIsNull s with
    | ParserResult.error msg state => ParserResult.error msg state
    | ParserResult.ok low s' =>
      match s'.peek with
      | some (.Keyword .AND) =>
        let s'' := s'.advance
        match parseIsNull s'' with
        | ParserResult.error msg state => ParserResult.error msg state
        | ParserResult.ok high s''' => ParserResult.ok (.Between left low high negated) s'''
      | _ => ParserResult.error "Expected AND in BETWEEN expression" s'

  -- Parse comparison expressions: =, <>, <, >, <=, >=, LIKE, IN, NOT IN, BETWEEN, NOT BETWEEN
  partial def parseComparison (s : ParserState) : ParserResult Expr :=
    match parseIsNull s with
    | ParserResult.error msg state => ParserResult.error msg state
    | ParserResult.ok left s' =>
      match s'.peek with
      | some (.Operator op) =>
        match op with
        | .Equals | .NotEquals | .LessThan | .GreaterThan | .LessOrEqual | .GreaterOrEqual =>
          let s'' := s'.advance
          match parseIsNull s'' with
          | ParserResult.error msg state => ParserResult.error msg state
          | ParserResult.ok right s''' => ParserResult.ok (.BinaryOp left op right) s'''
        | _ => ParserResult.ok left s'
      | some (.Keyword .LIKE) =>
        let s'' := s'.advance
        match parseIsNull s'' with
        | ParserResult.error msg state => ParserResult.error msg state
        | ParserResult.ok right s''' => ParserResult.ok (.BinaryOp left .Like right) s'''
      | some (.Keyword .IN) =>
        parseInOrSubquery left false (s'.advance)
      | some (.Keyword .BETWEEN) =>
        let s'' := s'.advance
        parseBetween left false s''
      | some (.Keyword .NOT) =>
        -- Check for NOT IN or NOT BETWEEN
        let s'' := s'.advance
        match s''.peek with
        | some (.Keyword .IN) =>
          parseInOrSubquery left true (s''.advance)
        | some (.Keyword .BETWEEN) =>
          let s''' := s''.advance
          parseBetween left true s'''
        | _ => ParserResult.ok left s'  -- Not NOT IN/BETWEEN, return left unchanged
      | _ => ParserResult.ok left s'

  -- Parse NOT expression (unary prefix operator)
  partial def parseNot (s : ParserState) : ParserResult Expr :=
    match s.peek with
    | some (.Keyword .NOT) =>
      let s' := s.advance
      match parseNot s' with
      | ParserResult.error msg state => ParserResult.error msg state
      | ParserResult.ok expr s'' => ParserResult.ok (.Not expr) s''
    | _ => parseComparison s

  -- Parse an AND expression
  partial def parseAnd (s : ParserState) : ParserResult Expr :=
    match parseNot s with
    | ParserResult.error msg state => ParserResult.error msg state
    | ParserResult.ok left s' =>
      match s'.peek with
      | some (.Keyword .AND) =>
        let s'' := s'.advance
        match parseAnd s'' with
        | ParserResult.error msg state => ParserResult.error msg state
        | ParserResult.ok right s''' =>
          ParserResult.ok (.BinaryOp left .And right) s'''
      | _ => ParserResult.ok left s'

  -- Parse an OR expression
  partial def parseOr (s : ParserState) : ParserResult Expr :=
    match parseAnd s with
    | ParserResult.error msg state => ParserResult.error msg state
    | ParserResult.ok left s' =>
      match s'.peek with
      | some (.Keyword .OR) =>
        let s'' := s'.advance
        match parseOr s'' with
        | ParserResult.error msg state => ParserResult.error msg state
        | ParserResult.ok right s''' =>
          ParserResult.ok (.BinaryOp left .Or right) s'''
      | _ => ParserResult.ok left s'
end

-- Main expression parser
def parseExpr := parseOr

-- Parse a select item
def parseSelectItem (s : ParserState) : ParserResult SelectItem :=
  match s.peek with
  | some .Star => .ok .AllColumns (s.advance)
  | _ =>
    match parseExpr s with
    | .error msg state => .error msg state
    | .ok expr s' =>
      match s'.peek with
      | some (.Keyword .AS) =>
        let s'' := s'.advance
        match parseIdentifier s'' with
        | .ok alias s''' => .ok (.Expr expr (some alias)) s'''
        | .error msg state => .error msg state
      | some (.Identifier alias) =>
        .ok (.Expr expr (some alias)) (s'.advance)
      | _ => .ok (.Expr expr none) s'

-- Parse comma-separated list
partial def parseList {α : Type} (parser : ParserState → ParserResult α)
    (s : ParserState) : ParserResult (List α) :=
  match parser s with
  | .error msg state => .error msg state
  | .ok item s' =>
    match s'.peek with
    | some .Comma =>
      let s'' := s'.advance
      match parseList parser s'' with
      | .error msg state => .error msg state
      | .ok rest s''' => .ok (item :: rest) s'''
    | _ => .ok [item] s'

-- Parse a natural number from a literal
def parseNat (s : ParserState) : ParserResult Nat :=
  match s.peek with
  | some (.Literal (.Integer n)) =>
    if n >= 0 then .ok n.toNat (s.advance)
    else .error "Expected non-negative integer" s
  | some t => .error s!"Expected integer, got {repr t}" s
  | none => .error "Expected integer, got EOF" s

-- Parse a simple table reference (table name with optional alias)
def parseTableRefSimple (s : ParserState) : ParserResult TableRef :=
  match parseIdentifier s with
  | .error msg state => .error msg state
  | .ok tableName s' =>
    let (tableAlias, s'') := match s'.peek with
      | some (.Keyword .AS) =>
        match parseIdentifier (s'.advance) with
        | .ok alias st => (some alias, st)
        | .error _ _ => (none, s')
      | some (.Identifier alias) =>
        (some alias, s'.advance)
      | _ => (none, s')
    .ok (TableRef.Table tableName tableAlias) s''

-- Try to parse [OUTER] JOIN after a join direction keyword, returning state after JOIN
private def tryParseOuterJoin (s : ParserState) : Option ParserState :=
  match s.peek with
  | some (.Keyword .OUTER) =>
    let s' := s.advance
    match s'.peek with
    | some (.Keyword .JOIN) => some s'.advance
    | _ => none
  | some (.Keyword .JOIN) => some s.advance
  | _ => none

-- Try to parse a join type keyword sequence
-- Returns (some joinType, state after JOIN keyword) or (none, original state)
def tryParseJoinType (s : ParserState) : Option JoinType × ParserState :=
  match s.peek with
  | some (.Keyword .INNER) =>
    let s' := s.advance
    match s'.peek with
    | some (.Keyword .JOIN) => (some .Inner, s'.advance)
    | _ => (none, s)
  | some (.Keyword .LEFT) =>
    match tryParseOuterJoin s.advance with
    | some s' => (some .Left, s')
    | none => (none, s)
  | some (.Keyword .RIGHT) =>
    match tryParseOuterJoin s.advance with
    | some s' => (some .Right, s')
    | none => (none, s)
  | some (.Keyword .FULL) =>
    match tryParseOuterJoin s.advance with
    | some s' => (some .Full, s')
    | none => (none, s)
  | some (.Keyword .JOIN) => (some .Inner, s.advance)  -- Plain JOIN = INNER JOIN
  | _ => (none, s)

-- Parse table reference with optional joins
-- Standard syntax: table [AS alias] [[INNER|LEFT|RIGHT|FULL] [OUTER] JOIN table [AS alias] ON expr]*
-- Non-standard extension: Accepts multi-JOIN without immediate ON clause (found in Spider benchmark)
--   Example: JOIN t1 JOIN t2 ON combined_condition
--   In this case, intermediate JOINs use Expr.True as placeholder condition
partial def parseTableRef (s : ParserState) : ParserResult TableRef :=
  match parseTableRefSimple s with
  | .error msg state => .error msg state
  | .ok table s' => parseTableRefJoins table s'
where
  parseTableRefJoins (leftTable : TableRef) (s : ParserState) : ParserResult TableRef :=
    let (joinType, s') := tryParseJoinType s
    match joinType with
    | none => .ok leftTable s  -- No more joins
    | some jt =>
      match parseTableRefSimple s' with
      | .error msg state => .error msg state
      | .ok rightTable s'' =>
        match s''.peek with
        | some (.Keyword .ON) =>
          match parseExpr (s''.advance) with
          | .error msg state => .error msg state
          | .ok condition s''' =>
            let joinedTable := TableRef.Join leftTable jt rightTable condition
            parseTableRefJoins joinedTable s'''
        | _ =>
          -- No ON clause - check if there's another JOIN (multi-JOIN syntax)
          -- This is a non-standard SQL extension found in Spider benchmark queries
          let (nextJoinType, _) := tryParseJoinType s''
          match nextJoinType with
          | some _ =>
            -- Another JOIN follows, use Expr.True as placeholder condition
            let joinedTable := TableRef.Join leftTable jt rightTable .True
            parseTableRefJoins joinedTable s''
          | none =>
            -- No more joins and no ON - error for standard case
            .error "Expected ON after JOIN table" s''

-- Parse ORDER BY item: expr [ASC|DESC]
def parseOrderByItem (s : ParserState) : ParserResult (Expr × Bool) :=
  match parseExpr s with
  | .error msg state => .error msg state
  | .ok expr s' =>
    match s'.peek with
    | some (.Keyword .ASC) => .ok (expr, true) (s'.advance)
    | some (.Keyword .DESC) => .ok (expr, false) (s'.advance)
    | _ => .ok (expr, true) s'  -- Default to ascending

-- Parse KEYWORD BY clause pattern (used for ORDER BY and GROUP BY)
private partial def parseKeywordByClause {α : Type} (kw : Keyword)
    (itemParser : ParserState → ParserResult α) (s : ParserState) : ParserResult (List α) :=
  match s.peek with
  | some (.Keyword k) =>
    if k == kw then
      let s' := s.advance
      match s'.peek with
      | some (.Keyword .BY) => parseList itemParser s'.advance
      | _ => .error s!"Expected BY after {kw.toString}" s'
    else .ok [] s
  | _ => .ok [] s

partial def parseOrderBy := parseKeywordByClause .ORDER parseOrderByItem

-- Parse optional keyword followed by Nat (used for LIMIT and OFFSET)
private def parseOptionalNat (kw : Keyword) (s : ParserState) : ParserResult (Option Nat) :=
  match s.peek with
  | some (.Keyword k) =>
    if k == kw then
      match parseNat s.advance with
      | .error msg state => .error msg state
      | .ok n s' => .ok (some n) s'
    else .ok none s
  | _ => .ok none s

def parseLimit := parseOptionalNat .LIMIT
def parseOffset := parseOptionalNat .OFFSET

partial def parseGroupBy := parseKeywordByClause .GROUP parseExpr

-- Parse HAVING clause: HAVING expr
def parseHaving (s : ParserState) : ParserResult (Option Expr) :=
  match s.peek with
  | some (.Keyword .HAVING) =>
    let s' := s.advance
    match parseExpr s' with
    | .error msg state => .error msg state
    | .ok expr s'' => .ok (some expr) s''
  | _ => .ok none s  -- No HAVING clause

-- Helper to parse the trailing clauses (GROUP BY, HAVING, ORDER BY, LIMIT, OFFSET) after WHERE
def parseSelectTrailing (distinct : Bool) (columns : List SelectItem) (fromTable : Option TableRef)
    (whereClause : Option Expr) (s : ParserState) : ParserResult Statement :=
  match parseGroupBy s with
  | .error msg state => .error msg state
  | .ok groupBy s' =>
    match parseHaving s' with
    | .error msg state => .error msg state
    | .ok having s'' =>
      match parseOrderBy s'' with
      | .error msg state => .error msg state
      | .ok orderBy s''' =>
        match parseLimit s''' with
        | .error msg state => .error msg state
        | .ok limit s'''' =>
          match parseOffset s'''' with
          | .error msg state => .error msg state
          | .ok offset s''''' =>
            .ok (.Select distinct columns fromTable whereClause groupBy having orderBy limit offset) s'''''

-- Parse SELECT statement
def parseSelect (s : ParserState) : ParserResult Statement :=
  match expectKeyword .SELECT s with
  | .error msg state => .error msg state
  | .ok _ s' =>
    -- Check for DISTINCT keyword
    let (distinct, s'') := match s'.peek with
      | some (.Keyword .DISTINCT) => (true, s'.advance)
      | _ => (false, s')
    match parseList parseSelectItem s'' with
    | .error msg state => .error msg state
    | .ok columns s''' =>
      -- Parse optional FROM clause with optional JOINs
      match s'''.peek with
      | some (.Keyword .FROM) =>
        match parseTableRef (s'''.advance) with
        | .error msg state => .error msg state
        | .ok tableRef sAfterFrom =>
          let fromTable := some tableRef
          -- Parse optional WHERE clause
          match sAfterFrom.peek with
          | some (.Keyword .WHERE) =>
            match parseExpr (sAfterFrom.advance) with
            | .error msg state => .error msg state
            | .ok expr sAfterWhere =>
              parseSelectTrailing distinct columns fromTable (some expr) sAfterWhere
          | _ =>
            parseSelectTrailing distinct columns fromTable none sAfterFrom
      | _ =>
        let fromTable := (none : Option TableRef)
        -- Parse optional WHERE clause when there is no FROM
        match s'''.peek with
        | some (.Keyword .WHERE) =>
          match parseExpr (s'''.advance) with
          | .error msg state => .error msg state
          | .ok expr s'''' =>
            parseSelectTrailing distinct columns fromTable (some expr) s''''
        | _ =>
          parseSelectTrailing distinct columns fromTable none s'''

-- Parse INSERT statement
def parseInsert (s : ParserState) : ParserResult Statement :=
  match expectKeyword .INSERT s with
  | .error msg state => .error msg state
  | .ok _ s' =>
    match expectKeyword .INTO s' with
    | .error msg state => .error msg state
    | .ok _ s'' =>
      match parseIdentifier s'' with
      | .error msg state => .error msg state
      | .ok tableName s''' =>
        -- Parse optional column list. If left paren is present, columns are required.
        match s'''.peek with
        | some .LeftParen =>
          match parseList parseIdentifier (s'''.advance) with
          | .error msg state => .error msg state
          | .ok cols s =>
            match expect .RightParen s with
            | .error msg state => .error msg state
            | .ok _ s' =>
              -- Parse VALUES
              match expectKeyword .VALUES s' with
              | .error msg state => .error msg state
              | .ok _ s'' =>
                -- Parse value list
                match expect .LeftParen s'' with
                | .error msg state => .error msg state
                | .ok _ s''' =>
                  match parseList parseExpr s''' with
                  | .error msg state => .error msg state
                  | .ok values s'''' =>
                    match expect .RightParen s'''' with
                    | .error msg state => .error msg state
                    | .ok _ s''''' =>
                      .ok (.Insert tableName cols [values]) s'''''
        | _ =>
          -- No column list
          match expectKeyword .VALUES s''' with
          | .error msg state => .error msg state
          | .ok _ s'''' =>
            -- Parse value list
            match expect .LeftParen s'''' with
            | .error msg state => .error msg state
            | .ok _ s''''' =>
              match parseList parseExpr s''''' with
              | .error msg state => .error msg state
              | .ok values s'''''' =>
                match expect .RightParen s'''''' with
                | .error msg state => .error msg state
                | .ok _ s''''''' =>
                  .ok (.Insert tableName [] [values]) s'''''''

-- Parse DELETE statement
def parseDelete (s : ParserState) : ParserResult Statement :=
  match expectKeyword .DELETE s with
  | .error msg state => .error msg state
  | .ok _ s' =>
    match expectKeyword .FROM s' with
    | .error msg state => .error msg state
    | .ok _ s'' =>
      match parseIdentifier s'' with
      | .error msg state => .error msg state
      | .ok tableName s''' =>
        -- Parse optional WHERE clause. If WHERE present, expression is required.
        match s'''.peek with
        | some (.Keyword .WHERE) =>
          -- WHERE present: require a valid expression, propagate errors
          match parseExpr (s'''.advance) with
          | .ok expr s'''' => .ok (.Delete tableName (some expr)) s''''
          | .error msg state => .error msg state
        | _ =>
          -- No WHERE clause
          .ok (.Delete tableName none) s'''

-- Main parser entry point
def parseStatement (s : ParserState) : ParserResult Statement :=
  match s.peek with
  | some (.Keyword .SELECT) => parseSelect s
  | some (.Keyword .INSERT) => parseInsert s
  | some (.Keyword .DELETE) => parseDelete s
  | some t => .error s!"Unexpected token: {repr t}" s
  | none => .error "Unexpected EOF" s

-- Convenience function to parse from tokens
def parse (tokens : List Token) : ParserResult Statement :=
  parseStatement { tokens := tokens }

-- Convenience function to parse from string
def parseSQL (input : String) : String ⊕ Statement :=
  match tokenizeString input with
  | .error msg _ => .inl s!"Lexer error: {msg}"
  | .ok tokens _ =>
    match parse tokens with
    | .error msg _ => .inl s!"Parser error: {msg}"
    | .ok stmt _ => .inr stmt

end SQLinLean
