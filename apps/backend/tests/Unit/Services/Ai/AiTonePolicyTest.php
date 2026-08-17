<?php

namespace Tests\Unit\Services\Ai;

use App\Services\Ai\AiGatewayService;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AiTonePolicyTest extends TestCase
{
    public function test_system_prompt_requires_casual_indonesian_youthful_tone_and_calibrated_financial_claims(): void
    {
        Config::set('ai.provider', 'gemini');
        Config::set('ai.api_key', 'test-key');
        Config::set('ai.base_url', 'https://generativelanguage.googleapis.com/v1beta/openai');
        Config::set('ai.model', 'gemini-3.6-flash');
        Config::set('ai.reasoning_effort', 'low');

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions' => Http::response([
                'choices' => [[
                    'message' => [
                        'role' => 'assistant',
                        'content' => "### Kondisi cashflow\n\n**Pemasukan:** Rp5.000.000\n**Pengeluaran:** Rp500.000\n\n---\n\n*Cashflow kamu lagi positif.*\n\n- Tetap cek pengeluaran yang belum tercatat.",
                    ],
                ]],
            ]),
        ]);

        $result = app(AiGatewayService::class)->chat([
            ['role' => 'user', 'content' => 'Bagaimana kondisi cashflow saya?'],
        ], [
            'income' => 5000000,
            'expense' => 500000,
            'net_cashflow' => 4500000,
            'savings_rate' => 0.9,
            'period_start' => '2026-08-01',
            'period_end' => '2026-08-31',
        ]);

        $this->assertSame(
            "Kondisi cashflow\n\nPemasukan: Rp5.000.000\nPengeluaran: Rp500.000\n\nCashflow kamu lagi positif.\n\n• Tetap cek pengeluaran yang belum tercatat.",
            $result,
        );

        $this->assertStringNotContainsString('#', $result);
        $this->assertStringNotContainsString('*', $result);
        $this->assertStringNotContainsString('`', $result);

        Http::assertSent(function ($request): bool {
            $messages = $request->data()['messages'];
            $system = $messages[0]['content'];

            return str_contains($system, 'natural, casual Indonesian')
                && str_contains($system, 'Gen Z')
                && str_contains($system, 'Do not overuse slang')
                && str_contains($system, 'Base financial conclusions only on the recorded application data')
                && str_contains($system, 'Do not call a financial situation "healthy"')
                && str_contains($system, 'Do not invent missing transactions')
                && str_contains($system, 'Do not use Markdown formatting')
                && str_contains($system, 'Do not use # headings')
                && str_contains($system, 'asterisks for bold or italic text');
        });
    }
}
