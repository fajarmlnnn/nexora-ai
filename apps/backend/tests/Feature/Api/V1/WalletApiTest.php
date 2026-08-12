<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WalletApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_list_wallets(): void
    {
        $user = User::factory()->create();
        Wallet::create([
            'user_id' => $user->id,
            'name' => 'Cash',
            'balance' => 100000,
            'type' => 'cash',
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/v1/wallets')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data');
    }

    public function test_user_cannot_access_another_users_wallet(): void
    {
        $owner = User::factory()->create();
        $otherUser = User::factory()->create();
        $wallet = Wallet::create([
            'user_id' => $owner->id,
            'name' => 'Private Wallet',
            'balance' => 500000,
            'type' => 'bank',
        ]);

        Sanctum::actingAs($otherUser);

        $this->getJson('/api/v1/wallets/' . $wallet->id)
            ->assertNotFound();
    }

    public function test_primary_wallet_is_unique_per_user(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $first = $this->postJson('/api/v1/wallets', [
            'name' => 'BCA',
            'type' => 'bank',
            'balance' => 1000000,
            'is_primary' => true,
        ])->assertCreated()->json('data');

        $second = $this->postJson('/api/v1/wallets', [
            'name' => 'Cash',
            'type' => 'cash',
            'balance' => 500000,
            'is_primary' => true,
        ])->assertCreated()->json('data');

        $this->assertFalse(Wallet::find($first['id'])->is_primary);
        $this->assertTrue(Wallet::find($second['id'])->is_primary);
    }
}
