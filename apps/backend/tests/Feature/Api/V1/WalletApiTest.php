<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WalletApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_legacy_wallet_routes_are_unmounted(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson('/api/v1/wallets')->assertNotFound();
        $this->postJson('/api/v1/wallets', ['name' => 'Cash', 'type' => 'cash'])->assertNotFound();
        $this->getJson('/api/v1/wallets/1')->assertNotFound();
        $this->patchJson('/api/v1/wallets/1', ['name' => 'Cash'])->assertNotFound();
        $this->deleteJson('/api/v1/wallets/1')->assertNotFound();
    }
}
