<?php

namespace Tests\Feature\Api\V1;

use App\Models\Transaction;
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

    public function test_wallet_balance_cannot_be_changed_directly(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create([
            'user_id' => $user->id,
            'name' => 'Cash',
            'balance' => 100000,
            'type' => 'cash',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson('/api/v1/wallets/' . $wallet->id, [
            'balance' => 999999999,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['balance']);

        $this->assertSame(100000.0, (float) Wallet::findOrFail($wallet->id)->balance);
    }

    public function test_wallet_metadata_can_be_updated_without_changing_balance(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create([
            'user_id' => $user->id,
            'name' => 'Cash',
            'balance' => 100000,
            'type' => 'cash',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson('/api/v1/wallets/' . $wallet->id, [
            'name' => 'Daily Cash',
            'is_hidden' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Daily Cash')
            ->assertJsonPath('data.is_hidden', true);

        $this->assertSame(100000.0, (float) Wallet::findOrFail($wallet->id)->balance);
    }

    public function test_wallet_with_transactions_cannot_be_deleted(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create([
            'user_id' => $user->id,
            'name' => 'Cash',
            'balance' => 100000,
            'type' => 'cash',
        ]);

        Transaction::create([
            'user_id' => $user->id,
            'wallet_id' => $wallet->id,
            'title' => 'Coffee',
            'amount' => 10000,
            'type' => 'expense',
            'category' => 'food',
            'date' => '2026-08-12 10:00:00',
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson('/api/v1/wallets/' . $wallet->id)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['wallet']);

        $this->assertDatabaseHas('wallets', ['id' => $wallet->id]);
        $this->assertDatabaseHas('transactions', ['wallet_id' => $wallet->id]);
    }

    public function test_empty_wallet_can_be_deleted(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create([
            'user_id' => $user->id,
            'name' => 'Unused',
            'balance' => 0,
            'type' => 'cash',
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson('/api/v1/wallets/' . $wallet->id)
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('wallets', ['id' => $wallet->id]);
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
