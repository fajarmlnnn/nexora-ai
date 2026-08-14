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

    public function test_expense_cannot_breach_wallet_minimum_balance(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create([
            'user_id' => $user->id,
            'name' => 'Protected Cash',
            'type' => 'cash',
            'balance' => 150000,
            'minimum_balance' => 100000,
        ]);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/transactions', [
            'title' => 'Too large', 'amount' => 60000, 'type' => 'expense', 'category' => 'other',
            'date' => '2026-08-12T10:00:00+07:00', 'wallet_id' => $wallet->id,
        ])->assertUnprocessable();

        $this->assertDatabaseCount('transactions', 0);
        $this->assertSame(150000.0, (float) $wallet->fresh()->balance);
    }

    public function test_transfer_cannot_breach_source_wallet_minimum_balance(): void
    {
        $user = User::factory()->create();
        $source = Wallet::create([
            'user_id' => $user->id, 'name' => 'Source', 'type' => 'bank',
            'balance' => 200000, 'minimum_balance' => 100000,
        ]);
        $destination = Wallet::create([
            'user_id' => $user->id, 'name' => 'Destination', 'type' => 'bank', 'balance' => 0,
        ]);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/transactions', [
            'title' => 'Too large transfer', 'amount' => 150000, 'type' => 'transfer', 'category' => 'other',
            'date' => '2026-08-12T10:00:00+07:00',
            'source_wallet_id' => $source->id, 'destination_wallet_id' => $destination->id,
        ])->assertUnprocessable();

        $this->assertDatabaseCount('transactions', 0);
        $this->assertSame(200000.0, (float) $source->fresh()->balance);
        $this->assertSame(0.0, (float) $destination->fresh()->balance);
    }

    public function test_idempotency_key_prevents_duplicate_transaction_and_balance_change(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create(['user_id' => $user->id, 'name' => 'Cash', 'type' => 'cash', 'balance' => 1000000]);
        Sanctum::actingAs($user);

        $payload = [
            'title' => 'Internet', 'amount' => 50000, 'type' => 'expense', 'category' => 'bills',
            'date' => '2026-08-12T10:00:00+07:00', 'wallet_id' => $wallet->id,
        ];

        $first = $this->withHeader('Idempotency-Key', 'internet-2026-08-12')
            ->postJson('/api/v1/transactions', $payload)
            ->assertCreated();

        $second = $this->withHeader('Idempotency-Key', 'internet-2026-08-12')
            ->postJson('/api/v1/transactions', $payload)
            ->assertOk()
            ->assertJsonPath('meta.idempotent_replay', true);

        $this->assertSame($first->json('data.id'), $second->json('data.id'));
        $this->assertDatabaseCount('transactions', 1);
        $this->assertSame(950000.0, (float) $wallet->fresh()->balance);
    }

    public function test_same_idempotency_key_is_scoped_to_authenticated_user(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $ownerWallet = Wallet::create(['user_id' => $owner->id, 'name' => 'Owner', 'type' => 'cash', 'balance' => 100000]);
        $otherWallet = Wallet::create(['user_id' => $other->id, 'name' => 'Other', 'type' => 'cash', 'balance' => 100000]);

        Sanctum::actingAs($owner);
        $first = $this->withHeader('Idempotency-Key', 'same-key')
            ->postJson('/api/v1/transactions', [
                'title' => 'Owner expense', 'amount' => 10000, 'type' => 'expense', 'category' => 'other',
                'date' => '2026-08-12T10:00:00+07:00', 'wallet_id' => $ownerWallet->id,
            ])->assertCreated();

        Sanctum::actingAs($other);
        $second = $this->withHeader('Idempotency-Key', 'same-key')
            ->postJson('/api/v1/transactions', [
                'title' => 'Other expense', 'amount' => 20000, 'type' => 'expense', 'category' => 'other',
                'date' => '2026-08-12T10:00:00+07:00', 'wallet_id' => $otherWallet->id,
            ])->assertCreated();

        $this->assertNotSame($first->json('data.id'), $second->json('data.id'));
        $this->assertDatabaseCount('transactions', 2);
        $this->assertSame(90000.0, (float) $ownerWallet->fresh()->balance);
        $this->assertSame(80000.0, (float) $otherWallet->fresh()->balance);
    }

    public function test_income_cannot_be_deleted_if_reversal_would_breach_minimum_balance(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create([
            'user_id' => $user->id,
            'name' => 'Protected Cash',
            'type' => 'cash',
            'balance' => 100000,
            'minimum_balance' => 50000,
        ]);
        Sanctum::actingAs($user);

        $income = $this->postJson('/api/v1/transactions', [
            'title' => 'Income', 'amount' => 60000, 'type' => 'income', 'category' => 'salary',
            'date' => '2026-08-12T10:00:00+07:00', 'wallet_id' => $wallet->id,
        ])->assertCreated();

        $this->assertSame(160000.0, (float) $wallet->fresh()->balance);

        $this->deleteJson('/api/v1/transactions/'.$income->json('data.id'))
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['transaction']);

        $this->assertDatabaseCount('transactions', 1);
        $this->assertSame(160000.0, (float) $wallet->fresh()->balance);
    }

    public function test_transfer_cannot_be_deleted_if_reversal_would_breach_destination_minimum_balance(): void
    {
        $user = User::factory()->create();
        $source = Wallet::create([
            'user_id' => $user->id, 'name' => 'Source', 'type' => 'bank',
            'balance' => 300000, 'minimum_balance' => 100000,
        ]);
        $destination = Wallet::create([
            'user_id' => $user->id, 'name' => 'Destination', 'type' => 'bank',
            'balance' => 50000, 'minimum_balance' => 40000,
        ]);
        Sanctum::actingAs($user);

        $transfer = $this->postJson('/api/v1/transactions', [
            'title' => 'Top up', 'amount' => 100000, 'type' => 'transfer', 'category' => 'other',
            'date' => '2026-08-12T10:00:00+07:00',
            'source_wallet_id' => $source->id, 'destination_wallet_id' => $destination->id,
        ])->assertCreated();

        $this->assertSame(200000.0, (float) $source->fresh()->balance);
        $this->assertSame(150000.0, (float) $destination->fresh()->balance);

        $this->deleteJson('/api/v1/transactions/'.$transfer->json('data.id'))
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['transaction']);

        $this->assertDatabaseCount('transactions', 1);
        $this->assertSame(200000.0, (float) $source->fresh()->balance);
        $this->assertSame(150000.0, (float) $destination->fresh()->balance);
    }

    public function test_rejected_reversal_does_not_partially_apply_when_updating_transaction(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::create([
            'user_id' => $user->id, 'name' => 'Protected Cash', 'type' => 'cash',
            'balance' => 100000, 'minimum_balance' => 50000,
        ]);
        Sanctum::actingAs($user);

        $income = $this->postJson('/api/v1/transactions', [
            'title' => 'Income', 'amount' => 60000, 'type' => 'income', 'category' => 'salary',
            'date' => '2026-08-12T10:00:00+07:00', 'wallet_id' => $wallet->id,
        ])->assertCreated();

        $this->putJson('/api/v1/transactions/'.$income->json('data.id'), [
            'title' => 'Changed', 'amount' => 60000, 'type' => 'expense', 'category' => 'shopping',
            'date' => '2026-08-12T11:00:00+07:00', 'wallet_id' => $wallet->id,
        ])->assertUnprocessable()->assertJsonValidationErrors(['transaction']);

        $this->assertDatabaseHas('transactions', [
            'id' => $income->json('data.id'),
            'title' => 'Income',
            'type' => 'income',
            'amount' => 60000,
        ]);
        $this->assertSame(160000.0, (float) $wallet->fresh()->balance);
    }
}
