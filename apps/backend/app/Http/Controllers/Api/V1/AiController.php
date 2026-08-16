<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\AiProviderException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AiChatRequest;
use App\Services\Ai\AiGatewayService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class AiController extends Controller
{
    public function __construct(private readonly AiGatewayService $gateway)
    {
    }

    public function health(): JsonResponse
    {
        $requestId = (string) Str::uuid();

        try {
            $this->gateway->healthCheck();
        } catch (AiProviderException $e) {
            Log::warning('AI health check reported provider unavailable.', [
                'request_id' => $requestId,
                'exception' => $e::class,
            ]);

            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'AI_PROVIDER_UNAVAILABLE',
                    'message' => 'AI provider is unavailable or misconfigured.',
                    'request_id' => $requestId,
                ],
            ], 503);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'status' => 'ok',
                'service' => 'nexora-ai-gateway',
            ],
            'request_id' => $requestId,
        ]);
    }

    public function chat(AiChatRequest $request): JsonResponse
    {
        $requestId = (string) Str::uuid();

        try {
            $answer = $this->gateway->chat(
                $request->validated('messages'),
                $request->validated('financial_context', []),
            );
        } catch (AiProviderException $e) {
            Log::warning('AI chat provider unavailable.', [
                'request_id' => $requestId,
                'exception' => $e::class,
            ]);

            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'AI_PROVIDER_UNAVAILABLE',
                    'message' => 'AI service is temporarily unavailable.',
                    'request_id' => $requestId,
                ],
            ], 503);
        } catch (\Throwable $e) {
            Log::error('Unexpected AI chat failure.', [
                'request_id' => $requestId,
                'exception' => $e::class,
            ]);

            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'AI_INTERNAL_ERROR',
                    'message' => 'Nexora AI mengalami kesalahan internal.',
                    'request_id' => $requestId,
                ],
            ], 500);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'message' => [
                    'role' => 'assistant',
                    'content' => $answer,
                ],
            ],
            'request_id' => $requestId,
        ]);
    }
}
