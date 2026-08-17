<?php

return [
    'provider' => env('AI_PROVIDER', 'openai_compatible'),
    'base_url' => rtrim(env('AI_BASE_URL', 'https://api.openai.com/v1'), '/'),
    'api_key' => env('AI_API_KEY'),
    'model' => env('AI_MODEL', 'gpt-4o-mini'),
    'timeout' => max(5, min((int) env('AI_TIMEOUT', 30), 30)),
    'max_tokens' => max(128, min((int) env('AI_MAX_TOKENS', 700), 1000)),

    // AI admission control must not depend on the application's default cache
    // store. Production can opt into a shared store (for example Redis) with
    // AI_RATE_LIMIT_STORE; file cache is safe for the current single-container
    // deployment and keeps the AI gateway available when DB cache is absent.
    'rate_limit_store' => env('AI_RATE_LIMIT_STORE', 'file'),
];
