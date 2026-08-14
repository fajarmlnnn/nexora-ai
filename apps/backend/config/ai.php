<?php

return [
    'provider' => env('AI_PROVIDER', 'openai_compatible'),
    'base_url' => rtrim(env('AI_BASE_URL', 'https://api.openai.com/v1'), '/'),
    'api_key' => env('AI_API_KEY'),
    'model' => env('AI_MODEL', 'gpt-4o-mini'),
    'timeout' => (int) env('AI_TIMEOUT', 30),
    'max_tokens' => (int) env('AI_MAX_TOKENS', 700),
];
