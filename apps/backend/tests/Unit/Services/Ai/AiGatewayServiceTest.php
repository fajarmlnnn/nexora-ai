<?php

namespace Tests\Unit\Services\Ai;

use App\Services\Ai\AiGatewayService;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AiGatewayServiceTest extends TestCase
{
    public function test_gemini_health_probe_reserves_output_budget_for_visible_text(): void
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
                        'content' => 'OK',
                    ],
                ]],
            ]),
        ]);

        app(AiGatewayService::class)->healthCheck();

        Http::assertSent(function ($request): bool {
            $body = $request->data();

            return $request->hasHeader('Authorization', 'Bearer test-key')
                && $body['model'] === 'gemini-3.6-flash'
                && $body['max_tokens'] === 64
                && $body['reasoning_effort'] === 'low'
                && ! array_key_exists('temperature', $body);
        });
    }

    public function test_gemini_chat_uses_reasoning_effort_instead_of_temperature(): void
    {
        Config::set('ai.provider', 'gemini');
        Config::set('ai.api_key', 'test-key');
        Config::set('ai.base_url', 'https://generativelanguage.googleapis.com/v1beta/openai');
        Config::set('ai.model', 'gemini-3.6-flash');
        Config::set('ai.reasoning_effort', 'low');
        Config::set('ai.max_tokens', 700);

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions' => Http::response([
                'choices' => [[
                    'message' => [
                        'role' => 'assistant',
                        'content' => 'Cashflow kamu positif.',
                    ],
                ]],
            ]),
        ]);

        $content = app(AiGatewayService::class)->chat([
            ['role' => 'user', 'content' => 'Analisis cashflow saya.'],
        ]);

        $this->assertSame('Cashflow kamu positif.', $content);

        Http::assertSent(function ($request): bool {
            $body = $request->data();

            return $body['reasoning_effort'] === 'low'
                && $body['max_tokens'] === 700
                && ! array_key_exists('temperature', $body);
        });
    }
}
