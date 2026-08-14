<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\Wallet;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class TransactionController extends Controller
{
    private const TYPES = ['income', 'expense', 'transfer'];

    private const CATEGORIES = [
        'food', 'transport', 'shopping', 'salary', 'investment',
        'bills', 'entertainment', 'health', 'education', 'other',
    ];

    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'type' => ['nullable', Rule::in(self::TYPES)],
            'category' => ['nullable', Rule::in(self::CATEGORIES)],
            'wallet_id' => ['nullable', 'integer', 'exists:wallets,id'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'search' => ['nullable', 'string', 'max:100'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $userId = $request->user()->id;
        $query = Transaction::query()
            ->where('user_id', $userId)
            ->with(['wallet', 'sourceWallet', 'destinationWallet'])
            ->orderByDesc('date')
            ->orderByDesc('id');

        if (isset($validated['type'])) {
            $query->where('type', $validated['type']);
        }

        if (isset($validated['category'])) {
            $query->where('category', $validated['category']);
        }

        if (isset($validated['wallet_id'])) {
            $walletId = (int) $validated['wallet_id'];
            $query->where(function ($walletQuery) use ($walletId): void {
                $walletQuery
                    ->where('wallet_id', $walletId)
                    ->orWhere('source_wallet_id', $walletId)
                    ->orWhere('destination_wallet_id', $walletId);
            });
        }

        if (isset($validated['from'])) {
            $query->where('date', '>=', $validated['from']);
        }

        if (isset($validated['to'])) {
            $query->where('date', '<=', $validated['to']);
        }

        if (isset($validated['search'])) {
            $search = $validated['search'];
            $query->where(function ($searchQuery) use ($search): void {
                $searchQuery
                    ->where('title', 'like', "%{$search}%")
                    ->orWhere('note', 'like', "%{$search}%")
                    ->orWhere('source_account', 'like', "%{$search}%")
                    ->orWhere('destination_account', 'like', "%{$search}%");
            });
        }

        $transactions = $query->paginate($validated['per_page'] ?? 20)->withQueryString();

        return response()->json([
            'success' => true,
            'data' => $transactions->items(),
            'meta' => [
                'current_page' => $transactions->currentPage(),
                'last_page' => $transactions->lastPage(),
                'per_page' => $transactions->perPage(),
                'total' => $transactions->total(),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->normalizeTransaction($this->validateTransaction($request));
        $userId = $request->user()->id;
        $idempotencyKey = $request->header('Idempotency-Key');

        if ($idempotencyKey !== null) {
            $existing = Transaction::query()
                ->where('user_id', $userId)
                ->where('idempotency_key', $idempotencyKey)
                ->first();

            if ($existing) {
                return response()->json([
                    'success' => true,
                    'data' => $existing->load(['wallet', 'sourceWallet', 'destinationWallet']),
                    'meta' => ['idempotent_replay' => true],
                ]);
            }
        }

        $validated['idempotency_key'] = $idempotencyKey;

        try {
            $transaction = DB::transaction(function () use ($userId, $validated): Transaction {
                $this->assertWalletOwnership($userId, $validated);
                $this->validateTransferShape($validated);

                $transaction = Transaction::create([
                    ...$validated,
                    'user_id' => $userId,
                ]);

                $this->applyBalanceChange($transaction, $userId);

                return $transaction;
            });
        } catch (QueryException $exception) {
            if ($idempotencyKey !== null && $this->isIdempotencyConflict($exception)) {
                $existing = Transaction::query()
                    ->where('user_id', $userId)
                    ->where('idempotency_key', $idempotencyKey)
                    ->firstOrFail();

                return response()->json([
                    'success' => true,
                    'data' => $existing->load(['wallet', 'sourceWallet', 'destinationWallet']),
                    'meta' => ['idempotent_replay' => true],
                ]);
            }

            throw $exception;
        }

        return response()->json([
            'success' => true,
            'data' => $transaction->fresh(['wallet', 'sourceWallet', 'destinationWallet']),
        ], 201);
    }

    public function show(Request $request, Transaction $transaction): JsonResponse
    {
        $this->assertOwnership($request, $transaction);

        return response()->json([
            'success' => true,
            'data' => $transaction->load(['wallet', 'sourceWallet', 'destinationWallet']),
        ]);
    }

    public function update(Request $request, Transaction $transaction): JsonResponse
    {
        $this->assertOwnership($request, $transaction);
        $validated = $this->validateTransaction($request, true);

        $updated = DB::transaction(function () use ($request, $transaction, $validated): Transaction {
            $transaction->load(['wallet', 'sourceWallet', 'destinationWallet']);

            $effective = array_merge(
                $transaction->only([
                    'title', 'amount', 'type', 'category', 'date', 'note',
                    'wallet_id', 'source_wallet_id', 'destination_wallet_id',
                    'source_account', 'destination_account',
                ]),
                $validated,
            );
            $effective = $this->normalizeTransaction($effective);

            $this->assertWalletOwnership($request->user()->id, $effective);
            $this->validateTransferShape($effective);

            $this->assertReversalAllowed($transaction);
            $this->reverseBalanceChange($transaction);
            $transaction->update($effective);
            $fresh = $transaction->fresh();
            $this->applyBalanceChange($fresh, $request->user()->id);

            return $fresh;
        });

        return response()->json([
            'success' => true,
            'data' => $updated->fresh(['wallet', 'sourceWallet', 'destinationWallet']),
        ]);
    }

    public function destroy(Request $request, Transaction $transaction): JsonResponse
    {
        $this->assertOwnership($request, $transaction);

        DB::transaction(function () use ($transaction): void {
            $transaction->load(['wallet', 'sourceWallet', 'destinationWallet']);
            $this->assertReversalAllowed($transaction);
            $this->reverseBalanceChange($transaction);
            $transaction->delete();
        });

        return response()->json([
            'success' => true,
            'data' => null,
        ]);
    }

    private function validateTransaction(Request $request, bool $partial = false): array
    {
        $presence = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'title' => [$presence, 'string', 'max:150'],
            'amount' => [$presence, 'numeric', 'gt:0', 'max:999999999999.99'],
            'type' => [$presence, 'string', Rule::in(self::TYPES)],
            'category' => [$partial ? 'sometimes' : 'nullable', 'string', Rule::in(self::CATEGORIES)],
            'date' => [$presence, 'date'],
            'note' => ['nullable', 'string', 'max:5000'],
            'wallet_id' => ['nullable', 'integer', 'exists:wallets,id'],
            'source_wallet_id' => ['nullable', 'integer', 'exists:wallets,id'],
            'destination_wallet_id' => ['nullable', 'integer', 'exists:wallets,id'],
            'source_account' => ['nullable', 'string', 'max:150'],
            'destination_account' => ['nullable', 'string', 'max:150'],
        ]);
    }

    private function normalizeTransaction(array $data): array
    {
        $data['category'] = $data['category'] ?? 'other';

        if (($data['type'] ?? null) === 'transfer') {
            $data['wallet_id'] = null;
        } else {
            $data['source_wallet_id'] = null;
            $data['destination_wallet_id'] = null;
        }

        return $data;
    }

    private function validateTransferShape(array $data): void
    {
        $type = $data['type'] ?? null;

        if ($type === 'transfer') {
            if (empty($data['source_wallet_id']) || empty($data['destination_wallet_id'])) {
                throw ValidationException::withMessages([
                    'source_wallet_id' => ['Source wallet is required for transfers.'],
                    'destination_wallet_id' => ['Destination wallet is required for transfers.'],
                ]);
            }

            if ((int) $data['source_wallet_id'] === (int) $data['destination_wallet_id']) {
                throw ValidationException::withMessages([
                    'destination_wallet_id' => ['Destination wallet must be different from source wallet.'],
                ]);
            }
        } elseif (empty($data['wallet_id'])) {
            throw ValidationException::withMessages([
                'wallet_id' => ['Wallet is required for income and expense transactions.'],
            ]);
        }
    }

    private function assertWalletOwnership(int $userId, array $data): void
    {
        $walletIds = array_filter([
            $data['wallet_id'] ?? null,
            $data['source_wallet_id'] ?? null,
            $data['destination_wallet_id'] ?? null,
        ]);

        if ($walletIds === []) {
            return;
        }

        $uniqueWalletIds = array_unique(array_map('intval', $walletIds));
        $ownedCount = Wallet::query()
            ->where('user_id', $userId)
            ->whereIn('id', $uniqueWalletIds)
            ->count();

        if ($ownedCount !== count($uniqueWalletIds)) {
            throw ValidationException::withMessages([
                'wallet_id' => ['One or more wallets do not belong to the authenticated user.'],
            ]);
        }
    }

    private function assertOwnership(Request $request, Transaction $transaction): void
    {
        abort_unless($transaction->user_id === $request->user()->id, 404);
    }

    private function applyBalanceChange(Transaction $transaction, int $userId): void
    {
        $amount = $transaction->amount;

        if ($transaction->type === 'transfer') {
            $wallets = $this->lockWallets($userId, [$transaction->source_wallet_id, $transaction->destination_wallet_id]);
            $source = $wallets[(int) $transaction->source_wallet_id];
            $this->assertSufficientBalance($source, $amount);
            $source->decrement('balance', $amount);
            $wallets[(int) $transaction->destination_wallet_id]->increment('balance', $amount);
            return;
        }

        $wallet = $this->lockWallets($userId, [$transaction->wallet_id])[(int) $transaction->wallet_id];

        if ($transaction->type === 'income') {
            $wallet->increment('balance', $amount);
            return;
        }

        $this->assertSufficientBalance($wallet, $amount);
        $wallet->decrement('balance', $amount);
    }

    private function assertReversalAllowed(Transaction $transaction): void
    {
        $walletIds = $transaction->type === 'transfer'
            ? [$transaction->source_wallet_id, $transaction->destination_wallet_id]
            : [$transaction->wallet_id];
        $wallets = $this->lockWallets($transaction->user_id, $walletIds);
        $amountCents = $this->moneyToCents($transaction->amount);

        if ($transaction->type === 'income') {
            $wallet = $wallets[(int) $transaction->wallet_id];
            $remainingCents = $this->moneyToCents($wallet->balance) - $amountCents;
            $minimumCents = $this->moneyToCents($wallet->minimum_balance);

            if ($remainingCents < $minimumCents) {
                throw ValidationException::withMessages([
                    'transaction' => ['Transaction cannot be reversed because it would breach the wallet minimum balance.'],
                ]);
            }

            return;
        }

        if ($transaction->type === 'transfer') {
            $destination = $wallets[(int) $transaction->destination_wallet_id];
            $remainingCents = $this->moneyToCents($destination->balance) - $amountCents;
            $minimumCents = $this->moneyToCents($destination->minimum_balance);

            if ($remainingCents < $minimumCents) {
                throw ValidationException::withMessages([
                    'transaction' => ['Transfer cannot be reversed because it would breach the destination wallet minimum balance.'],
                ]);
            }
        }
    }

    private function reverseBalanceChange(Transaction $transaction): void
    {
        $amount = $transaction->amount;
        $userId = $transaction->user_id;

        if ($transaction->type === 'transfer') {
            $wallets = $this->lockWallets($userId, [$transaction->source_wallet_id, $transaction->destination_wallet_id]);
            $wallets[(int) $transaction->source_wallet_id]->increment('balance', $amount);
            $wallets[(int) $transaction->destination_wallet_id]->decrement('balance', $amount);
            return;
        }

        $wallet = $this->lockWallets($userId, [$transaction->wallet_id])[(int) $transaction->wallet_id];
        $transaction->type === 'income'
            ? $wallet->decrement('balance', $amount)
            : $wallet->increment('balance', $amount);
    }

    /** @return array<int, Wallet> */
    private function lockWallets(int $userId, array $walletIds): array
    {
        $ids = array_values(array_unique(array_map('intval', $walletIds)));
        sort($ids);

        $wallets = Wallet::query()
            ->where('user_id', $userId)
            ->whereIn('id', $ids)
            ->lockForUpdate()
            ->get()
            ->keyBy('id');

        if ($wallets->count() !== count($ids)) {
            throw ValidationException::withMessages([
                'wallet_id' => ['One or more wallets could not be found for this user.'],
            ]);
        }

        return $wallets->all();
    }

    private function assertSufficientBalance(Wallet $wallet, mixed $amount): void
    {
        $balanceCents = $this->moneyToCents($wallet->balance);
        $amountCents = $this->moneyToCents($amount);
        $minimumCents = $this->moneyToCents($wallet->minimum_balance);

        if (($balanceCents - $amountCents) < $minimumCents) {
            throw ValidationException::withMessages([
                'amount' => ['Insufficient wallet balance for this transaction.'],
            ]);
        }
    }

    private function moneyToCents(mixed $value): int
    {
        return (int) round(((float) $value) * 100);
    }

    private function isIdempotencyConflict(QueryException $exception): bool
    {
        return str_contains(strtolower($exception->getMessage()), 'idempotency');
    }
}
