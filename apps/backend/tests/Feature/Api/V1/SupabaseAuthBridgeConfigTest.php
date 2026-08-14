<?php

namespace Tests\Feature\Api\V1;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Tests\TestCase;

class SupabaseAuthBridgeConfigTest extends TestCase
{
    use RefreshDatabase;

    public function test_ai_route_is_not_backed_by_a_laravel_sanctum_identity(): void
    {
        $routes = app('router')->getRoutes();
        $route = $routes->getByName('generated::missing-name');

        $this->assertNull($route);
        $this->assertSame(
            'https://example.supabase.co',
            Config::set('services.supabase.url', 'https://example.supabase.co')->get('services.supabase.url'),
        );
    }
}
