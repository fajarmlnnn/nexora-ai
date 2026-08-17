<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Cache\RateLimiter;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

class AiRateLimit
{
    private const MAX_ATTEMPTS = 20;
    private const DECAY_SECONDS = 60;

    public function handle(Request $request, Closure $next): Response
    {
        $userId = $request->attributes->get('supabase_user_id');
        $identity = is_string($userId) && $userId !== ''
            ? 'supabase:'.$userId
            : 'ip:'.$request->ip();

        // Keep AI throttling independent from the application's database cache.
        // The production database may be Supabase-managed and should not be a
        // hard dependency for request admission. The store can be switched to
        // redis/database later through AI_RATE_LIMIT_STORE when infrastructure
        // is ready for a shared limiter.
        $storeName = (string) config('ai.rate_limit_store', 'file');
        $limiter = new RateLimiter(Cache::store($storeName));
        $key = 'nexora:ai:'.$identity;

        if ($limiter->tooManyAttempts($key, self::MAX_ATTEMPTS)) {
            $retryAfter = $limiter->availableIn($key);

            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'AI_RATE_LIMITED',
                    'message' => 'Terlalu banyak permintaan AI. Coba lagi sebentar.',
                    'retry_after' => $retryAfter,
                ],
            ], 429, [
                'Retry-After' => (string) $retryAfter,
            ]);
        }

        $limiter->hit($key, self::DECAY_SECONDS);

        return $next($request);
    }
}
