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
        // Registration is intentionally IP-throttled because there is no
        // authenticated user identity yet. This limits account-creation abuse
        // without introducing a second identity system or touching Supabase Auth.
        Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:3,1');
        Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:6,1');
    });

    // Legacy Sanctum endpoints remain isolated from the Supabase-first Flutter
    // identity path. They are rate-limited as defense-in-depth while migration
    // work continues; they must not be used as a bypass around Supabase RLS/RPC.
    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        Route::middleware('throttle:60,1')->group(function (): void {
            Route::apiResource('wallets', WalletController::class);
        });

        Route::middleware('throttle:30,1')->group(function (): void {
            Route::apiResource('transactions', TransactionController::class);
        });
    });

    // Supabase Auth remains the Flutter identity provider. These routes verify
    // the Supabase access token before entering the server-side AI gateway.
    Route::middleware(AuthenticateSupabaseUser::class)->group(function (): void {
        Route::get('/ai/health', [AuthoritativeAiController::class, 'health']);
        Route::post('/ai/chat', [AuthoritativeAiController::class, 'chat'])
            ->middleware(AiRateLimit::class);
    });
});
