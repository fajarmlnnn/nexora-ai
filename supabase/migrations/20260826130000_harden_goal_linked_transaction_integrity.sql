-- Harden the financial state machine around goal-funded transactions.
-- A goal contribution owns both a goal ledger entry and a wallet transaction.
-- The generic transaction RPCs must not be able to mutate/delete that linked
-- transaction independently, otherwise wallet history can diverge from
-- goals.saved_amount.

CREATE OR REPLACE FUNCTION public.enforce_goal_transaction_linkage()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.goal_contribution_id IS NOT NULL
       AND COALESCE(current_setting('nexora.goal_write_context', true), '') <> 'rpc' THEN
      RAISE EXCEPTION 'Goal contribution transaction linkage is server-controlled';
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    IF (OLD.goal_contribution_id IS NOT NULL OR NEW.goal_contribution_id IS NOT NULL)
       AND COALESCE(current_setting('nexora.goal_write_context', true), '') <> 'rpc' THEN
      RAISE EXCEPTION 'Goal contribution transactions must be changed through the goal workflow';
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    IF OLD.goal_contribution_id IS NOT NULL
       AND COALESCE(current_setting('nexora.goal_write_context', true), '') <> 'rpc' THEN
      RAISE EXCEPTION 'Goal contribution transactions must be removed through the goal workflow';
    END IF;
    RETURN OLD;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS transactions_goal_linkage_guard ON public.transactions;
CREATE TRIGGER transactions_goal_linkage_guard
BEFORE INSERT OR UPDATE OR DELETE ON public.transactions
FOR EACH ROW
EXECUTE FUNCTION public.enforce_goal_transaction_linkage();

-- A generic transaction update/delete reverses the old transfer through the
-- wallet-balance trigger. Do not allow that reversal to push the destination
-- wallet below its configured minimum balance.
CREATE OR REPLACE FUNCTION public.guard_transfer_reversal_minimum_balance()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_balance numeric(19,2);
  v_minimum numeric(19,2);
BEGIN
  IF TG_OP IN ('UPDATE', 'DELETE') AND OLD.type = 'transfer' THEN
    SELECT balance, minimum_balance
      INTO v_balance, v_minimum
      FROM public.wallets
     WHERE id = OLD.destination_wallet_id
     FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Destination wallet is invalid for transfer reversal';
    END IF;

    IF v_balance - OLD.amount < v_minimum THEN
      RAISE EXCEPTION 'Transfer reversal would breach the destination wallet minimum balance';
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS transactions_transfer_reversal_guard ON public.transactions;
CREATE TRIGGER transactions_transfer_reversal_guard
BEFORE UPDATE OR DELETE ON public.transactions
FOR EACH ROW
EXECUTE FUNCTION public.guard_transfer_reversal_minimum_balance();

-- Generic transaction RPCs are intentionally unable to mutate a goal-linked
-- transaction. Goal deletion sets nexora.goal_write_context='rpc' and remains
-- the only workflow allowed to remove the linked contribution + transaction
-- together.
CREATE OR REPLACE FUNCTION public.nexora_update_transaction(
  p_transaction_id uuid,
  p_type text,
  p_amount numeric,
  p_category text DEFAULT 'other',
  p_description text DEFAULT NULL,
  p_occurred_at timestamptz DEFAULT now(),
  p_metadata jsonb DEFAULT '{}'::jsonb,
  p_wallet_id uuid DEFAULT NULL,
  p_source_wallet_id uuid DEFAULT NULL,
  p_destination_wallet_id uuid DEFAULT NULL
)
RETURNS SETOF public.transactions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_row public.transactions;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Transaction amount must be greater than zero';
  END IF;

  SELECT *
    INTO v_row
    FROM public.transactions
   WHERE id = p_transaction_id
     AND user_id = v_user_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;

  IF v_row.goal_contribution_id IS NOT NULL THEN
    RAISE EXCEPTION 'Goal contribution transactions must be changed through the goal workflow';
  END IF;

  UPDATE public.transactions
     SET type = p_type,
         amount = p_amount,
         category = coalesce(p_category, 'other'),
         description = p_description,
         occurred_at = coalesce(p_occurred_at, now()),
         metadata = coalesce(p_metadata, '{}'::jsonb),
         wallet_id = p_wallet_id,
         source_wallet_id = p_source_wallet_id,
         destination_wallet_id = p_destination_wallet_id
   WHERE id = p_transaction_id
     AND user_id = v_user_id
  RETURNING * INTO v_row;

  RETURN NEXT v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.nexora_delete_transaction(
  p_transaction_id uuid
)
RETURNS SETOF public.transactions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_row public.transactions;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT *
    INTO v_row
    FROM public.transactions
   WHERE id = p_transaction_id
     AND user_id = v_user_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;

  IF v_row.goal_contribution_id IS NOT NULL THEN
    RAISE EXCEPTION 'Goal contribution transactions must be removed through the goal workflow';
  END IF;

  DELETE FROM public.transactions
   WHERE id = p_transaction_id
     AND user_id = v_user_id
  RETURNING * INTO v_row;

  RETURN NEXT v_row;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.nexora_update_transaction(uuid,text,numeric,text,text,timestamptz,jsonb,uuid,uuid,uuid) FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.nexora_delete_transaction(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.nexora_update_transaction(uuid,text,numeric,text,text,timestamptz,jsonb,uuid,uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nexora_delete_transaction(uuid) TO authenticated;

-- Keep goal deletion as the trusted atomic workflow. The LOCAL context is
-- visible to triggers fired by this transaction only and is reset at commit.
CREATE OR REPLACE FUNCTION public.nexora_delete_goal(p_goal_id uuid)
RETURNS public.goals
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_goal public.goals;
  v_has_unlinked_contribution boolean;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_goal
  FROM public.goals
  WHERE id = p_goal_id
    AND user_id = v_user
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Goal not found';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.goal_contributions gc
    WHERE gc.goal_id = v_goal.id
      AND NOT EXISTS (
        SELECT 1
        FROM public.transactions t
        WHERE t.user_id = v_user
          AND t.metadata ->> 'goal_contribution_id' = gc.id::text
      )
  ) INTO v_has_unlinked_contribution;

  IF v_has_unlinked_contribution THEN
    RAISE EXCEPTION 'Goal has an unlinked contribution; deletion was blocked to protect wallet history';
  END IF;

  PERFORM set_config('nexora.goal_write_context', 'rpc', true);

  DELETE FROM public.transactions t
  WHERE t.user_id = v_user
    AND t.metadata ->> 'goal_id' = v_goal.id::text
    AND t.metadata ->> 'kind' IN ('goal_contribution', 'goal_contribution_reconciliation');

  DELETE FROM public.goals
  WHERE id = v_goal.id
    AND user_id = v_user;

  RETURN v_goal;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.nexora_delete_goal(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.nexora_delete_goal(uuid) TO authenticated;

COMMENT ON FUNCTION public.enforce_goal_transaction_linkage() IS
'Prevents generic transaction APIs from mutating or deleting goal-linked ledger entries outside the atomic goal workflow.';

COMMENT ON FUNCTION public.guard_transfer_reversal_minimum_balance() IS
'Prevents transaction update/delete reversal from reducing a transfer destination wallet below its configured minimum balance.';
