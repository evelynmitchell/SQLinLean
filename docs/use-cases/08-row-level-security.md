# Use Case: Row-Level Security (RLS) Verification

## Overview

Define security policies in Lean and prove that queries cannot return data violating those policies, regardless of database content.

## Problem Statement

Row-Level Security policies are complex predicates. It's easy to accidentally expose data through:
- Overly permissive WHERE clauses
- JOINs that bypass RLS
- Subqueries that leak information
- Aggregations that reveal protected data

## How Lean4 Helps

- Formally define security policies as predicates
- Prove queries cannot violate policies
- Catch policy bypasses at compile time
- Verify policy composition

## Research & References

- PostgreSQL RLS documentation
- Information flow control
- Security type systems
- Mandatory access control models

## Implementation Ideas

### Policy Definition
```lean
-- A policy is a predicate on rows
structure Policy where
  name : String
  predicate : Row → Bool

-- Example: Users can only see their own data
def userOnlyOwn (currentUserId : Nat) : Policy := {
  name := "user_owns_row",
  predicate := fun row => row.get "user_id" == some currentUserId
}

-- Example: Admins see everything
def adminSeeAll : Policy := {
  name := "admin_all",
  predicate := fun _ => true
}
```

### Query Verification
```lean
-- Prove a query respects a policy
theorem query_respects_policy
  (q : Query)
  (p : Policy)
  (db : Database) :
  ∀ row ∈ (execute q db), p.predicate row := by ...

-- Example: Verify this query is safe
def safeQuery : Query :=
  sql! "SELECT * FROM orders WHERE user_id = $currentUserId"

example : query_respects_policy safeQuery (userOnlyOwn uid) db := by
  -- Proof that WHERE clause enforces policy
  ...
```

### Policy Bypass Detection
```lean
-- Detect if a JOIN could bypass RLS
def joinBypassesRLS (q : Query) (protectedTable : String) : Bool :=
  -- Check if JOIN exposes rows from protectedTable
  -- without applying its RLS policy
  ...

-- Detect if aggregation leaks information
def aggregationLeaks (q : Query) (p : Policy) : Bool :=
  -- COUNT, SUM, etc. on protected data without grouping by policy key
  ...
```

## Key Scenarios

### Direct Access
- [ ] SELECT respects policy predicate
- [ ] UPDATE/DELETE only affects permitted rows
- [ ] INSERT validates against policy

### Indirect Access
- [ ] JOINs don't expose protected data
- [ ] Subqueries don't leak information
- [ ] Views maintain RLS guarantees

### Aggregation Safety
- [ ] COUNT doesn't reveal existence of protected rows
- [ ] SUM/AVG don't leak values
- [ ] GROUP BY respects policy boundaries

## Policy Patterns

### Common Policies
- **Ownership**: `user_id = current_user`
- **Role-based**: `role IN (user_roles)`
- **Tenant isolation**: `tenant_id = current_tenant`
- **Time-based**: `created_at > subscription_start`

### Policy Composition
```lean
-- Combine policies with AND/OR
def combinePolicies (p1 p2 : Policy) (op : Bool → Bool → Bool) : Policy := {
  name := s!"{p1.name} {op} {p2.name}",
  predicate := fun row => op (p1.predicate row) (p2.predicate row)
}
```

## Open Questions

- How to handle dynamic policies (runtime user context)?
- Verifying policies across multiple tables?
- Performance impact of policy checking?
- Handling SECURITY DEFINER functions?

## Notes & Ideas

<!-- Add your thoughts, discoveries, and explorations here -->

