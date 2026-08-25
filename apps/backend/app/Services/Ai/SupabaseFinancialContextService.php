<?php

namespace App\Services\Ai;

use Carbon\CarbonImmutable;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class SupabaseFinancialContextService
{
    private const MAX_TRANSACTIONS = 1000;

    /**
     * Build authoritative financial context from Supabase using the caller's
     * JWT. RLS therefore remains the final ownership boundary; this service
     * never accepts client-provided monetary aggregates.
     *
     * @return array<string, mixed>
     */
    public function build(string $accessToken, string $periodStart, string $periodEnd, ?string $timezone = null): array
    {
        $baseUrl = rtrim((string) config('services.supabase.url'), '/');
        $publishableKey = (string) config('services.supabase.publishable_key');
        $timezone = $timezone ?: 'Asia/Jakarta';

        if ($baseUrl === '' || $publishableKey === '') {
            throw new RuntimeException('Supabase financial context is not configured.');
        }

        try {
            $start = CarbonImmutable::createFromFormat('!Y-m-d', $periodStart, $timezone)->startOfDay();
            $end = CarbonImmutable::createFromFormat('!Y-m-d', $periodEnd, $timezone)->endOfDay();
        } catch (\Throwable $e) {
            throw new RuntimeException('Invalid financial context date range.', previous: $e);
        }

        if ($start->greaterThan($end)) {
            throw new RuntimeException('Financial context period is invalid.');
        }

        $response = Http::acceptJson()
            ->withHeaders([
                'apikey' => $publishableKey,
                'Authorization' => 'Bearer '.$accessToken,
            ])
            ->connectTimeout(3)
            ->timeout(8)
            ->get($baseUrl.'/rest/v1/transactions', [
                'select' => 'type,amount,category,occurred_at',
                'occurred_at' => 'gte.'.$start->utc()->toIso8601String(),
                'order' => 'occurred_at.asc',
                'limit' => self::MAX_TRANSACTIONS,
            ]);

        if (! $response->successful()) {
            throw new RuntimeException('Unable to read authoritative financial context from Supabase.');
        }

        $rows = $response->json();
        if (! is_array($rows)) {
            throw new RuntimeException('Supabase returned an invalid financial context payload.');
        }

        $income = 0.0;
        $expense = 0.0;
        $expenseByCategory = [];
        $transactionCount = 0;

        foreach ($rows as $row) {
            if (! is_array($row)) {
                continue;
            }

            $occurredAt = $row['occurred_at'] ?? null;
            if (! is_string($occurredAt)) {
                continue;
            }

            try {
                $occurred = CarbonImmutable::parse($occurredAt);
            } catch (\Throwable) {
                continue;
            }

            if ($occurred->greaterThan($end->utc())) {
                continue;
            }

            $amount = is_numeric($row['amount'] ?? null) ? (float) $row['amount'] : 0.0;
            if ($amount <= 0) {
                continue;
            }

            $type = $row['type'] ?? null;
            $transactionCount++;

            if ($type === 'income') {
                $income += $amount;
                continue;
            }

            if ($type === 'expense') {
                $expense += $amount;
                $category = is_string($row['category'] ?? null) && trim($row['category']) !== ''
                    ? trim($row['category'])
                    : 'other';
                $expenseByCategory[$category] = ($expenseByCategory[$category] ?? 0.0) + $amount;
            }
        }

        arsort($expenseByCategory, SORT_NUMERIC);
        $topCategory = array_key_first($expenseByCategory);
        $netCashflow = $income - $expense;
        $savingsRate = $income > 0 ? ($netCashflow / $income) * 100 : 0.0;

        return [
            'income' => round($income, 2),
            'expense' => round($expense, 2),
            'net_cashflow' => round($netCashflow, 2),
            'savings_rate' => round($savingsRate, 2),
            'top_expense_category' => $topCategory,
            'top_expense_value' => $topCategory !== null ? round($expenseByCategory[$topCategory], 2) : 0.0,
            'period_start' => $start->toDateString(),
            'period_end' => $end->toDateString(),
            'transaction_count' => $transactionCount,
            'source' => 'supabase_authoritative',
        ];
    }
}
