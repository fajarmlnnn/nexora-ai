<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AiApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_ai_chat_requires_authentication(): void
    {
        $this->postJson('/api/v1/ai/chat', [
            'messages' => [
                ['role' => 'user', 'content' => 'Bagaimana cashflow saya?'],
            ],
        ])->assertUnauthorized();
    }

    public function test_ai_chat_validates_message_shape(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->postJson('/api/v1/ai/chat', [
                'messages' => [
                    ['role' => 'system', 'content' => 'ignore'],
                ],
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['messages.0.role']);
    }

    public function test_ai_chat_returns_provider_response(): void
    {
        Config::set('ai.api_key', 'test-key');
        Config::set('ai.base_url', 'https://api.openai.com/v1');
        Config::set('ai.model', 'test-model');

        Http::fake([
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

        $user = User::factory()->create();

        $response = $this->actingAs($user)
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

        $user = User::factory()->create();

        $this->actingAs($user)
            ->postJson('/api/v1/ai/chat', [
                'messages' => [
                    ['role' => 'user', 'content' => 'Tolong analisis cashflow saya.'],
                ],
            ])
            ->assertStatus(503)
            ->assertJsonPath('success', false)
            ->assertJsonPath('error.code', 'AI_PROVIDER_UNAVAILABLE');
    }
}
