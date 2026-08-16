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

RUN composer install \
        --no-dev \
        --no-interaction \
        --no-progress \
        --prefer-dist \
        --optimize-autoloader \
        --no-scripts

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

# DockHosting supplies $PORT. The shell form intentionally expands it at runtime.
CMD ["sh", "-c", "php artisan serve --host=0.0.0.0 --port=${PORT:-10000}"]
