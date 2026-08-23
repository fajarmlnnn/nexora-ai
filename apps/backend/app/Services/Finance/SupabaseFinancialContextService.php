<?php

namespace App\Services\Finance;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SupabaseFinancialContextService
{
    private const PAGE_SIZE = 500;
    private const MAX_ROWS = 5000;

    /**
     * Build AI context only from the authenticated user's live Supabase ledger.
     * If the ledger cannot be read completely, return an empty context rather
     * than giving the model a partial financial picture.
     *
     * @return array<string, mixed>
     */
    public function forUser(string $userId, string $accessToken): array
    {
        $baseUrl = rtrim((string) config('services.supabase.url'), '/');
        $publishableKey = trim((string) config('services.supabase.publishable_key'));

        if ($userId === '' || $accessToken === '' || $baseUrl === '' || $publishableKey === '') {
            return [];
        }

        $from = now()->startOfMonth()->toIso8601String();
        $to = now()->endOfMonth()->toIso8601String();
        $rows = [];

        try {
            for ($offset = 0; $offset < self::MAX_ROWS; $offset += self::PAGE_SIZE) {
                $response = Http::acceptJson()
                    ->withHeaders([
                        'apikey' => $publishableKey,
                        'Authorization' => 'Bearer '.$accessToken,
                        'Prefer' => 'count=exact',
                    ])
                    ->connectTimeout(3)
                    ->timeout(5)
                    ->get($baseUrl.'/rest/v1/transactions', [
                        'select' => 'type,amount,category,occurred_at',
                        'user_id' => 'eq.'.$userId,
                        'occurred_at' => 'gte.'.$from,
                        'occurred_at' => 'lte.'.$to,
                        'order' => 'occurred_at.desc',
                        'limit' => self::PAGE_SIZE,
                        'offset' => $offset,
                    ]);

                if (! $response->successful()) {
                    Log::warning('Supabase financial context query rejected.', [
                        'status' => $response->status(),
                    ]);
                    return [];
                }

                $page = $response->json();
                if (! is_array($page)) {
                    return [];
                }

                foreach ($page as $row) {
                    if (! is_array($row)) {
                        return [];
                    }
                    $rows[] = $row;
                }

                if (count($page) < self::PAGE_SIZE) {
                    return $this->aggregate($rows);
                }
            }
        } catch (ConnectionException $e) {
            Log::warning('Supabase financial context connection failed.', [
                'exception' => $e::class,
            ]);
        } catch (\Throwable $e) {
            Log::warning('Supabase financial context failed.', [
                'exception' => $e::class,
            ]);
        }

        // Never expose a silently truncated ledger to the model.
        return [];
    }

    /** @param array<int, mixed> $rows */
    private function aggregate(array $rows): array
    {
        $income = 0.0;
        $expense = 0.0;
        $expenseByCategory = [];

        foreach ($rows as $row) {
            $type = $row['type'] ?? null;
            $amount = $row['amount'] ?? null;

            if (! is_string($type) || (! is_int($amount) && ! is_float($amount) && ! is_string($amount))) {
                return [];
            }

            $value = is_numeric($amount) ? (float) $amount : null;
            if ($value === null || ! is_finite($value) || $value < 0) {
                return [];
            }

            if ($type === 'income') {
                $income += $value;
            } elseif ($type === 'expense') {
                $expense += $value;
                $category = is_string($row['category'] ?? null) && trim($row['category']) !== ''
                    ? trim($row['category'])
                    : null;
                if ($category !== null) {
                    $expenseByCategory[$category] = ($expenseByCategory[$category] ?? 0.0) + $value;
                }
            } elseif ($type !== 'transfer') {
                return [];
            }
        }

        arsort($expenseByCategory, SORT_NUMERIC);
        $topExpenseCategory = array_key_first($expenseByCategory);
        $netCashflow = $income - $expense;
        $savingsRate = $income > 0 ? round(($netCashflow / $income) * 100, 1) : null;

        return [
            'period' => now()->format('Y-m'),
            'income' => round($income, 2),
            'expense' => round($expense, 2),
            'net_cashflow' => round($netCashflow, 2),
            'savings_rate' => $savingsRate,
            'top_expense_category' => $topExpenseCategory,
            'top_expense_value' => $topExpenseCategory === null
                ? null
                : round((float) $expenseByCategory[$topExpenseCategory], 2),
            'source' => 'supabase_ledger',
        ];
    }
}
