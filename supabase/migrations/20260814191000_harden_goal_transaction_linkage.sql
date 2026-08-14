ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS goal_contribution_id uuid;

ALTER TABLE public.transactions
  DROP CONSTRAINT IF EXISTS transactions_goal_contribution_id_fkey;

ALTER TABLE public.transactions
  ADD CONSTRAINT transactions_goal_contribution_id_fkey
  FOREIGN KEY (goal_contribution_id)
  REFERENCES public.goal_contributions(id)
  ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS transactions_goal_contribution_id_idx
  ON public.transactions(goal_contribution_id)
  WHERE goal_contribution_id IS NOT NULL;

DROP POLICY IF EXISTS goal_contributions_insert_own ON public.goal_contributions;
DROP POLICY IF EXISTS goal_contributions_delete_own ON public.goal_contributions;

CREATE OR REPLACE FUNCTION public.enforce_goal_transaction_linkage()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.goal_contribution_id IS NOT NULL
     AND current_setting('nexora.goal_write_context', true) <> 'rpc' THEN
    RAISE EXCEPTION 'Goal contribution transaction linkage is server-controlled';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS transactions_goal_linkage_guard ON public.transactions;
CREATE TRIGGER transactions_goal_linkage_guard
BEFORE INSERT OR UPDATE OF goal_contribution_id ON public.transactions
FOR EACH ROW
EXECUTE FUNCTION public.enforce_goal_transaction_linkage();

CREATE OR REPLACE FUNCTION public.nexora_contribute_to_goal_from_wallet(
  p_goal_id uuid,
  p_wallet_id uuid,
  p_amount numeric,
  p_note text DEFAULT NULL,
  p_idempotency_key text DEFAULT NULL
)
RETURNS public.goals
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_goal public.goals;
  v_wallet public.wallets;
  v_existing public.goal_contributions;
  v_existing_tx public.transactions;
  v_contribution public.goal_contributions;
  v_new_saved numeric(19,2);
  v_status text;
  v_key text := nullif(trim(p_idempotency_key), '');
  v_transaction_key text;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_amount IS NULL OR p_amount <= 0 THEN RAISE EXCEPTION 'Contribution amount must be greater than zero'; END IF;
  IF p_wallet_id IS NULL THEN RAISE EXCEPTION 'Funding wallet is required'; END IF;
  IF v_key IS NOT NULL AND char_length(v_key) > 255 THEN RAISE EXCEPTION 'Idempotency key is too long'; END IF;

  IF v_key IS NOT NULL THEN
    SELECT * INTO v_existing
    FROM public.goal_contributions
    WHERE user_id = v_user AND idempotency_key = v_key
    LIMIT 1;

    IF FOUND THEN
      SELECT * INTO v_existing_tx
      FROM public.transactions
      WHERE user_id = v_user AND goal_contribution_id = v_existing.id
      LIMIT 1;

      IF NOT FOUND
         OR v_existing.goal_id <> p_goal_id
         OR v_existing.amount <> p_amount
         OR v_existing_tx.wallet_id <> p_wallet_id
         OR v_existing_tx.type <> 'expense' THEN
        RAISE EXCEPTION 'Idempotency key sudah digunakan untuk payload goal yang berbeda';
      END IF;

      SELECT * INTO v_goal
      FROM public.goals
      WHERE id = v_existing.goal_id AND user_id = v_user;
      IF NOT FOUND THEN RAISE EXCEPTION 'Goal not found'; END IF;
      RETURN v_goal;
    END IF;
  END IF;

  SELECT * INTO v_goal
  FROM public.goals
  WHERE id = p_goal_id AND user_id = v_user
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Goal not found'; END IF;
  IF v_goal.status = 'paused' THEN RAISE EXCEPTION 'Goal is paused'; END IF;

  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE id = p_wallet_id AND user_id = v_user
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Funding wallet not found'; END IF;
  IF v_wallet.balance - p_amount < v_wallet.minimum_balance THEN
    RAISE EXCEPTION 'Wallet balance cannot fall below minimum balance';
  END IF;

  v_new_saved := v_goal.saved_amount + p_amount;
  v_status := CASE WHEN v_new_saved >= v_goal.target_amount THEN 'completed' ELSE 'active' END;

  PERFORM set_config('nexora.goal_write_context', 'rpc', true);

  INSERT INTO public.goal_contributions(goal_id, user_id, amount, note, idempotency_key)
  VALUES(v_goal.id, v_user, p_amount, nullif(trim(p_note), ''), v_key)
  RETURNING * INTO v_contribution;

  v_transaction_key := CASE WHEN v_key IS NULL THEN NULL ELSE 'goal-contribution:' || v_key END;

  INSERT INTO public.transactions(
    user_id, wallet_id, type, amount, category, description, occurred_at,
    idempotency_key, metadata, goal_contribution_id
  )
  VALUES(
    v_user, v_wallet.id, 'expense', p_amount, 'other',
    'Setoran goal: ' || v_goal.name, now(), v_transaction_key,
    jsonb_build_object(
      'goal_id', v_goal.id,
      'goal_contribution_id', v_contribution.id,
      'kind', 'goal_contribution'
    ),
    v_contribution.id
  );

  UPDATE public.goals
  SET saved_amount = v_new_saved, status = v_status, updated_at = now()
  WHERE id = v_goal.id AND user_id = v_user
  RETURNING * INTO v_goal;

  RETURN v_goal;
