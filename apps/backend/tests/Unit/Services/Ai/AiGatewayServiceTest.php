<?php

namespace Tests\Unit\Services\Ai;

use App\Exceptions\AiProviderException;
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

    public function test_groq_chat_uses_temperature_and_primary_model(): void
    {
        Config::set('ai.provider', 'groq');
        Config::set('ai.api_key', 'groq-key');
        Config::set('ai.base_url', 'https://api.groq.com/openai/v1');
        Config::set('ai.model', 'llama-3.1-8b-instant');
        Config::set('ai.fallback_provider', 'gemini');
        Config::set('ai.fallback_api_key', 'gemini-key');
        Config::set('ai.fallback_base_url', 'https://generativelanguage.googleapis.com/v1beta/openai');
        Config::set('ai.fallback_model', 'gemini-2.5-flash');
        Config::set('ai.max_tokens', 600);

        Http::fake([
            'https://api.groq.com/openai/v1/chat/completions' => Http::response([
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

            return $request->url() === 'https://api.groq.com/openai/v1/chat/completions'
                && $request->hasHeader('Authorization', 'Bearer groq-key')
                && $body['model'] === 'llama-3.1-8b-instant'
                && $body['max_tokens'] === 600
                && $body['temperature'] === 0.2
                && ! array_key_exists('reasoning_effort', $body);
        });
    }

    public function test_groq_rate_limit_falls_back_once_to_gemini(): void
    {
        Config::set('ai.provider', 'groq');
        Config::set('ai.api_key', 'groq-key');
        Config::set('ai.base_url', 'https://api.groq.com/openai/v1');
        Config::set('ai.model', 'llama-3.1-8b-instant');
        Config::set('ai.fallback_provider', 'gemini');
        Config::set('ai.fallback_api_key', 'gemini-key');
        Config::set('ai.fallback_base_url', 'https://generativelanguage.googleapis.com/v1beta/openai');
        Config::set('ai.fallback_model', 'gemini-2.5-flash');

        Http::fake([
            'https://api.groq.com/openai/v1/chat/completions' => Http::response([], 429),
            'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions' => Http::response([
                'choices' => [[
                    'message' => [
                        'role' => 'assistant',
                        'content' => 'Oke, gue bantu dari data yang ada.',
                    ],
                ]],
            ]),
        ]);

        $content = app(AiGatewayService::class)->chat([
            ['role' => 'user', 'content' => 'Gimana cashflow gue?'],
        ]);

        $this->assertSame('Oke, gue bantu dari data yang ada.', $content);
        Http::assertSentCount(2);
        Http::assertSent(function ($request): bool {
            return $request->url() === 'https://api.groq.com/openai/v1/chat/completions'
                && $request->data()['model'] === 'llama-3.1-8b-instant';
        });
        Http::assertSent(function ($request): bool {
            $body = $request->data();

            return $request->url() === 'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions'
                && $request->hasHeader('Authorization', 'Bearer gemini-key')
                && $body['model'] === 'gemini-2.5-flash'
                && $body['reasoning_effort'] === 'low'
                && ! array_key_exists('temperature', $body);
        });
    }

    public function test_groq_and_gemini_rate_limits_return_specific_exception(): void
    {
        Config::set('ai.provider', 'groq');
        Config::set('ai.api_key', 'groq-key');
        Config::set('ai.base_url', 'https://api.groq.com/openai/v1');
        Config::set('ai.model', 'llama-3.1-8b-instant');
        Config::set('ai.fallback_provider', 'gemini');
        Config::set('ai.fallback_api_key', 'gemini-key');
        Config::set('ai.fallback_base_url', 'https://generativelanguage.googleapis.com/v1beta/openai');
        Config::set('ai.fallback_model', 'gemini-2.5-flash');

        Http::fake([
            'https://api.groq.com/openai/v1/chat/completions' => Http::response([], 429),
            'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions' => Http::response([], 429),
        ]);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionCode(3004);

        app(AiGatewayService::class)->chat([
            ['role' => 'user', 'content' => 'Coba lagi.'],
        ]);

        Http::assertSentCount(2);
    }

    public function test_chat_keeps_recent_conversation_context_only(): void
    {
        Config::set('ai.provider', 'groq');
        Config::set('ai.api_key', 'test-key');
        Config::set('ai.base_url', 'https://api.groq.com/openai/v1');
        Config::set('ai.model', 'llama-3.1-8b-instant');
        Config::set('ai.max_tokens', 600);

        Http::fake([
            'https://api.groq.com/openai/v1/chat/completions' => Http::response([
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
