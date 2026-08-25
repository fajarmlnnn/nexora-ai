<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\AiProviderException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AiChatRequest;
use App\Services\Ai\AiGatewayService;
use App\Services\Ai\SupabaseFinancialContextRpcService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

class AuthoritativeAiController extends Controller
{
    public function __construct(
        private readonly AiGatewayService $gateway,
        private readonly SupabaseFinancialContextRpcService $financialContext,
    ) {
    }

    public function health(): JsonResponse
    {
        $requestId = (string) Str::uuid();

        try {
            $this->gateway->healthCheck();
        } catch (Throwable $e) {
            Log::warning('AI health check failed.', [
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
            $context = $this->financialContext->build(
                $request->bearerToken() ?? '',
                $request->validated('period_start'),
                $request->validated('period_end'),
                $request->validated('timezone'),
            );

            $answer = $this->gateway->chat(
                $request->validated('messages'),
                $context,
            );
        } catch (AiProviderException $e) {
            Log::warning('AI provider unavailable.', [
                'request_id' => $requestId,
                'exception' => $e::class,
            ]);

            return response()->json([
                'success' => false,
                'error' => [
                    'code' => $e->getCode() === 3004 ? 'AI_RATE_LIMITED' : 'AI_PROVIDER_UNAVAILABLE',
                    'message' => $e->getCode() === 3004
                        ? 'AI sedang ramai. Coba lagi sebentar.'
                        : 'AI service is temporarily unavailable.',
                    'request_id' => $requestId,
                ],
            ], $e->getCode() === 3004 ? 429 : 503);
        } catch (Throwable $e) {
            Log::error('Authoritative AI chat failed.', [
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
                    'content' => trim($answer),
                ],
            ],
            'request_id' => $requestId,
        ]);
    }
}