END;
$$;

CREATE OR REPLACE FUNCTION public.nexora_delete_goal(p_goal_id uuid)
RETURNS public.goals
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_goal public.goals;
  v_has_unlinked_contribution boolean;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

  SELECT * INTO v_goal
  FROM public.goals
  WHERE id = p_goal_id AND user_id = v_user
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Goal not found'; END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.goal_contributions gc
    WHERE gc.goal_id = v_goal.id
      AND NOT EXISTS (
        SELECT 1 FROM public.transactions t
        WHERE t.user_id = v_user AND t.goal_contribution_id = gc.id
      )
  ) INTO v_has_unlinked_contribution;

  IF v_has_unlinked_contribution THEN
    RAISE EXCEPTION 'Goal has an unlinked contribution; deletion was blocked to protect wallet history';
  END IF;

  PERFORM set_config('nexora.goal_write_context', 'rpc', true);

  DELETE FROM public.transactions t
  USING public.goal_contributions gc
  WHERE gc.goal_id = v_goal.id
    AND t.user_id = v_user
    AND t.goal_contribution_id = gc.id;

  DELETE FROM public.goals WHERE id = v_goal.id AND user_id = v_user;
  RETURN v_goal;
END;
$$;

CREATE OR REPLACE FUNCTION public.nexora_update_goal_target(p_goal_id uuid, p_target_amount numeric)
RETURNS public.goals
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_goal public.goals;
  v_user uuid := auth.uid();
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_target_amount IS NULL OR p_target_amount <= 0 THEN RAISE EXCEPTION 'Target amount must be greater than zero'; END IF;

  UPDATE public.goals
  SET target_amount = p_target_amount,
      status = CASE WHEN saved_amount >= p_target_amount THEN 'completed' ELSE 'active' END,
      updated_at = now()
  WHERE id = p_goal_id AND user_id = v_user
  RETURNING * INTO v_goal;

  IF NOT FOUND THEN RAISE EXCEPTION 'Goal not found'; END IF;
  RETURN v_goal;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.nexora_contribute_to_goal(uuid, numeric, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.nexora_contribute_to_goal_from_wallet(uuid, uuid, numeric, text, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.nexora_delete_goal(uuid) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.nexora_update_goal_target(uuid, numeric) FROM anon, public;

GRANT EXECUTE ON FUNCTION public.nexora_contribute_to_goal_from_wallet(uuid, uuid, numeric, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nexora_delete_goal(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nexora_update_goal_target(uuid, numeric) TO authenticated;
