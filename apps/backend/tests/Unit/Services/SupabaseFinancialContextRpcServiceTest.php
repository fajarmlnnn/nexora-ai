<?php

namespace Tests\Unit\Services;

use App\Services\Ai\SupabaseFinancialContextRpcService;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class SupabaseFinancialContextRpcServiceTest extends TestCase
{
    public function test_it_requests_authoritative_context_without_client_financial_values(): void
    {
        Http::fake([
            '*/rest/v1/rpc/nexora_get_ai_financial_context' => Http::response([
                'income' => 1200000,
                'expense' => 300000,
                'net_cashflow' => 900000,
                'savings_rate' => 75,
                'top_expense_category' => 'food',
                'top_expense_value' => 300000,
                'period_start' => '2026-08-01',
                'period_end' => '2026-08-31',
                'transaction_count' => 4,
                'source' => 'supabase_authoritative',
            ], 200),
        ]);

        config()->set('services.supabase.url', 'https://example.supabase.co');
        config()->set('services.supabase.publishable_key', 'publishable-test-key');

        $context = app(SupabaseFinancialContextRpcService::class)->build(
            'user-jwt',
            '2026-08-01',
            '2026-08-31',
        );

        $this->assertSame('supabase_authoritative', $context['source']);
        $this->assertSame(1200000, $context['income']);

        Http::assertSent(function ($request): bool {
            return $request->url() === 'https://example.supabase.co/rest/v1/rpc/nexora_get_ai_financial_context'
                && $request->header('Authorization')[0] === 'Bearer user-jwt'
                && ! array_key_exists('income', $request->data())
                && ! array_key_exists('expense', $request->data())
                && $request['p_period_start'] === '2026-08-01'
                && $request['p_period_end'] === '2026-08-31';
        });
    }
}
