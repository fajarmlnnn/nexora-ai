<?php

namespace Tests\Feature\Api\V1;

use Tests\TestCase;

class HealthApiTest extends TestCase
{
    public function test_health_endpoint_returns_a_stable_liveness_payload(): void
    {
        $this->getJson('/api/v1/health')
            ->assertOk()
            ->assertExactJson([
                'success' => true,
                'data' => [
                    'status' => 'ok',
                    'service' => 'nexora-api',
                ],
            ]);
    }
}
