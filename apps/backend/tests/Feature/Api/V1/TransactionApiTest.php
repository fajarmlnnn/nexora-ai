<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TransactionApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_create_income_and_balance_is_updated(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create([
            'user_id' => $user->id,
            'name' => 'BCA',
            'type' => 'bank',
            'balance' => 100000,
        ]);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/transactions', [
            'title' => 'Salary', 'amount' => 5000000, 'type' => 'income', 'category' => 'salary',
            'date' => '2026-08-12T10:00:00+07:00', 'wallet_id' => $wallet->id,
        ]);

        $response->assertCreated()->assertJsonPath('success', true)->assertJsonPath('data.type', 'income');
        $this->assertDatabaseHas('transactions', ['user_id' => $user->id, 'wallet_id' => $wallet->id, 'type' => 'income', 'category' => 'salary', 'title' => 'Salary']);
        $this->assertSame(5100000.0, (float) $wallet->fresh()->balance);
    }

    public function test_expense_updates_wallet_balance_and_delete_restores_it(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create(['user_id' => $user->id, 'name' => 'Cash', 'type' => 'cash', 'balance' => 1000000]);
        Sanctum::actingAs($user);

        $created = $this->postJson('/api/v1/transactions', [
            'title' => 'Lunch', 'amount' => 75000, 'type' => 'expense', 'category' => 'food',
            'date' => '2026-08-12T12:00:00+07:00', 'wallet_id' => $wallet->id,
        ])->assertCreated();

        $this->assertSame(925000.0, (float) $wallet->fresh()->balance);
        $id = $created->json('data.id');
        $this->deleteJson('/api/v1/transactions/'.$id)->assertOk();
        $this->assertDatabaseMissing('transactions', ['id' => $id]);
        $this->assertSame(1000000.0, (float) $wallet->fresh()->balance);
    }

    public function test_updating_transaction_reverses_old_effect_before_applying_new_effect(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create(['user_id' => $user->id, 'name' => 'Cash', 'type' => 'cash', 'balance' => 1000000]);
        Sanctum::actingAs($user);

        $created = $this->postJson('/api/v1/transactions', [
            'title' => 'Old expense', 'amount' => 100000, 'type' => 'expense', 'category' => 'food',
            'date' => '2026-08-12T12:00:00+07:00', 'wallet_id' => $wallet->id,
        ])->assertCreated();

        $id = $created->json('data.id');
        $this->assertSame(900000.0, (float) $wallet->fresh()->balance);

        $this->putJson('/api/v1/transactions/'.$id, [
            'title' => 'Updated expense', 'amount' => 250000, 'type' => 'expense', 'category' => 'shopping',
            'date' => '2026-08-12T13:00:00+07:00', 'wallet_id' => $wallet->id,
        ])->assertOk();

        $this->assertSame(750000.0, (float) $wallet->fresh()->balance);
        $this->assertDatabaseHas('transactions', ['id' => $id, 'title' => 'Updated expense', 'amount' => 250000, 'category' => 'shopping']);
    }

    public function test_transfer_moves_balance_between_two_wallets(): void
    {
        $user = User::factory()->create();
        $source = Wallet::create(['user_id' => $user->id, 'name' => 'BCA', 'type' => 'bank', 'balance' => 1000000]);
        $destination = Wallet::create(['user_id' => $user->id, 'name' => 'DANA', 'type' => 'ewallet', 'balance' => 250000]);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/transactions', [
            'title' => 'Top up DANA', 'amount' => 300000, 'type' => 'transfer', 'category' => 'other',
            'date' => '2026-08-12T13:00:00+07:00', 'source_wallet_id' => $source->id, 'destination_wallet_id' => $destination->id,
        ]);

        $response->assertCreated()->assertJsonPath('data.type', 'transfer');
        $this->assertSame(700000.0, (float) $source->fresh()->balance);
        $this->assertSame(550000.0, (float) $destination->fresh()->balance);
    }

    public function test_user_cannot_use_or_access_another_users_wallet_or_transaction(): void
    {
        $owner = User::factory()->create();
        $attacker = User::factory()->create();
        $wallet = Wallet::create(['user_id' => $owner->id, 'name' => 'Private Wallet', 'type' => 'bank', 'balance' => 100000]);
        Sanctum::actingAs($attacker);

        $this->postJson('/api/v1/transactions', [
            'title' => 'Invalid', 'amount' => 1000, 'type' => 'expense', 'category' => 'other',
            'date' => '2026-08-12T10:00:00+07:00', 'wallet_id' => $wallet->id,
        ])->assertUnprocessable();

        Sanctum::actingAs($owner);
        $transaction = $this->postJson('/api/v1/transactions', [
            'title' => 'Private', 'amount' => 1000, 'type' => 'expense', 'category' => 'other',
            'date' => '2026-08-12T10:00:00+07:00', 'wallet_id' => $wallet->id,
        ])->assertCreated();

        Sanctum::actingAs($attacker);
        $this->getJson('/api/v1/transactions/'.$transaction->json('data.id'))->assertNotFound();
    }

    public function test_transaction_list_supports_filters_search_and_pagination(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create(['user_id' => $user->id, 'name' => 'Cash', 'type' => 'cash', 'balance' => 1000000]);
        Sanctum::actingAs($user);

        foreach ([['Coffee', 'expense', 'food'], ['Bus', 'expense', 'transport'], ['Salary', 'income', 'salary']] as $item) {
            $this->postJson('/api/v1/transactions', [
                'title' => $item[0], 'amount' => 1000, 'type' => $item[1], 'category' => $item[2],
                'date' => '2026-08-12T10:00:00+07:00', 'wallet_id' => $wallet->id,
            ])->assertCreated();
        }

        $this->getJson('/api/v1/transactions?type=expense&category=food&search=Coffee&per_page=1')
            ->assertOk()->assertJsonPath('meta.total', 1)->assertJsonCount(1, 'data')->assertJsonPath('data.0.title', 'Coffee');
    }

    public function test_validation_rejects_invalid_transaction_shapes(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create(['user_id' => $user->id, 'name' => 'Cash', 'type' => 'cash', 'balance' => 100000]);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/transactions', [
            'title' => 'Bad amount', 'amount' => 0, 'type' => 'expense', 'category' => 'other',
            'date' => '2026-08-12T10:00:00+07:00', 'wallet_id' => $wallet->id,
        ])->assertUnprocessable();

        $this->postJson('/api/v1/transactions', [
            'title' => 'Bad transfer', 'amount' => 1000, 'type' => 'transfer', 'category' => 'other',
            'date' => '2026-08-12T10:00:00+07:00', 'source_wallet_id' => $wallet->id, 'destination_wallet_id' => $wallet->id,
        ])->assertUnprocessable();
    }
}
