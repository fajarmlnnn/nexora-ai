create or replace function public.prevent_direct_wallet_balance_insert()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if new.balance <> 0 then
    raise exception 'Wallet balance must start at zero; create an income transaction for opening funds';
  end if;
  return new;
end;
$$;

revoke all on function public.prevent_direct_wallet_balance_insert() from public, anon, authenticated;

drop trigger if exists wallets_balance_insert_guard on public.wallets;
create trigger wallets_balance_insert_guard
before insert on public.wallets
for each row execute function public.prevent_direct_wallet_balance_insert();
