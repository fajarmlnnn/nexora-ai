<?php

namespace App\Http\Controllers\Api\V1;

use App\Services\Ai\AiGatewayService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Throwable;

class AiHealthController
{
    public function __construct(private readonly AiGatewayService $gateway)
    {
    }

    public function __invoke(): JsonResponse
    {
        $requestId = request()->header('X-Request-ID') ?: (string) str()->uuid();

        try {
            $result = $this->gateway->healthCheck();

            return response()->json([
                'success' => true,
                'data' => $result,
                'request_id' => $requestId,
            ]);
        } catch (Throwable $e) {
            Log::error('AI health check failed', [
                'request_id' => $requestId,
                'exception' => $e::class,
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'AI_PROVIDER_UNAVAILABLE',
                    'message' => 'AI provider is unavailable.',
                    'request_id' => $requestId,
                ],
            ], 503);
        }
    }
}
