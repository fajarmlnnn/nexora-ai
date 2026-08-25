# Production data safety

Nexora production data is never used as a test fixture.

## Prohibited

- inserting dummy users, wallets, transactions, goals, budgets, or contributions into production;
- running seeders against the production Supabase project;
- creating synthetic financial history to validate UI flows;
- leaving test rows behind after security verification;
- using production financial records as mutable test subjects.

## Allowed verification methods

- schema, RLS, grant, and function-definition inspection;
- authenticated permission tests that do not mutate data;
- isolated Supabase development/test projects;
- transaction-scoped tests that are guaranteed to roll back;
- static analysis and dependency/security scans;
- read-only reconciliation and consistency checks.

Any required end-to-end mutation test must run outside the production project.
