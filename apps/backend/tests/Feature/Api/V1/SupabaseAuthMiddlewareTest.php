<?php

namespace Tests\Feature\Api\V1;

use App\Http\Middleware\AuthenticateSupabaseUser;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class SupabaseAuthMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Config::set('services.supabase.url', 'https://example.supabase.co');
        Config::set('services.supabase.publishable_key', 'test-publishable-key');
    }

    public function test_missing_bearer_token_is_rejected_without_calling_supabase(): void
    {
        Http::fake();

        $this->postJson('/api/v1/ai/chat', [
            'messages' => [
                ['role' => 'user', 'content' => 'test'],
            ],
        ])->assertUnauthorized();

        Http::assertNothingSent();
    }

    public function test_supabase_identity_is_attached_to_the_request(): void
    {
        Http::fake([
            'https://example.supabase.co/auth/v1/user' => Http::response([
                'id' => '11111111-1111-1111-1111-111111111111',
                'role' => 'authenticated',
            ]),
        ]);

        $request = Request::create('/api/v1/ai/chat', 'POST');
        $request->headers->set('Authorization', 'Bearer valid-token');

        $response = app(AuthenticateSupabaseUser::class)->handle(
            $request,
            fn (Request $request) => response()->json([
                'user_id' => $request->attributes->get('supabase_user_id'),
            ]),
        );

        $response->assertOk()->assertJsonPath(
            'user_id',
            '11111111-1111-1111-1111-111111111111',
        );

        Http::assertSent(function ($request): bool {
            return $request->url() === 'https://example.supabase.co/auth/v1/user'
                && $request->hasHeader('apikey', 'test-publishable-key')
                && $request->hasHeader('Authorization', 'Bearer valid-token');
        });
    }

    public function test_supabase_auth_outage_returns_503_without_leaking_provider_details(): void
    {
        Http::fake([
            'https://example.supabase.co/auth/v1/user' => Http::response([
                'error' => 'upstream internal detail',
            ], 500),
        ]);

        $this->withHeader('Authorization', 'Bearer valid-token')
            ->postJson('/api/v1/ai/chat', [
                'messages' => [
                    ['role' => 'user', 'content' => 'test'],
                ],
            ])
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHENTICATED')
            ->assertJsonMissing(['upstream internal detail']);
    }
}
