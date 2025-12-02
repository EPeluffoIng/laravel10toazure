# Stage 1: Build React frontend with Vite
FROM node:18-bullseye AS frontend

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

# Stage 2: PHP application with Nginx and Supervisor
FROM php:8.1-fpm-bullseye

WORKDIR /app

# Install system dependencies and Microsoft ODBC Driver
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    nginx \
    supervisor \
    git \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    zip \
    unzip \
    file \
    openssl \
    bash \
    unixodbc-dev \
    gnupg \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Install Microsoft ODBC Driver 18 for SQL Server
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 mssql-tools18 && \
    rm -rf /var/lib/apt/lists/*

# Install PHP extensions including SQL Server support
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) \
    gd \
    pdo \
    pdo_mysql \
    mbstring \
    bcmath \
    ctype \
    fileinfo && \
    pecl install sqlsrv pdo_sqlsrv && \
    docker-php-ext-enable sqlsrv pdo_sqlsrv

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy composer files
COPY composer.json composer.lock ./

# Install PHP dependencies (don't run scripts yet because app files aren't present)
RUN composer install --no-dev --no-scripts --optimize-autoloader

# Copy application files
COPY . .

# Copy built frontend assets from stage 1
COPY --from=frontend /app/public/build ./public/build

# Set permissions
RUN chown -R www-data:www-data /app && \
    chmod -R 755 /app/storage /app/bootstrap/cache

# Run Composer scripts and discover after app files are present
RUN composer dump-autoload --optimize && \
    php artisan package:discover --ansi || true

# Configure Nginx
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/default.conf /etc/nginx/conf.d/default.conf

# Configure Supervisor
COPY docker/supervisord.conf /etc/supervisord.conf

# Create entrypoint script for environment setup
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create required directories
RUN mkdir -p /var/log/supervisor

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
