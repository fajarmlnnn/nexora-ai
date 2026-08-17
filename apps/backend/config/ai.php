<?php

return [
    'provider' => env('AI_PROVIDER', env('GROQ_API_KEY') ? 'groq' : 'openai_compatible'),
    'base_url' => rtrim(env('AI_BASE_URL', env('GROQ_API_KEY') ? 'https://api.groq.com/openai/v1' : 'https://api.openai.com/v1'), '/'),
    'api_key' => env('AI_API_KEY', env('GROQ_API_KEY')),
    'model' => env('AI_MODEL', env('GROQ_API_KEY') ? 'llama-3.1-8b-instant' : 'gpt-4o-mini'),
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
