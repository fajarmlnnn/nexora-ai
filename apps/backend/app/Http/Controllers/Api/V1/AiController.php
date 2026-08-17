<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\AiProviderException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AiChatRequest;
use App\Services\Ai\AiGatewayService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

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
            $diagnosticCode = $this->diagnosticCode($e->getCode());

            Log::warning('AI health check reported provider unavailable.', [
                'request_id' => $requestId,
                'exception' => $e::class,
                'diagnostic_code' => $diagnosticCode,
            ]);

            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'AI_PROVIDER_UNAVAILABLE',
                    'message' => 'AI provider is unavailable or misconfigured.',
                    'diagnostic_code' => $diagnosticCode,
                    'request_id' => $requestId,
                ],
            ], 503);
        } catch (Throwable $e) {
            Log::error('Unexpected AI health check failure.', [
                'request_id' => $requestId,
                'exception' => $e::class,
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'AI_PROVIDER_UNAVAILABLE',
                    'message' => 'AI provider is unavailable or misconfigured.',
                    'diagnostic_code' => 'internal_runtime_error',
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
        $financialContext = $request->validated('financial_context', []);

        try {
            $answer = $this->gateway->chat(
                $request->validated('messages'),
                $financialContext,
            );
            $answer = $this->enforceFinancialFacts($answer, $financialContext);
        } catch (AiProviderException $e) {
            $diagnosticCode = $this->diagnosticCode($e->getCode());
            $status = $e->getCode() === 3004 ? 429 : 503;

            Log::warning('AI chat provider unavailable.', [
                'request_id' => $requestId,
                'exception' => $e::class,
                'diagnostic_code' => $diagnosticCode,
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
            ], $status);
        } catch (Throwable $e) {
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

    /**
     * Add a deterministic last-mile guard around facts that must never be
     * hallucinated by the language model. This intentionally fixes only
     * unambiguous financial wording and leaves the model's useful explanation
     * intact.
     *
     * @param array<string, mixed> $context
     */
    private function enforceFinancialFacts(string $answer, array $context): string
    {
        $answer = trim(str_replace(["\r\n", "\r"], "\n", $answer));

        // Never allow the common "3.6 bulan" decimal typo. Emergency funds
        // are a range of 3 to 6 months, not 3.6 months.
        $answer = preg_replace('/\b3\.6\s*bulan\b/i', '3-6 bulan', $answer) ?? $answer;
        $answer = preg_replace('/\b3[.,]6\s*bulan\b/i', '3-6 bulan', $answer) ?? $answer;
        $answer = preg_replace('/Rp\s*1\.5\.3\s*juta/i', 'Rp1.500.000-Rp3.000.000', $answer) ?? $answer;
        $answer = preg_replace('/Rp\s*1\.500\.000\s*\.\s*Rp\s*3\.000\.000/i', 'Rp1.500.000-Rp3.000.000', $answer) ?? $answer;

        $expense = $this->numericContextValue($context['expense'] ?? null);
        if ($expense !== null && $expense > 0) {
            $minEmergency = $expense * 3;
            $maxEmergency = $expense * 6;
            $range = $this->formatRupiah($minEmergency) . '-' . $this->formatRupiah($maxEmergency);

            // If the answer discusses emergency savings but contains a
            // malformed/incorrect numeric range, replace only the range.
            $answer = preg_replace(
                '/(3-6\s*bulan[^\n.]{0,100}?)(?:Rp\s*)?(?:[0-9.,]+\s*(?:juta|jt|ribu|rb)?(?:\s*[-–]\s*[0-9.,]+\s*(?:juta|jt|ribu|rb)?)?)/iu',
                '$1' . $range,
                $answer,
            ) ?? $answer;
        }

        // A cashflow surplus is not proof that the same amount was actually
        // saved. If the model calls the surplus a savings rate, rewrite the
        // complete claim instead of leaving a misleading sentence behind.
        $income = $this->numericContextValue($context['income'] ?? null);
        $net = $this->numericContextValue($context['net_cashflow'] ?? null);
        if ($income !== null && $income > 0 && $net !== null) {
            $expectedRate = round(($net / $income) * 100, 1);
            if ($expectedRate >= 0 && $expectedRate <= 100) {
                $percentage = $this->formatPercentage($expectedRate);
                $answer = preg_replace(
                    '/(?:Dengan\s+)?(?:rasio\s+tabungan|rasio\s+simpanan|tabungan(?:mu| kamu| Anda)?\s+(?:sebesar|mencapai)|simpanan(?:mu| kamu| Anda)?\s+(?:sebesar|mencapai))\s+\d+(?:[.,]\d+)?\s*%[^.\n]*\.?/iu',
                    'Surplus kas tercatat sekitar ' . $percentage . ' dari pendapatan.',
                    $answer,
                ) ?? $answer;

                $answer = preg_replace(
                    '/\b(?:kamu|Anda)\s+sudah\s+menabung\s+[^.\n]*\b(?:pendapatan|penghasilan)\b[^.\n]*\.?/iu',
                    '',
                    $answer,
                ) ?? $answer;
            }
        }

        // Normalize Indonesian Rupiah everywhere in the generated answer.
        // Examples: "5 000 000 IDR" -> "Rp5.000.000" and
        // "1500000 rupiah" -> "Rp1.500.000".
        $answer = $this->normalizeRupiahFormatting($answer);

        // Remove exact duplicate sentences/paragraphs produced by the model.
        // This is intentionally deterministic so the UI never receives the
        // same sentence twice merely because the provider repeated itself.
        $answer = $this->deduplicateAnswer($answer);

        return trim($answer);
    }

    private function normalizeRupiahFormatting(string $answer): string
    {
        $pattern = '/(?<![\d.,])(?:Rp\s*)?((?:\d{1,3}(?:[ .]\d{3})+)|(?:\d{4,}))(?:\s*(?:IDR|rupiah))\b/iu';

        return preg_replace_callback($pattern, function (array $match): string {
            $digits = preg_replace('/\D/', '', $match[1]) ?? '';
            if ($digits === '') {
                return $match[0];
            }

            return 'Rp' . number_format((float) $digits, 0, ',', '.');
        }, $answer) ?? $answer;
    }

    private function deduplicateAnswer(string $answer): string
    {
        $paragraphs = preg_split('/\n{2,}/', trim($answer)) ?: [];
        $seenParagraphs = [];
        $uniqueParagraphs = [];

        foreach ($paragraphs as $paragraph) {
            $paragraph = trim($paragraph);
            if ($paragraph === '') {
                continue;
            }

            $key = $this->normalizedComparisonKey($paragraph);
            if ($key !== '' && isset($seenParagraphs[$key])) {
                continue;
            }

            if ($key !== '') {
                $seenParagraphs[$key] = true;
            }

            $sentences = preg_split('/(?<=[.!?])\s+/u', $paragraph) ?: [$paragraph];
            $seenSentences = [];
            $uniqueSentences = [];

            foreach ($sentences as $sentence) {
                $sentence = trim($sentence);
                if ($sentence === '') {
                    continue;
                }

                $sentenceKey = $this->normalizedComparisonKey($sentence);
                if ($sentenceKey !== '' && isset($seenSentences[$sentenceKey])) {
                    continue;
                }

                if ($sentenceKey !== '') {
                    $seenSentences[$sentenceKey] = true;
                }
                $uniqueSentences[] = $sentence;
            }

            if ($uniqueSentences !== []) {
                $uniqueParagraphs[] = implode(' ', $uniqueSentences);
            }
        }

        return implode("\n\n", $uniqueParagraphs);
    }

    private function normalizedComparisonKey(string $value): string
    {
        $value = mb_strtolower(trim($value));
        $value = preg_replace('/\s+/u', ' ', $value) ?? $value;
        return $value;
    }

    private function numericContextValue(mixed $value): ?float
    {
        if (is_int($value) || is_float($value)) {
            return (float) $value;
        }

        if (is_string($value) && is_numeric($value)) {
            return (float) $value;
        }

        return null;
    }

    private function formatRupiah(float $value): string
    {
        return 'Rp' . number_format($value, 0, ',', '.');
    }

    private function formatPercentage(float $value): string
    {
        $formatted = rtrim(rtrim(number_format($value, 1, ',', '.'), '0'), ',');
        return $formatted . '%';
    }

    private function diagnosticCode(int $code): string
    {
        return match ($code) {
            1001 => 'configuration_missing',
            1002 => 'configuration_invalid_url',
            2000 => 'provider_connection_failed',
            3000 => 'provider_rejected_request',
            3001 => 'provider_empty_response',
            3002 => 'provider_response_too_large',
            3004 => 'provider_rate_limited',
            default => 'provider_unavailable',
        };
    }
}
