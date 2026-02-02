#!/usr/bin/env bash
set -e

export WMILL_HOST=${WMILL_HOST:-http://localhost:8000}
export WMILL_TOKEN=${WMILL_TOKEN:-docker-bootstrap}
export WMILL_NON_INTERACTIVE=1

echo "Starting Windmill..."
/app/windmill &

echo "Waiting for Windmill API..."
until curl -sf "$WMILL_HOST/api/version" > /dev/null; do
  sleep 2
done

echo "Windmill is up"

echo "Ensuring workspace exists..."
wmill workspace add zoomcamp zoomcamp "$WMILL_HOST" \
  --token "$WMILL_TOKEN" \
  --create || true

echo "Switching workspace..."
wmill workspace switch zoomcamp \
  --base-url "$WMILL_HOST" \
  --token "$WMILL_TOKEN"

# echo "Syncing scripts & flows..."
# wmill sync push \
#   --base-url "$WMILL_HOST" \
#   --token "$WMILL_TOKEN" \
#   --workspace zoomcamp \
#   --yes

echo "Bootstrap complete"

# Bring Windmill back to foreground
wait -n