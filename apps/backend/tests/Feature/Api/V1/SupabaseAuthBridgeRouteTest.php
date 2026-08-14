<?php

namespace Tests\Feature\Api\V1;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class SupabaseAuthBridgeRouteTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Config::set('services.supabase.url', 'https://example.supabase.co');
        Config::set('services.supabase.publishable_key', 'test-publishable-key');
    }

    public function test_ai_route_uses_supabase_identity_without_a_sanctum_token(): void
    {
        Http::fake([
            'https://example.supabase.co/auth/v1/user' => Http::response([
                'id' => '11111111-1111-1111-1111-111111111111',
                'role' => 'authenticated',
            ]),
            'https://api.openai.com/v1/chat/completions' => Http::response([
                'choices' => [[
                    'message' => [
                        'role' => 'assistant',
                        'content' => 'ok',
                    ],
                ]],
            ]),
        ]);

        Config::set('ai.api_key', 'test-key');
        Config::set('ai.base_url', 'https://api.openai.com/v1');
        Config::set('ai.model', 'test-model');

        $this->withHeader('Authorization', 'Bearer supabase-access-token')
            ->postJson('/api/v1/ai/chat', [
                'messages' => [
                    ['role' => 'user', 'content' => 'test'],
                ],
            ])
            ->assertOk()
            ->assertJsonPath('data.message.content', 'ok');

        Http::assertSent(function ($request): bool {
            return $request->url() === 'https://example.supabase.co/auth/v1/user'
                && $request->hasHeader('Authorization', 'Bearer supabase-access-token');
        });
    }
}
