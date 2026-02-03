#!/usr/bin/env bash
set -e

export WMILL_HOST=${WMILL_HOST:-http://localhost:8000}
export WMILL_TOKEN=${WMILL_TOKEN:-docker-bootstrap}
export WMILL_NON_INTERACTIVE=1

export POSTGRES_HOST=${POSTGRES_HOST:-db}
export POSTGRES_DB=${POSTGRES_DB:-windmill}
export POSTGRES_USER=${POSTGRES_USER:-root}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-changeme}

echo "Starting Windmill..."
/app/windmill &

echo "Waiting for Windmill API..."
until curl -sf "$WMILL_HOST/api/version" > /dev/null; do
  sleep 2
done

echo "Windmill is up"

echo "Ensuring bootstrap token exists..."

export PGPASSWORD="${POSTGRES_PASSWORD}"

psql \
  -h "${POSTGRES_HOST}" \
  -U "${POSTGRES_USER}" \
  -d "${POSTGRES_DB}" \
  <<'SQL'
INSERT INTO public.token (
  token,
  label,
  email,
  super_admin
)
VALUES (
  'docker-bootstrap',
  'docker-bootstrap',
  'admin@windmill.dev',
  true
)
ON CONFLICT (token) DO NOTHING;
SQL

echo "Bootstrap token ensured"

echo "Ensuring workspace exists..."
wmill workspace add zoomcamp zoomcamp "$WMILL_HOST" \
  --token "$WMILL_TOKEN" \
  --create || true

echo "Switching workspace..."
wmill workspace switch zoomcamp \
  --base-url "$WMILL_HOST" \
  --token "$WMILL_TOKEN"

echo "Syncing scripts & flows..."
cd /app/zoomcamp
wmill sync push \
  --base-url "$WMILL_HOST" \
  --token "$WMILL_TOKEN" \
  --workspace zoomcamp \
  --yes

echo "Bootstrap complete"

# Bring Windmill back to foreground
wait -n