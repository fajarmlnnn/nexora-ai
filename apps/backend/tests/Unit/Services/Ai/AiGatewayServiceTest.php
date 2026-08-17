<?php

namespace Tests\Unit\Services\Ai;

use App\Services\Ai\AiGatewayService;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AiGatewayServiceTest extends TestCase
{
    public function test_gemini_health_probe_validates_model_metadata_without_generation(): void
    {
        Config::set('ai.provider', 'gemini');
        Config::set('ai.api_key', 'test-key');
        Config::set('ai.base_url', 'https://generativelanguage.googleapis.com/v1beta/openai');
        Config::set('ai.model', 'gemini-3.6-flash');
        Config::set('ai.reasoning_effort', 'low');

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/openai/models/gemini-3.6-flash' => Http::response([
                'id' => 'gemini-3.6-flash',
            ]),
        ]);

        app(AiGatewayService::class)->healthCheck();

        Http::assertSent(function ($request): bool {
            return $request->method() === 'GET'
                && $request->url() === 'https://generativelanguage.googleapis.com/v1beta/openai/models/gemini-3.6-flash'
                && $request->hasHeader('Authorization', 'Bearer test-key');
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

    public function test_chat_keeps_recent_conversation_context_only(): void
    {
        Config::set('ai.provider', 'gemini');
        Config::set('ai.api_key', 'test-key');
        Config::set('ai.base_url', 'https://generativelanguage.googleapis.com/v1beta/openai');
        Config::set('ai.model', 'gemini-3.6-flash');
        Config::set('ai.reasoning_effort', 'low');
        Config::set('ai.max_tokens', 600);

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions' => Http::response([
                'choices' => [[
                    'message' => [
                        'role' => 'assistant',
                        'content' => 'Oke, gue paham.',
                    ],
                ]],
            ]),
        ]);

        $messages = [];
        for ($index = 1; $index <= 12; $index++) {
            $messages[] = [
                'role' => $index % 2 === 0 ? 'assistant' : 'user',
                'content' => "Pesan $index",
            ];
        }

        app(AiGatewayService::class)->chat($messages);

        Http::assertSent(function ($request): bool {
            $sentMessages = $request->data()['messages'];
            $conversation = array_slice($sentMessages, 1);

            return count($sentMessages) === 9
                && $conversation[0]['content'] === 'Pesan 5'
                && $conversation[7]['content'] === 'Pesan 12';
        });
    }
}
