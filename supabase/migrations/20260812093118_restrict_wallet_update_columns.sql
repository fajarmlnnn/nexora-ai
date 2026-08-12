revoke update on table public.wallets from authenticated;

grant update (
  name,
  bank_name,
  account_number,
  type,
  minimum_balance,
  currency_code,
  color,
  is_primary,
  is_hidden
) on table public.wallets to authenticated;
