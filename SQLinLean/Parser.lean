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

-- Expression parsing with mutual recursion and proper precedence
mutual
  -- Parse a primary expression (literals, identifiers, parenthesized expressions)
  partial def parsePrimary (s : ParserState) : ParserResult Expr :=
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

  -- Parse comparison expressions: =, <>, <, >, <=, >=
  partial def parseComparison (s : ParserState) : ParserResult Expr :=
    match parseAdditive s with
    | ParserResult.error msg state => ParserResult.error msg state
    | ParserResult.ok left s' =>
      match s'.peek with
      | some (.Operator op) =>
        match op with
        | .Equals | .NotEquals | .LessThan | .GreaterThan | .LessOrEqual | .GreaterOrEqual =>
          let s'' := s'.advance
          match parseAdditive s'' with
          | ParserResult.error msg state => ParserResult.error msg state
          | ParserResult.ok right s''' => ParserResult.ok (.BinaryOp left op right) s'''
        | _ => ParserResult.ok left s'
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

-- Parse SELECT statement
def parseSelect (s : ParserState) : ParserResult Statement :=
  match expectKeyword .SELECT s with
  | .error msg state => .error msg state
  | .ok _ s' =>
    match parseList parseSelectItem s' with
    | .error msg state => .error msg state
    | .ok columns s'' =>
      -- Parse optional FROM clause. If FROM is present, a table name is required.
      match s''.peek with
      | some (.Keyword .FROM) =>
        match parseIdentifier (s''.advance) with
        | .error msg state =>
          -- Propagate error: FROM was present but table name could not be parsed
          .error msg state
        | .ok tableName sAfterTable =>
          -- Parse optional table alias (AS alias or just alias)
          -- Note: Keywords like WHERE are tokenized as Token.Keyword, not Token.Identifier,
          -- so the Identifier pattern below won't match them
          let (tableAlias, sAfterAlias) := match sAfterTable.peek with
            | some (.Keyword .AS) =>
              match parseIdentifier (sAfterTable.advance) with
              | .ok alias st => (some alias, st)
              | .error _ _ => (none, sAfterTable)
            | some (.Identifier alias) =>
              (some alias, sAfterTable.advance)
            | _ => (none, sAfterTable)
          let fromTable := some (TableRef.Table tableName tableAlias)
          -- Parse optional WHERE clause. If WHERE is present, an expression is required.
          match sAfterAlias.peek with
          | some (.Keyword .WHERE) =>
            match parseExpr (sAfterAlias.advance) with
            | .error msg state =>
              -- Propagate error: WHERE was present but expression could not be parsed
              .error msg state
            | .ok expr sAfterWhere =>
              let whereClause := some expr
              .ok (.Select columns fromTable whereClause [] none none) sAfterWhere
          | _ =>
            let whereClause := (none : Option _)
            .ok (.Select columns fromTable whereClause [] none none) sAfterAlias
      | _ =>
        let fromTable := (none : Option TableRef)
        -- Parse optional WHERE clause when there is no FROM
        match s''.peek with
        | some (.Keyword .WHERE) =>
          match parseExpr (s''.advance) with
          | .error msg state =>
            -- Propagate error: WHERE was present but expression could not be parsed
            .error msg state
          | .ok expr s''' =>
            let whereClause := some expr
            .ok (.Select columns fromTable whereClause [] none none) s'''
        | _ =>
          let whereClause := (none : Option _)
          .ok (.Select columns fromTable whereClause [] none none) s''

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
