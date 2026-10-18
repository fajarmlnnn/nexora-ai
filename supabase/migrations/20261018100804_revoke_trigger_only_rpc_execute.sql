-- Trigger-only safety guard. It protects minimum-balance invariants when a
-- transfer transaction is updated or deleted; clients should not invoke it as
-- an RPC. Trigger execution remains attached to transactions and does not
-- require exposing the trigger function through the Data API.
revoke execute on function public.guard_transfer_reversal_minimum_balance()
  from public, anon, authenticated;
