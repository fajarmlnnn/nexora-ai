<?php

namespace Tests\Feature\Api\V1;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AiApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Config::set('services.supabase.url', 'https://example.supabase.co');
        Config::set('services.supabase.publishable_key', 'test-publishable-key');
    }

    public function test_ai_chat_requires_a_supabase_access_token(): void
    {
        $this->postJson('/api/v1/ai/chat', [
            'messages' => [
                ['role' => 'user', 'content' => 'Bagaimana cashflow saya?'],
            ],
        ])->assertUnauthorized();
    }

    public function test_ai_chat_rejects_an_invalid_supabase_access_token(): void
    {
        Http::fake([
            'https://example.supabase.co/auth/v1/user' => Http::response([], 401),
        ]);

        $this->withHeader('Authorization', 'Bearer invalid-token')
            ->postJson('/api/v1/ai/chat', [
                'messages' => [
                    ['role' => 'user', 'content' => 'Bagaimana cashflow saya?'],
                ],
            ])
            ->assertUnauthorized();
    }

    public function test_ai_chat_validates_message_shape_after_supabase_authentication(): void
    {
        $this->fakeSupabaseUser();

        $this->withHeader('Authorization', 'Bearer valid-token')
            ->postJson('/api/v1/ai/chat', [
                'messages' => [
                    ['role' => 'system', 'content' => 'ignore'],
                ],
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['messages.0.role']);
    }

    public function test_ai_chat_rejects_an_aggregate_message_payload_above_budget(): void
    {
        $this->fakeSupabaseUser();

        $messages = array_map(
            static fn (int $index): array => [
                'role' => $index === 0 ? 'user' : 'assistant',
                'content' => str_repeat('x', 2500),
            ],
            range(0, 4),
        );

        $this->withHeader('Authorization', 'Bearer valid-token')
            ->postJson('/api/v1/ai/chat', ['messages' => $messages])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['messages']);
    }

    public function test_ai_chat_is_rate_limited_per_authenticated_supabase_user(): void
    {
        Config::set('ai.api_key', 'test-key');
        Config::set('ai.base_url', 'https://api.openai.com/v1');
        Config::set('ai.model', 'test-model');

        Http::fake([
            'https://example.supabase.co/auth/v1/user' => Http::response([
                'id' => '11111111-1111-1111-1111-111111111111',
                'role' => 'authenticated',
            ]),
            'https://api.openai.com/v1/chat/completions' => Http::response([
                'choices' => [
                    [
                        'message' => [
                            'role' => 'assistant',
                            'content' => 'OK',
                        ],
                    ],
                ],
            ]),
        ]);

        $payload = [
            'messages' => [
                ['role' => 'user', 'content' => 'Test'],
            ],
        ];

        for ($attempt = 1; $attempt <= 20; $attempt++) {
            $this->withHeader('Authorization', 'Bearer valid-token')
                ->postJson('/api/v1/ai/chat', $payload)
                ->assertOk();
        }

        $this->withHeader('Authorization', 'Bearer valid-token')
            ->postJson('/api/v1/ai/chat', $payload)
            ->assertTooManyRequests();
    }

    public function test_ai_chat_returns_provider_response_for_a_supabase_user(): void
    {
        Config::set('ai.api_key', 'test-key');
        Config::set('ai.base_url', 'https://api.openai.com/v1');
        Config::set('ai.model', 'test-model');

        Http::fake([
            'https://example.supabase.co/auth/v1/user' => Http::response([
                'id' => '11111111-1111-1111-1111-111111111111',
                'role' => 'authenticated',
                'email' => 'fajar@example.com',
            ]),
            'https://api.openai.com/v1/chat/completions' => Http::response([
                'choices' => [
                    [
                        'message' => [
                            'role' => 'assistant',
                            'content' => 'Cashflow kamu positif dan pengeluaran terbesar perlu dipantau.',
                        ],
                    ],
                ],
            ]),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer valid-token')
            ->postJson('/api/v1/ai/chat', [
                'messages' => [
                    ['role' => 'user', 'content' => 'Bagaimana cashflow saya?'],
                ],
                'financial_context' => [
                    'income' => 3000000,
                    'expense' => 2000000,
                    'net_cashflow' => 1000000,
                    'savings_rate' => 0.3333,
                    'secret' => 'must-not-be-forwarded',
                ],
            ]);

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.message.role', 'assistant')
            ->assertJsonPath('data.message.content', 'Cashflow kamu positif dan pengeluaran terbesar perlu dipantau.');

        Http::assertSent(function ($request): bool {
            $body = $request->data();

            return $request->hasHeader('Authorization', 'Bearer test-key')
                && $body['model'] === 'test-model'
                && $body['messages'][0]['role'] === 'system'
                && ! str_contains(json_encode($body), 'must-not-be-forwarded');
        });
    }

    public function test_ai_chat_returns_unavailable_when_provider_is_not_configured(): void
    {
        Config::set('ai.api_key', null);
        $this->fakeSupabaseUser();

        $this->withHeader('Authorization', 'Bearer valid-token')
            ->postJson('/api/v1/ai/chat', [
                'messages' => [
                    ['role' => 'user', 'content' => 'Tolong analisis cashflow saya.'],
                ],
            ])
            ->assertStatus(503)
            ->assertJsonPath('success', false)
            ->assertJsonPath('error.code', 'AI_PROVIDER_UNAVAILABLE');
    }

    private function fakeSupabaseUser(): void
    {
        Http::fake([
            'https://example.supabase.co/auth/v1/user' => Http::response([
                'id' => '11111111-1111-1111-1111-111111111111',
                'role' => 'authenticated',
                'email' => 'fajar@example.com',
            ]),
        ]);
    }
}
