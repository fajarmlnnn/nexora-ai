<?php

namespace Tests\Feature\Api\V1;

use App\Services\Ai\AiGatewayService;
use Illuminate\Support\Facades\RateLimiter;
use Mockery;
use Tests\TestCase;

class AiHealthApiTest extends TestCase
{
    public function test_ai_health_returns_success_when_provider_is_healthy(): void
    {
        $gateway = Mockery::mock(AiGatewayService::class);
        $gateway->shouldReceive('healthCheck')->once()->andReturn(['provider' => 'configured']);
        $this->app->instance(AiGatewayService::class, $gateway);

        $response = $this->withHeaders(['Authorization' => 'Bearer test-token'])
            ->getJson('/api/v1/ai/health');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_ai_health_converts_unexpected_provider_exception_to_503(): void
    {
        $gateway = Mockery::mock(AiGatewayService::class);
        $gateway->shouldReceive('healthCheck')->once()->andThrow(new \RuntimeException('provider failure'));
        $this->app->instance(AiGatewayService::class, $gateway);

        $response = $this->withHeaders(['Authorization' => 'Bearer test-token'])
            ->getJson('/api/v1/ai/health');

        $response->assertStatus(503)
            ->assertJsonPath('success', false)
            ->assertJsonPath('error.code', 'AI_PROVIDER_UNAVAILABLE');
    }
}
