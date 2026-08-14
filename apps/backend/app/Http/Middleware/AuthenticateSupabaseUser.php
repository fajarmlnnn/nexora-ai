<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateSupabaseUser
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();
        $baseUrl = rtrim((string) config('services.supabase.url'), '/');
        $publishableKey = (string) config('services.supabase.publishable_key');

        if ($token === null || $baseUrl === '' || $publishableKey === '') {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                    'message' => 'Authentication is required.',
                ],
            ], 401);
        }

        try {
            $response = Http::acceptJson()
                ->withHeaders([
                    'apikey' => $publishableKey,
                    'Authorization' => 'Bearer '.$token,
                ])
                ->connectTimeout(3)
                ->timeout(5)
                ->get($baseUrl.'/auth/v1/user');
        } catch (ConnectionException) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'AUTH_PROVIDER_UNAVAILABLE',
                    'message' => 'Authentication service is temporarily unavailable.',
                ],
            ], 503);
        }

        if (! $response->successful()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                    'message' => 'Authentication is required.',
                ],
            ], 401);
        }

        $user = $response->json();
        $userId = is_array($user) ? ($user['id'] ?? null) : null;

        if (! is_string($userId) || $userId === '') {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                    'message' => 'Authentication is required.',
                ],
            ], 401);
        }

        // Keep Supabase Auth as the source of identity. Laravel does not create
        // or persist a second application identity for this request.
        $request->attributes->set('supabase_user_id', $userId);
        $request->attributes->set('supabase_user', $user);

        return $next($request);
    }
}
