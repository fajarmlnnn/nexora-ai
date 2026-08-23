<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TransactionApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_legacy_transaction_routes_are_unmounted(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson('/api/v1/transactions')->assertNotFound();
        $this->postJson('/api/v1/transactions')->assertNotFound();
        $this->putJson('/api/v1/transactions/1')->assertNotFound();
        $this->deleteJson('/api/v1/transactions/1')->assertNotFound();
    }
}
