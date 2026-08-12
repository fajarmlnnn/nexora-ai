<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\Wallet;
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
        $validated = $this->validateTransaction($request);

        $transaction = DB::transaction(function () use ($request, $validated): Transaction {
            $this->assertWalletOwnership($request->user()->id, $validated);
            $this->validateTransferShape($validated);

            $transaction = Transaction::create([
                ...$validated,
                'user_id' => $request->user()->id,
            ]);

            $this->applyBalanceChange($transaction, $request->user()->id);

            return $transaction;
        });

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

            $this->assertWalletOwnership($request->user()->id, $effective);
            $this->validateTransferShape($effective);

            $this->reverseBalanceChange($transaction);
            $transaction->update($validated);
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
            $wallets[(int) $transaction->source_wallet_id]->decrement('balance', $amount);
            $wallets[(int) $transaction->destination_wallet_id]->increment('balance', $amount);
            return;
        }

        $wallet = $this->lockWallets($userId, [$transaction->wallet_id])[(int) $transaction->wallet_id];
        $transaction->type === 'income'
            ? $wallet->increment('balance', $amount)
            : $wallet->decrement('balance', $amount);
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
}
