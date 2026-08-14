<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\AiProviderException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AiChatRequest;
use App\Services\Ai\AiGatewayService;
use Illuminate\Http\JsonResponse;

class AiController extends Controller
{
    public function __construct(private readonly AiGatewayService $gateway)
    {
    }

    public function chat(AiChatRequest $request): JsonResponse
    {
        try {
            $answer = $this->gateway->chat(
                $request->validated('messages'),
                $request->validated('financial_context', []),
            );
        } catch (AiProviderException $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'AI_PROVIDER_UNAVAILABLE',
                    'message' => 'AI service is temporarily unavailable.',
                ],
            ], 503);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'message' => [
                    'role' => 'assistant',
                    'content' => $answer,
                ],
            ],
        ]);
    }
}
