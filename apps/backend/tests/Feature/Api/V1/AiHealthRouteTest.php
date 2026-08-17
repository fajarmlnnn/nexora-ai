<?php

namespace Tests\Feature\Api\V1;

use Tests\TestCase;

class AiHealthRouteTest extends TestCase
{
    public function test_ai_health_route_is_registered(): void
    {
        $route = app('router')->getRoutes()->getByName('api.v1.ai.health');

        $this->assertNotNull($route);
        $this->assertContains('/api/v1/ai/health', [$route->uri()]);
    }
}
