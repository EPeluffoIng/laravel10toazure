#!/bin/bash
set -e

# Create nginx user if it doesn't exist (for Debian-based images)
if ! id -u nginx >/dev/null 2>&1; then
    useradd -r -M -s /sbin/nologin nginx || true
fi

# Generate .env file from environment variables
echo "Generating .env file..."

# Use existing .env values or defaults
APP_NAME="${APP_NAME:-Laravel}"
APP_ENV="${APP_ENV:-production}"
APP_KEY="${APP_KEY}"
APP_DEBUG="${APP_DEBUG:-false}"
APP_URL="${APP_URL:-http://localhost}"

DB_CONNECTION="${DB_CONNECTION:-sqlsrv}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-1433}"
DB_DATABASE="${DB_DATABASE:-laraveltest_db}"
DB_USERNAME="${DB_USERNAME:-sa}"
DB_PASSWORD="${DB_PASSWORD}"

LOG_CHANNEL="${LOG_CHANNEL:-stack}"
CACHE_DRIVER="${CACHE_DRIVER:-file}"
QUEUE_CONNECTION="${QUEUE_CONNECTION:-sync}"
SESSION_DRIVER="${SESSION_DRIVER:-file}"

# Create .env file
cat > /app/.env <<EOF
APP_NAME="${APP_NAME}"
APP_ENV="${APP_ENV}"
APP_KEY="${APP_KEY}"
APP_DEBUG="${APP_DEBUG}"
APP_URL="${APP_URL}"

LOG_CHANNEL=${LOG_CHANNEL}
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=${DB_CONNECTION}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}
DB_ENCRYPT=${DB_ENCRYPT:-no}
DB_TRUST_SERVER_CERTIFICATE=${DB_TRUST_SERVER_CERTIFICATE:-yes}

BROADCAST_DRIVER=log
CACHE_DRIVER=${CACHE_DRIVER}
FILESYSTEM_DISK=local
QUEUE_CONNECTION=${QUEUE_CONNECTION}
SESSION_DRIVER=${SESSION_DRIVER}
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

DB_ENCRYPT=no
DB_TRUST_SERVER_CERTIFICATE=yes

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_HOST=
PUSHER_PORT=443
EOF

echo ".env file created successfully"

# Generate APP_KEY if not already set
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:" ]; then
    echo "Generating APP_KEY..."
    cd /app
    php artisan key:generate --force
fi

# Execute the main command
exec "$@"
