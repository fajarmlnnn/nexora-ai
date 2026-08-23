<?php

use App\Http\Controllers\Api\V1\AiController;
use App\Http\Controllers\Api\V1\AuthController;
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
        // Registration creates a persistent user and token, so it must be
        // throttled just like login to reduce automated account/token abuse.
        Route::post('/register', [AuthController::class, 'register'])
            ->middleware('throttle:5,1');
        Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:6,1');
    });

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        // Legacy Laravel wallets/transactions are unmounted.
        // Flutter uses Supabase as the financial source of truth.
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
