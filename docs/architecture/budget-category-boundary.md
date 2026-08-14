# Budget category boundary

A budget has two distinct concepts:

- `id`: stable identity of the budget row.
- `category`: the transaction category whose expense total is tracked.

The dashboard MUST calculate budget spending from `budget.category`, never from `budget.id` or display name.

The database stores `category` explicitly and enforces the supported expense-category set. The current product model exposes one monthly budget per category, so `(user_id, category)` is unique.

Legacy rows are backfilled from the old category-keyed id/name convention during migration. After migration, changing a budget id or name must not change which transactions are counted as spending.
