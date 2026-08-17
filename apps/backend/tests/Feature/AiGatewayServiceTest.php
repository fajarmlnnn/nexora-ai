<?php

namespace Tests\Feature;

use App\Exceptions\AiProviderException;
use App\Services\Ai\AiGatewayService;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class AiGatewayServiceTest extends TestCase
{
    public function test_gateway_sends_only_allowed_financial_context_and_respects_output_budget(): void
    {
        config()->set('ai.api_key', 'test-secret');
        config()->set('ai.base_url', 'https://ai.test/v1');
        config()->set('ai.model', 'test-model');
        config()->set('ai.provider', 'openai');
        config()->set('ai.max_tokens', 5000);

        Http::fake([
            'https://ai.test/v1/chat/completions' => Http::response([
                'choices' => [['message' => ['content' => 'Gunakan surplus secara konservatif.']]],
            ], 200),
        ]);

        $answer = app(AiGatewayService::class)->chat(
            [['role' => 'user', 'content' => 'Apa yang harus saya lakukan?']],
            [
                'income' => 1000000,
                'expense' => 600000,
                'secret_note' => 'must-not-leak',
                'period_start' => '2026-08-01',
            ],
        );

        $this->assertSame('Gunakan surplus secara konservatif.', $answer);
        Http::assertSent(function ($request): bool {
            $payload = $request->data();
            $context = $payload['messages'][0]['content'];

            return $request->header('Authorization')[0] === 'Bearer test-secret'
                && $payload['max_tokens'] === 2000
                && $payload['temperature'] === 0.2
                && str_contains($context, '1000000')
                && str_contains($context, '2026-08-01')
                && ! str_contains($context, 'must-not-leak');
        });
    }

    public function test_provider_failures_are_wrapped_without_exposing_provider_response(): void
    {
        config()->set('ai.api_key', 'test-secret');
        config()->set('ai.base_url', 'https://ai.test/v1');

        Http::fake([
            'https://ai.test/v1/chat/completions' => Http::response([
                'error' => ['message' => 'provider internal detail'],
            ], 429),
        ]);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessage('AI provider rejected the request.');

        app(AiGatewayService::class)->chat([
            ['role' => 'user', 'content' => 'test'],
        ]);
    }

    public function test_provider_failure_logging_contains_only_safe_metadata(): void
    {
        config()->set('ai.api_key', 'super-secret-api-key');
        config()->set('ai.base_url', 'https://ai.test/v1');

        Http::fake([
            'https://ai.test/v1/chat/completions' => Http::response([
                'error' => [
                    'message' => 'provider internal detail',
                    'secret' => 'response-secret',
                    'prompt' => 'private financial prompt',
                ],
            ], 429),
        ]);

        Log::shouldReceive('warning')
            ->once()
            ->with('AI provider rejected request.', [
                'status' => 429,
                'failure_class' => 'rate_limited',
            ]);

        try {
            app(AiGatewayService::class)->chat([
                ['role' => 'user', 'content' => 'private user message'],
            ], [
                'income' => 5000000,
                'expense' => 4000000,
            ]);
            $this->fail('Expected AiProviderException was not thrown.');
        } catch (AiProviderException $e) {
            $this->assertSame('AI provider rejected the request.', $e->getMessage());
        }
    }

    public function test_empty_provider_response_is_rejected(): void
    {
        config()->set('ai.api_key', 'test-secret');
        config()->set('ai.base_url', 'https://ai.test/v1');

        Http::fake([
            'https://ai.test/v1/chat/completions' => Http::response([
                'choices' => [['message' => ['content' => '   ']]],
            ], 200),
        ]);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessage('AI provider returned an empty response.');

        app(AiGatewayService::class)->chat([
            ['role' => 'user', 'content' => 'test'],
        ]);
    }

    public function test_missing_provider_key_fails_closed(): void
    {
        config()->set('ai.api_key', null);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessage('AI provider is not configured.');

        app(AiGatewayService::class)->chat([
            ['role' => 'user', 'content' => 'test'],
        ]);
    }
}
