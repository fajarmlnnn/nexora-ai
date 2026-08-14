create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  type text not null check (type in ('saving','wishlist','debt')),
  target_amount numeric(19,2) not null check (target_amount > 0),
  saved_amount numeric(19,2) not null default 0 check (saved_amount >= 0),
  deadline date,
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  status text not null default 'active' check (status in ('active','paused','completed')),
  category text,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists goals_user_id_idx on public.goals(user_id);
create index if not exists goals_user_status_idx on public.goals(user_id, status);

create table if not exists public.goal_contributions (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.goals(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  amount numeric(19,2) not null check (amount > 0),
  note text,
  contributed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists goal_contributions_goal_idx on public.goal_contributions(goal_id, contributed_at desc);
create index if not exists goal_contributions_user_idx on public.goal_contributions(user_id, contributed_at desc);

alter table public.goals enable row level security;
alter table public.goal_contributions enable row level security;

create policy goals_select_own on public.goals for select using (user_id = auth.uid());
create policy goals_insert_own on public.goals for insert with check (user_id = auth.uid());
create policy goals_update_own on public.goals for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy goals_delete_own on public.goals for delete using (user_id = auth.uid());
create policy goal_contributions_select_own on public.goal_contributions for select using (user_id = auth.uid());

create or replace function public.enforce_goal_write_boundaries()
returns trigger language plpgsql security definer set search_path = pg_catalog, public as $$
declare trusted boolean := current_setting('nexora.goal_write_context', true) = 'rpc';
begin
  if tg_op = 'INSERT' and new.saved_amount <> 0 and not trusted then raise exception 'Goal saved amount must start at zero; use goal contribution'; end if;
  if tg_op = 'UPDATE' and new.saved_amount <> old.saved_amount and not trusted then raise exception 'Goal saved amount is server-controlled; use goal contribution'; end if;
  if new.target_amount < new.saved_amount then raise exception 'Goal target cannot be below saved amount'; end if;
  return new;
end; $$;
create trigger goals_write_boundaries before insert or update on public.goals for each row execute function public.enforce_goal_write_boundaries();

create or replace function public.set_goals_updated_at()
returns trigger language plpgsql set search_path = pg_catalog, public as $$ begin new.updated_at = now(); return new; end; $$;
create trigger goals_updated_at before update on public.goals for each row execute function public.set_goals_updated_at();

revoke insert, update, delete on public.goal_contributions from authenticated;
grant select on public.goal_contributions to authenticated;
revoke update (saved_amount) on public.goals from authenticated;

create or replace function public.nexora_contribute_to_goal(p_goal_id uuid, p_amount numeric, p_note text default null)
returns public.goals language plpgsql security definer set search_path = pg_catalog, public as $$
declare v_goal public.goals; v_user uuid := auth.uid(); v_new_saved numeric(19,2); v_status text;
begin
  if v_user is null then raise exception 'Not authenticated'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'Contribution amount must be greater than zero'; end if;
  select * into v_goal from public.goals where id = p_goal_id and user_id = v_user for update;
  if not found then raise exception 'Goal not found'; end if;
  if v_goal.status = 'paused' then raise exception 'Goal is paused'; end if;
  v_new_saved := v_goal.saved_amount + p_amount;
  v_status := case when v_new_saved >= v_goal.target_amount then 'completed' else 'active' end;
  perform set_config('nexora.goal_write_context', 'rpc', true);
  insert into public.goal_contributions(goal_id, user_id, amount, note) values (v_goal.id, v_user, p_amount, nullif(trim(p_note), ''));
  update public.goals set saved_amount = v_new_saved, status = v_status, updated_at = now() where id = v_goal.id and user_id = v_user returning * into v_goal;
  return v_goal;
end; $$;
revoke all on function public.nexora_contribute_to_goal(uuid,numeric,text) from public;
grant execute on function public.nexora_contribute_to_goal(uuid,numeric,text) to authenticated;

create or replace function public.nexora_update_goal_target(p_goal_id uuid, p_target_amount numeric)
returns public.goals language plpgsql security definer set search_path = pg_catalog, public as $$
declare v_goal public.goals; v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Not authenticated'; end if;
  if p_target_amount is null or p_target_amount <= 0 then raise exception 'Target amount must be greater than zero'; end if;
  perform set_config('nexora.goal_write_context', 'rpc', true);
  update public.goals set target_amount = p_target_amount, status = case when saved_amount >= p_target_amount then 'completed' else 'active' end, updated_at = now() where id = p_goal_id and user_id = v_user returning * into v_goal;
  if not found then raise exception 'Goal not found'; end if;
  return v_goal;
end; $$;
revoke all on function public.nexora_update_goal_target(uuid,numeric) from public;
grant execute on function public.nexora_update_goal_target(uuid,numeric) to authenticated;
