<?php

$provider = strtolower((string) env('AI_PROVIDER', env('GROQ_API_KEY') ? 'groq' : 'openai_compatible'));
$configuredModel = trim((string) env('AI_MODEL', $provider === 'groq'
    ? env('GROQ_MODEL', 'openai/gpt-oss-20b')
    : (env('GROQ_API_KEY') ? 'openai/gpt-oss-20b' : 'gpt-4o-mini')));

// Groq retired several older production model IDs. Keep deployments resilient
// when an old model is still present in hosting environment variables by
// mapping only known retired IDs to their official replacements.
if ($provider === 'groq') {
    $deprecatedGroqModels = [
        'llama-3.1-8b-instant' => 'openai/gpt-oss-20b',
        'llama-3.3-70b-versatile' => 'openai/gpt-oss-120b',
        'qwen/qwen3-32b' => 'openai/gpt-oss-120b',
        'meta-llama/llama-4-scout-17b-16e-instruct' => 'openai/gpt-oss-120b',
        'moonshotai/kimi-k2-instruct-0905' => 'openai/gpt-oss-120b',
    ];

    $configuredModel = $deprecatedGroqModels[$configuredModel] ?? $configuredModel;
}

return [
    'provider' => $provider,
    'base_url' => rtrim(
        env('AI_BASE_URL', $provider === 'groq'
            ? 'https://api.groq.com/openai/v1'
            : (env('GROQ_API_KEY') ? 'https://api.groq.com/openai/v1' : 'https://api.openai.com/v1')),
        '/'
    ),
    // When Groq is explicitly selected, prefer the dedicated Groq secret so
    // an old generic AI_API_KEY cannot accidentally authenticate against Groq.
    'api_key' => $provider === 'groq'
        ? env('GROQ_API_KEY', env('AI_API_KEY'))
        : env('AI_API_KEY', env('GROQ_API_KEY')),
    'model' => $configuredModel,
    'fallback_provider' => env('AI_FALLBACK_PROVIDER', 'gemini'),
    'fallback_base_url' => rtrim(env('AI_FALLBACK_BASE_URL', 'https://generativelanguage.googleapis.com/v1beta/openai'), '/'),
    'fallback_api_key' => env('AI_FALLBACK_API_KEY', env('GEMINI_API_KEY')),
    'fallback_model' => env('AI_FALLBACK_MODEL', 'gemini-2.5-flash'),
    'timeout' => max(5, min((int) env('AI_TIMEOUT', 18), 18)),
    'max_tokens' => max(128, min((int) env('AI_MAX_TOKENS', 600), 800)),
    'reasoning_effort' => env('AI_REASONING_EFFORT', 'low'),

    // AI admission control must not depend on the application's default cache
    // store. Production can opt into a shared store (for example Redis) with
    // AI_RATE_LIMIT_STORE; file cache is safe for the current single-container
    // deployment and keeps the AI gateway available when DB cache is absent.
    'rate_limit_store' => env('AI_RATE_LIMIT_STORE', 'file'),
];