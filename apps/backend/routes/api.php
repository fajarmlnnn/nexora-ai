<?php

use App\Http\Controllers\Api\V1\AuthoritativeAiController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\TransactionController;
use App\Http\Controllers\Api\V1\WalletController;
use App\Http\Middleware\AiRateLimit;
use App\Http\Middleware\AuthenticateSupabaseUser;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', function () {
        return response()->json([
            'success' => true,
            'data' => [
                'status' => 'ok',
                'service' => 'nexora-api',
            ],
        ]);
    });

    Route::prefix('auth')->group(function (): void {
        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:6,1');
    });

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        Route::apiResource('wallets', WalletController::class);
        Route::apiResource('transactions', TransactionController::class);
    });

    // Supabase Auth remains the Flutter identity provider. These routes verify
    // the Supabase access token before entering the server-side AI gateway.
    Route::middleware(AuthenticateSupabaseUser::class)->group(function (): void {
        Route::get('/ai/health', [AuthoritativeAiController::class, 'health']);
        Route::post('/ai/chat', [AuthoritativeAiController::class, 'chat'])
            ->middleware(AiRateLimit::class);
    });
});
