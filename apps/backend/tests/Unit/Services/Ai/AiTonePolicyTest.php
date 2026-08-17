<?php

namespace Tests\Unit\Services\Ai;

use App\Services\Ai\AiGatewayService;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AiTonePolicyTest extends TestCase
{
    public function test_system_prompt_and_output_follow_plain_chat_gen_z_financial_policy(): void
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
            "Kondisi cashflow\n\nPemasukan: Rp5.000.000\nPengeluaran: Rp500.000\n\nCashflow kamu lagi positif.\nTetap cek pengeluaran yang belum tercatat.",
            $result,
        );

        foreach (['#', '*', '`', '•', '---'] as $marker) {
            $this->assertStringNotContainsString($marker, $result);
        }

        Http::assertSentCount(1);
        $recorded = Http::recorded();
        $request = $recorded[0][0];
        $messages = $request->data()['messages'] ?? [];
        $this->assertNotEmpty($messages);

        $system = (string) ($messages[0]['content'] ?? '');
        $lowerSystem = strtolower($system);

        $this->assertStringContainsString('Nexora AI', $system);
        $this->assertStringContainsString('Gen Z', $system);
        $this->assertStringContainsString('Markdown', $system);
        $this->assertStringContainsString('financial', $lowerSystem);
        $this->assertStringContainsString('healthy', $lowerSystem);
        $this->assertStringContainsString('invent', $lowerSystem);
        $this->assertStringContainsString('secret', $lowerSystem);

        $this->assertStringContainsString('smart friend', $lowerSystem);
        $this->assertStringContainsString('natural conversation', $lowerSystem);
        $this->assertStringContainsString('generic chatbot template', $lowerSystem);
        $this->assertStringContainsString('canned', $lowerSystem);
        $this->assertStringContainsString('kamu', $lowerSystem);
        $this->assertStringContainsString('anda', $lowerSystem);
    }
}
