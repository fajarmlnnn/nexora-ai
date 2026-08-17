#!/bin/sh
set -eu

# Production containers must apply Laravel migrations before serving requests.
# This is especially important because the AI routes use Laravel's database
# cache-backed rate limiter, which requires the `cache` table to exist.
php artisan migrate --force

exec "$@"
