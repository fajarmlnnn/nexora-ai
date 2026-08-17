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
        Config::set('ai.rate_limit_store', 'array');
    }

    public function test_ai_health_requires_a_supabase_access_token(): void
    {
        $this->getJson('/api/v1/ai/health')->assertUnauthorized();
    }

    public function test_ai_health_returns_ok_when_provider_answers(): void
    {
        Config::set('ai.api_key', 'test-key');
        Config::set('ai.base_url', 'https://api.openai.com/v1');
        Config::set('ai.model', 'test-model');

        Http::fake([
            'https://example.supabase.co/auth/v1/user' => Http::response([
                'id' => 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
                'role' => 'authenticated',
            ]),
            'https://api.openai.com/v1/models' => Http::response([
                'data' => [[
                    'id' => 'test-model',
                    'object' => 'model',
                ]],
            ]),
        ]);

        $this->withHeader('Authorization', 'Bearer valid-token')
            ->getJson('/api/v1/ai/health')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'ok')
            ->assertJsonPath('data.service', 'nexora-ai-gateway');
    }

    public function test_ai_health_returns_503_when_provider_is_not_configured(): void
    {
        Config::set('ai.api_key', null);
        $this->fakeSupabaseUser();

        $this->withHeader('Authorization', 'Bearer valid-token')
            ->getJson('/api/v1/ai/health')
            ->assertStatus(503)
            ->assertJsonPath('success', false)
            ->assertJsonPath('error.code', 'AI_PROVIDER_UNAVAILABLE');
    }

    public function test_ai_health_hides_provider_failure_details(): void
    {
        Config::set('ai.api_key', 'test-key');
        Config::set('ai.base_url', 'https://api.openai.com/v1');
        Config::set('ai.model', 'test-model');

        Http::fake([
            'https://example.supabase.co/auth/v1/user' => Http::response([
                'id' => 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
                'role' => 'authenticated',
            ]),
            'https://api.openai.com/v1/models' => Http::response(['error' => ['message' => 'secret-provider-detail']], 401),
        ]);

        $this->withHeader('Authorization', 'Bearer valid-token')
            ->getJson('/api/v1/ai/health')
            ->assertStatus(503)
            ->assertJsonPath('success', false)
            ->assertJsonPath('error.code', 'AI_PROVIDER_UNAVAILABLE')
            ->assertJsonMissingPath('error.provider_detail');
    }

    private function fakeSupabaseUser(): void
    {
        Http::fake([
            'https://example.supabase.co/auth/v1/user' => Http::response([
                'id' => 'cccccccc-cccc-cccc-cccc-cccccccccccc',
                'role' => 'authenticated',
            ]),
        ]);
    }
}
