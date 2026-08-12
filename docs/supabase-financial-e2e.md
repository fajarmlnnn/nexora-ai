# Supabase Financial E2E

The frontend contains a live integration test at:

`apps/frontend/test/integration/supabase_financial_e2e_test.dart`

The test is skipped unless all four values are provided:

- `NEXORA_SUPABASE_URL`
- `NEXORA_SUPABASE_PUBLISHABLE_KEY`
- `NEXORA_E2E_EMAIL`
- `NEXORA_E2E_PASSWORD`

Run it from `apps/frontend`:

```bash
flutter test test/integration/supabase_financial_e2e_test.dart \
  --dart-define=NEXORA_SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=NEXORA_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY \
  --dart-define=NEXORA_E2E_EMAIL=YOUR_TEST_USER_EMAIL \
  --dart-define=NEXORA_E2E_PASSWORD=YOUR_TEST_USER_PASSWORD
```

Use a dedicated test account. Do not use a production account with real financial data.

The flow verifies:

1. authenticated access;
2. wallet creation starts at zero even when the client model contains a fake balance;
3. income increases the wallet balance;
4. expense decreases it;
5. transfer atomically moves funds between wallets;
6. deleting a transaction restores its previous balance effect;
7. updating a transfer reverses the old effect before applying the new amount;
8. idempotent retry does not double-apply the income;
9. cleanup removes the test transactions and wallets;
10. the test signs out at the end.

The live test intentionally is not enabled in the normal CI test command because CI does not need production Supabase credentials. Configure a dedicated CI secret/account later if continuous remote E2E coverage is required.
