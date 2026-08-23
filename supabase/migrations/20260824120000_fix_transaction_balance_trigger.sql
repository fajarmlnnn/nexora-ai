-- Fix transaction balance mutations to validate the final wallet state.
-- UPDATEs must apply the net old->new delta atomically; reversing the old
-- transaction first can incorrectly reject a valid update at minimum_balance.
-- Transfer DELETEs also validate the destination minimum before reversing it.
create or replace function public.apply_transaction_to_wallets()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  effect record;
  wallet record;
  new_delta numeric(19,2);
begin
  if tg_op = 'INSERT' then
    if new.type in ('income', 'expense') then
      select w.id, w.user_id, w.balance, w.minimum_balance
        into effect
      from public.wallets w
      where w.id = new.wallet_id
      for update;

      if effect.id is null or effect.user_id <> new.user_id then
        raise exception 'Wallet is invalid for transaction';
      end if;

      new_delta := case when new.type = 'income' then new.amount else -new.amount end;
      if effect.balance + new_delta < effect.minimum_balance then
        raise exception 'Wallet balance cannot fall below minimum balance';
      end if;

      update public.wallets
      set balance = balance + new_delta, updated_at = now()
      where id = new.wallet_id;
    else
      perform 1
      from public.wallets
      where id in (new.source_wallet_id, new.destination_wallet_id)
      order by id
      for update;

      select w.id, w.user_id, w.balance, w.minimum_balance
        into effect
      from public.wallets w
      where w.id = new.source_wallet_id;
      if effect.id is null or effect.user_id <> new.user_id then
        raise exception 'Source wallet is invalid for transfer';
      end if;
      if effect.balance - new.amount < effect.minimum_balance then
        raise exception 'Source wallet balance cannot fall below minimum balance';
      end if;

      select w.id, w.user_id
        into effect
      from public.wallets w
      where w.id = new.destination_wallet_id;
      if effect.id is null or effect.user_id <> new.user_id then
        raise exception 'Destination wallet is invalid for transfer';
      end if;

      update public.wallets
      set balance = balance - new.amount, updated_at = now()
      where id = new.source_wallet_id;

      update public.wallets
      set balance = balance + new.amount, updated_at = now()
      where id = new.destination_wallet_id;
    end if;

    return new;
  end if;

  if tg_op = 'DELETE' then
    if old.type in ('income', 'expense') then
      select w.id, w.user_id, w.balance, w.minimum_balance
        into effect
      from public.wallets w
      where w.id = old.wallet_id
      for update;

      if effect.id is null or effect.user_id <> old.user_id then
        raise exception 'Source wallet is invalid for transaction';
      end if;

      new_delta := case when old.type = 'income' then -old.amount else old.amount end;
      if effect.balance + new_delta < effect.minimum_balance then
        raise exception 'Wallet balance cannot fall below minimum balance';
      end if;

      update public.wallets
      set balance = balance + new_delta, updated_at = now()
      where id = old.wallet_id;
    else
      perform 1
      from public.wallets
      where id in (old.source_wallet_id, old.destination_wallet_id)
      order by id
      for update;

      select w.id, w.user_id, w.balance, w.minimum_balance
        into effect
      from public.wallets w
      where w.id = old.destination_wallet_id;
      if effect.id is null or effect.user_id <> old.user_id then
        raise exception 'Destination wallet is invalid for transfer';
      end if;
      if effect.balance - old.amount < effect.minimum_balance then
        raise exception 'Destination wallet balance cannot fall below minimum balance';
      end if;

      select w.id, w.user_id
        into effect
      from public.wallets w
      where w.id = old.source_wallet_id;
      if effect.id is null or effect.user_id <> old.user_id then
        raise exception 'Source wallet is invalid for transfer';
      end if;

      update public.wallets
      set balance = balance + old.amount, updated_at = now()
      where id = old.source_wallet_id;

      update public.wallets
      set balance = balance - old.amount, updated_at = now()
      where id = old.destination_wallet_id;
    end if;

    return old;
  end if;

  for effect in
    with effects(wallet_id, delta) as (
      select old.wallet_id,
             case when old.type = 'income' then -old.amount else old.amount end
      where old.type in ('income', 'expense')
      union all
      select old.source_wallet_id, old.amount
      where old.type = 'transfer'
      union all
      select old.destination_wallet_id, -old.amount
      where old.type = 'transfer'
      union all
      select new.wallet_id,
             case when new.type = 'income' then new.amount else -new.amount end
      where new.type in ('income', 'expense')
      union all
      select new.source_wallet_id, -new.amount
      where new.type = 'transfer'
      union all
      select new.destination_wallet_id, new.amount
      where new.type = 'transfer'
    )
    select wallet_id, sum(delta)::numeric(19,2) as delta
    from effects
    where wallet_id is not null
    group by wallet_id
    having sum(delta) <> 0
    order by wallet_id
  loop
    select w.id, w.user_id, w.balance, w.minimum_balance
      into wallet
    from public.wallets w
    where w.id = effect.wallet_id
    for update;

    if wallet.id is null or wallet.user_id <> new.user_id then
      raise exception 'Wallet is invalid for transaction update';
    end if;

    if wallet.balance + effect.delta < wallet.minimum_balance then
      raise exception 'Wallet balance cannot fall below minimum balance';
    end if;

    update public.wallets
    set balance = balance + effect.delta, updated_at = now()
    where id = effect.wallet_id;
  end loop;

  return new;
end;
$$;

revoke execute on function public.apply_transaction_to_wallets() from public, anon, authenticated;
