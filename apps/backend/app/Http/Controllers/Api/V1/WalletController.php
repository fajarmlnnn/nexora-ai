<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Wallet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class WalletController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $wallets = Wallet::query()
            ->where('user_id', $request->user()->id)
            ->orderByDesc('is_primary')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $wallets,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'bank_name' => ['nullable', 'string', 'max:100'],
            'account_number' => ['nullable', 'string', 'max:100'],
            'balance' => ['nullable', 'numeric', 'min:0'],
            'type' => ['required', 'string', Rule::in(['cash', 'bank', 'ewallet', 'investment', 'other'])],
            'color' => ['nullable', 'string', 'max:20'],
            'is_primary' => ['nullable', 'boolean'],
            'is_hidden' => ['nullable', 'boolean'],
            'minimum_balance' => ['nullable', 'numeric', 'min:0'],
        ]);

        $wallet = Wallet::create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        if ($wallet->is_primary) {
            Wallet::query()
                ->where('user_id', $request->user()->id)
                ->whereKeyNot($wallet->id)
                ->update(['is_primary' => false]);
        }

        return response()->json([
            'success' => true,
            'data' => $wallet->fresh(),
        ], 201);
    }

    public function show(Request $request, Wallet $wallet): JsonResponse
    {
        $this->assertOwnership($request, $wallet);

        return response()->json([
            'success' => true,
            'data' => $wallet,
        ]);
    }

    public function update(Request $request, Wallet $wallet): JsonResponse
    {
        $this->assertOwnership($request, $wallet);
        $this->rejectBalanceMutation($request);

        $validated = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'bank_name' => ['nullable', 'string', 'max:100'],
            'account_number' => ['nullable', 'string', 'max:100'],
            'type' => ['sometimes', 'required', 'string', Rule::in(['cash', 'bank', 'ewallet', 'investment', 'other'])],
            'color' => ['nullable', 'string', 'max:20'],
            'is_primary' => ['sometimes', 'boolean'],
            'is_hidden' => ['sometimes', 'boolean'],
            'minimum_balance' => ['sometimes', 'numeric', 'min:0'],
        ]);

        $wallet->update($validated);

        if ($wallet->is_primary) {
            Wallet::query()
                ->where('user_id', $request->user()->id)
                ->whereKeyNot($wallet->id)
                ->update(['is_primary' => false]);
        }

        return response()->json([
            'success' => true,
            'data' => $wallet->fresh(),
        ]);
    }

    public function destroy(Request $request, Wallet $wallet): JsonResponse
    {
        $this->assertOwnership($request, $wallet);

        $wallet->delete();

        return response()->json([
            'success' => true,
            'data' => null,
        ]);
    }

    private function assertOwnership(Request $request, Wallet $wallet): void
    {
        abort_unless($wallet->user_id === $request->user()->id, 404);
    }

    private function rejectBalanceMutation(Request $request): void
    {
        if ($request->has('balance')) {
            throw ValidationException::withMessages([
                'balance' => ['Wallet balance cannot be changed directly. Create a transaction to change the balance.'],
            ]);
        }
    }
}
