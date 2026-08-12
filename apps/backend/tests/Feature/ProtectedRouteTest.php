<?php

namespace Tests\Feature;

use Tests\TestCase;

class ProtectedRouteTest extends TestCase
{
    public function test_authenticated_routes_reject_missing_bearer_token(): void
    {
        $this->getJson('/api/v1/auth/me')->assertUnauthorized();
        $this->postJson('/api/v1/auth/logout')->assertUnauthorized();
    }
}
