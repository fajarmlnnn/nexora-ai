-- Budget category contract:
-- 1. Every budget has an explicit supported expense category.
-- 2. Budget identity is independent from category.
-- 3. One user cannot have duplicate monthly budgets for the same category.
-- 4. Changing a budget id must never change the category used for spending.
-- 5. Spending is derived from transactions, not a persisted budget.spent field.

-- The production migration enforces #1 and #3. Flutter unit/E2E tests enforce
-- #2, #4 and #5 without inserting destructive fixture data into production.
