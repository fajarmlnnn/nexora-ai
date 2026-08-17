<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // AI rate limiting is implemented by AiRateLimit with an isolated,
        // configurable cache store. Do not bind it to the application's
        // default database-backed limiter.
    }
}
