<?php

namespace App\Services\Ai;

use App\Exceptions\AiProviderException;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AiGatewayService
{
    private const MAX_RESPONSE_CHARS = 8000;
    private const MAX_CONTEXT_MESSAGES = 8;

    public function healthCheck(): void
    {
        $this->validateConfiguration();

        try {
            $provider = strtolower((string) config('ai.provider'));
            $request = Http::acceptJson()
                ->withToken((string) config('ai.api_key'))
                ->connectTimeout(3)
                ->timeout(10)
                ->retry(1, 150, throw: false);

            $response = $request->get(rtrim((string) config('ai.base_url'), '/') . '/models');
        } catch (\Throwable $e) {
            Log::warning('AI provider health check failed.', ['exception' => $e::class]);
            throw new AiProviderException('AI provider health check failed.', 2000, $e);
        }

        if ($response->failed()) {
            Log::warning('AI provider health check rejected.', [
                'provider' => $provider,
                'status' => $response->status(),
                'failure_class' => $this->failureClass($response->status()),
            ]);
            throw new AiProviderException('AI provider health check rejected.', 3000);
        }

        $configuredModel = trim((string) config('ai.model'));
        $models = $response->json('data');
        if (! is_array($models)) {
            Log::warning('AI provider model list returned invalid metadata.', ['provider' => $provider]);
            throw new AiProviderException('AI provider health check returned invalid model metadata.', 3001);
        }

        $available = false;
        foreach ($models as $model) {
            if (is_array($model) && ($model['id'] ?? null) === $configuredModel) {
                $available = true;
                break;
            }
        }

        if (! $available) {
            Log::warning('Configured AI model is not available from provider.', [
                'provider' => $provider,
                'model' => $configuredModel,
            ]);
            throw new AiProviderException('Configured AI model is unavailable.', 3000);
        }
    }

    /** @param array<int, array{role:string,content:string}> $messages */
    public function chat(array $messages, array $financialContext = []): string
    {
        $this->validateConfiguration();
        $messages = $this->trimConversation($messages);

        $system = [
            'role' => 'system',
            'content' => implode("\n", [
                'You are Nexora AI, a financial coaching assistant for everyday users.',
                'Speak in natural, casual Indonesian with a friendly Gen Z vibe. Sound human, warm, direct, and easy to understand.',
                'Use everyday Indonesian and light conversational phrases when they genuinely fit. Do not overuse slang, emojis, or English.',
                'Prioritize natural conversation. Avoid stiff phrases such as "berdasarkan data yang tersedia", "dapat disimpulkan bahwa", "dengan demikian", or "Anda" when simpler language works.',
                'Do not use generic filler openings. Answer simple questions directly.',
                'Keep normal answers short: usually 3-6 sentences. For a simple factual question, prefer 1-3 sentences. Only go longer when the user explicitly asks for detail.',
                'For financial summaries, mention only the important numbers and what they mean. Do not repeat the same conclusion in multiple paragraphs.',
                'Write like a normal chat message. Do not use Markdown headings, bold, tables, bullet markers, or decorative formatting.',
                'Lead with the actual answer, then the key number(s), then at most one practical next step.',
                'Base financial conclusions only on recorded application data and the user message. Never invent transactions, income, expenses, debts, assets, goals, emergency savings, or obligations.',
                'Treat financial context as observed records, not necessarily the complete financial picture. If a conclusion depends on incomplete records, say so naturally.',
                'Separate cashflow from overall financial health. Positive cashflow alone is not proof that someone is financially secure.',
                'Never imply unrecorded expenses exist. Say they may exist and invite the user to add them if relevant.',
                'Do arithmetic from the supplied numbers before stating a result. Never estimate or invent a multiplier. For emergency savings based on monthly expenses, use a clear 3-6 month range: monthly expense × 3 and monthly expense × 6. ALWAYS write the range as "3-6 bulan" or "3–6 bulan"; never write "3.6 bulan" because that means a different number.',
                'When assessing finances: state the result, explain the key numbers, identify the largest recorded expense or useful pattern, then give one practical caveat or next action.',
                'When the user confirms records are complete and cashflow is strongly positive, prioritize near-term obligations, emergency savings, planned goals, then optional investing or discretionary spending.',
                'INVESTMENT SAFETY GATE: Never treat a cashflow surplus as automatically investable. If the conversation indicates the user does not have an emergency fund, or the user is unsure whether they have one, do NOT recommend investing the surplus yet. First recommend building an emergency fund from 3-6 months of essential monthly expenses. If monthly expense data is available, calculate the range explicitly and correctly. Only discuss investing as a later step after the emergency-fund priority is satisfied.',
                'If the user asks "investasi yang cocok" while emergency savings are missing, answer that the priority is the emergency fund first, give the calculated 3-6 month target if possible, and stop there unless the user explicitly asks what to consider after that.',
                'Never describe any investment, savings product, or financial action as "aman", "paling aman", "yang paling aman", "pasti untung", "tanpa risiko", or "dijamin". Never use phrases such as "langkah yang paling aman" or "pilihan paling aman" as absolute claims. Prefer "lebih konservatif", "risiko relatif lebih rendah", or "lebih cocok untuk tujuan ini" when supported by the user context. Every investment has risk, terms, or trade-offs.',
                'Do not claim a deposit can always be withdrawn immediately. Explain that deposits can have a tenor and early withdrawal may have conditions or penalties.',
                'Do not say that investments are generally illiquid. Instead explain that liquidity depends on the specific product: some can be sold quickly but may fluctuate in value, while others have lock-up periods or withdrawal conditions.',
                'Do not recommend a specific investment allocation from a surplus unless the user has first established an adequate emergency reserve and the recommendation is supported by their stated goal and risk tolerance.',
                'When discussing investments, use cautious language and present education rather than a guaranteed prescription. Do not guarantee returns or outcomes.',
                'Never claim to execute transfers, payments, investments, or account changes.',
                'Never request or expose secrets, passwords, access tokens, or API keys.',
                'Financial context: ' . json_encode($this->sanitizeContext($financialContext), JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            ]),
        ];

        $conversation = array_merge([$system], $messages);

        try {
            $primaryProvider = strtolower((string) config('ai.provider'));
            $primaryModel = trim((string) config('ai.model'));
            $payload = $this->chatPayload($conversation, $primaryProvider, $primaryModel);
            $response = $this->sendChatRequest(
                $payload,
                $primaryModel,
                (string) config('ai.api_key'),
                (string) config('ai.base_url'),
            );

            if ($response->status() === 429) {
                $fallbackModel = trim((string) config('ai.fallback_model', ''));
                $fallbackKey = trim((string) config('ai.fallback_api_key', ''));
                $fallbackBaseUrl = trim((string) config('ai.fallback_base_url', ''));
                $fallbackProvider = strtolower((string) config('ai.fallback_provider', 'gemini'));

                if ($fallbackModel !== '' && $fallbackKey !== '' && $fallbackBaseUrl !== '' && ($fallbackProvider !== $primaryProvider || $fallbackModel !== $primaryModel)) {
                    Log::notice('AI primary model rate limited; trying fallback provider.', [
                        'primary_provider' => $primaryProvider,
                        'primary_model' => $primaryModel,
                        'fallback_provider' => $fallbackProvider,
                        'fallback_model' => $fallbackModel,
                    ]);
                    $fallbackPayload = $this->chatPayload($conversation, $fallbackProvider, $fallbackModel);
                    $response = $this->sendChatRequest($fallbackPayload, $fallbackModel, $fallbackKey, $fallbackBaseUrl);
                }
            }
        } catch (\Throwable $e) {
            Log::warning('AI provider request failed.', ['exception' => $e::class]);
            throw new AiProviderException('AI provider request failed.', 2000, $e);
        }

        if ($response->failed()) {
            $status = $response->status();
            Log::warning('AI provider rejected request.', [
                'status' => $status,
                'failure_class' => $this->failureClass($status),
            ]);
            if ($status === 429) {
                throw new AiProviderException('AI provider rate limit reached.', 3004);
            }
            throw new AiProviderException('AI provider rejected the request.', 3000);
        }

        $content = $response->json('choices.0.message.content');
        if (! is_string($content) || trim($content) === '') {
            throw new AiProviderException('AI provider returned an empty response.', 3001);
        }

        $content = $this->normalizeChatText($content);
        if ($content === '') {
            throw new AiProviderException('AI provider returned an empty response.', 3001);
        }
        if (mb_strlen($content) > self::MAX_RESPONSE_CHARS) {
            Log::warning('AI provider response exceeded gateway limit.', ['response_chars' => mb_strlen($content)]);
            throw new AiProviderException('AI provider returned an oversized response.', 3002);
        }

        return $content;
    }

    /** @param array<string, mixed> $payload */
    private function sendChatRequest(array $payload, string $model, string $apiKey, string $baseUrl): Response
    {
        $payload['model'] = $model;

        return Http::acceptJson()
            ->withToken($apiKey)
            ->connectTimeout(3)
            ->timeout(max(5, min((int) config('ai.timeout', 18), 18)))
            ->retry(1, 150, throw: false)
            ->post(rtrim($baseUrl, '/') . '/chat/completions', $payload);
    }

    /** @param array<int, array{role:string,content:string}> $messages */
    private function trimConversation(array $messages): array
    {
        if (count($messages) <= self::MAX_CONTEXT_MESSAGES) {
            return $messages;
        }

        return array_values(array_slice($messages, -self::MAX_CONTEXT_MESSAGES));
    }

    private function normalizeChatText(string $content): string
    {
        $content = str_replace(["\r\n", "\r"], "\n", trim($content));
        $content = preg_replace('/^\s{0,3}#{1,6}\s+/m', '', $content) ?? $content;
        $content = preg_replace('/^\s*(?:\*{3,}|-{3,}|_{3,})\s*$/m', '', $content) ?? $content;
        $content = preg_replace('/\*{1,3}([^*\n]+)\*{1,3}/', '$1', $content) ?? $content;
        $content = preg_replace('/_{1,3}([^_\n]+)_{1,3}/', '$1', $content) ?? $content;
        $content = preg_replace('/`([^`\n]+)`/', '$1', $content) ?? $content;
        $content = preg_replace('/^\s*(?:[-*+]\s+|•\s+)/m', '', $content) ?? $content;
        $content = preg_replace('/^\s*\d+[.)]\s+/m', '', $content) ?? $content;
        $content = preg_replace('/\n{3,}/', "\n\n", $content) ?? $content;
        $content = preg_replace('/\b3\.6\s*bulan\b/i', '3-6 bulan', $content) ?? $content;
        $content = preg_replace('/\b3[.,]?6\s*bulan\b/i', '3-6 bulan', $content) ?? $content;
        $content = preg_replace('/Rp\s*1\.5\.3\s*juta/i', 'Rp1,5-3 juta', $content) ?? $content;
        $content = preg_replace('/Rp\s*1\.500\.000\s*\.\s*Rp\s*3\.000\.000/i', 'Rp1,5-3 juta', $content) ?? $content;
        $content = preg_replace('/\b(investasi|pilihan investasi) yang (paling )?aman\b/i', '$1 dengan risiko relatif lebih rendah', $content) ?? $content;
        $content = preg_replace('/\b(?:langkah|pilihan|cara) yang paling aman\b/i', 'langkah yang lebih konservatif', $content) ?? $content;
        $content = preg_replace('/\b(?:langkah|pilihan|cara) paling aman\b/i', 'langkah yang lebih konservatif', $content) ?? $content;
        $content = preg_replace('/\bdeposito[^.\n]*bisa dicairkan kalau ada kebutuhan mendadak\b/i', 'deposito memiliki tenor dan pencairan sebelum jatuh tempo dapat memiliki ketentuan atau penalti', $content) ?? $content;

        return trim($content);
    }

    /** @param array<int, array{role:string,content:string}> $messages */
    private function chatPayload(array $messages, string $provider, string $model): array
    {
        return $this->applyProviderOptions([
            'model' => $model,
            'messages' => $messages,
            'max_tokens' => max(256, min((int) config('ai.max_tokens', 450), 700)),
        ], $provider);
    }

    /** @param array<string, mixed> $payload */
    private function applyProviderOptions(array $payload, string $provider): array
    {
        if (strtolower($provider) === 'gemini') {
            $payload['reasoning_effort'] = config('ai.reasoning_effort', 'low');
            return $payload;
        }

        $payload['temperature'] = 0.2;
        return $payload;
    }

    private function validateConfiguration(): void
    {
        $apiKey = config('ai.api_key');
        $baseUrl = config('ai.base_url');
        $model = config('ai.model');

        if (! is_string($apiKey) || trim($apiKey) === '' || ! is_string($baseUrl) || trim($baseUrl) === '' || ! is_string($model) || trim($model) === '') {
            throw new AiProviderException('AI provider is not configured.', 1001);
        }

        if (! filter_var($baseUrl, FILTER_VALIDATE_URL) || ! str_starts_with($baseUrl, 'https://')) {
            throw new AiProviderException('AI provider URL is invalid.', 1002);
        }
    }

    private function failureClass(int $status): string
    {
        return match (true) {
            $status === 429 => 'rate_limited',
            $status >= 500 => 'upstream_server_error',
            $status >= 400 => 'provider_client_error',
            default => 'provider_error',
        };
    }

    /** @param array<string, mixed> $context */
    private function sanitizeContext(array $context): array
    {
        $allowed = [
            'income',
            'expense',
            'net_cashflow',
            'savings_rate',
            'top_expense_category',
            'top_expense_value',
            'period_start',
            'period_end',
        ];

        return array_intersect_key($context, array_flip($allowed));
    }
}
