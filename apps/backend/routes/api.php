<?php

use App\Http\Controllers\Api\V1\AiController;
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
        // Health diagnostics should test authentication + provider connectivity
        // without depending on the application's request-rate cache.
        Route::get('/ai/health', [AiController::class, 'health']);

        // Chat remains rate limited, but the limiter uses its own configurable
        // cache store so a missing database cache table cannot break AI access.
        Route::post('/ai/chat', [AiController::class, 'chat'])
            ->middleware(AiRateLimit::class);
    });
});
