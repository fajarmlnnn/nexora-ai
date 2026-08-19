# Nexora API — Laravel production container
FROM php:8.4-cli-alpine

WORKDIR /var/www/html

# Runtime libraries + build dependencies for Laravel/Supabase Postgres.
RUN apk add --no-cache \
        bash \
        curl \
        icu-libs \
        libzip \
        oniguruma \
        libpq \
        unzip \
    && apk add --no-cache --virtual .build-deps \
        icu-dev \
        libzip-dev \
        oniguruma-dev \
        postgresql-dev \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        intl \
        mbstring \
        pcntl \
        pdo_pgsql \
        zip \
    && apk del --no-network .build-deps

# Install Composer from the official Composer image.
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy dependency manifests first for Docker layer caching.
COPY composer.json composer.lock ./

# GitHub can temporarily return HTTP 429 while Composer resolves/downloads
# public dist archives. Keep production builds resilient by limiting Composer's
# parallel HTTP work and retrying with exponential backoff before failing.
RUN set -eu; \
    attempt=1; \
    max_attempts=5; \
    while [ "$attempt" -le "$max_attempts" ]; do \
        if COMPOSER_MAX_PARALLEL_HTTP=1 composer install \
            --no-dev \
            --no-interaction \
            --no-progress \
            --prefer-dist \
            --optimize-autoloader \
            --no-scripts; then \
            break; \
        fi; \
        if [ "$attempt" -eq "$max_attempts" ]; then \
            echo "Composer install failed after $max_attempts attempts." >&2; \
            exit 1; \
        fi; \
        delay=$((attempt * 10)); \
        echo "Composer install failed (attempt $attempt/$max_attempts); retrying in ${delay}s..." >&2; \
        sleep "$delay"; \
        attempt=$((attempt + 1)); \
    done

# Copy the Laravel application.
COPY . .

# Laravel needs these writable at runtime.
RUN mkdir -p storage/framework/cache \
           storage/framework/sessions \
           storage/framework/views \
           storage/logs \
           bootstrap/cache \
    && chmod -R ug+rwx storage bootstrap/cache \
    && composer dump-autoload --optimize --no-dev

EXPOSE 10000

# Database schema changes are applied explicitly by Backend CI/deployment
# tooling. Production startup must not run the full migration history against
# an already-provisioned Supabase schema.
CMD ["sh", "-c", "php artisan serve --host=0.0.0.0 --port=${PORT:-10000}"]
