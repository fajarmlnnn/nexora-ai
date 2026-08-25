<?php

namespace App\Services\Ai;

use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class SupabaseFinancialContextRpcService
{
    /**
     * Build authoritative financial context through an RLS-aware Supabase RPC.
     * The caller's JWT is forwarded, so the RPC evaluates auth.uid() for the
     * authenticated user. No client-provided monetary aggregate is accepted.
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
            $start = CarbonImmutable::createFromFormat('!Y-m-d', $periodStart, $timezone);
            $end = CarbonImmutable::createFromFormat('!Y-m-d', $periodEnd, $timezone);
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
            ->post($baseUrl.'/rest/v1/rpc/nexora_get_ai_financial_context', [
                'p_period_start' => $start->toDateString(),
                'p_period_end' => $end->toDateString(),
                'p_timezone' => $timezone,
            ]);

        if (! $response->successful()) {
            throw new RuntimeException('Unable to read authoritative financial context from Supabase.');
        }

        $context = $response->json();
        if (! is_array($context)) {
            throw new RuntimeException('Supabase returned an invalid financial context payload.');
        }

        return $context;
    }
}
