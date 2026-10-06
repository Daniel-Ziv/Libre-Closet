#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v railway >/dev/null 2>&1; then
  echo "Railway CLI is required: https://docs.railway.com/cli" >&2
  exit 1
fi

railway whoami >/dev/null

secret="$(openssl rand -hex 48)"
printf '%s' "$secret" | railway variable set ACCESS_TOKEN_SECRET --stdin --skip-deploys
unset secret

railway variable set \
  APP_NAME='Libre Closet' \
  AUTH_ENABLED=true \
  PWA_ENABLED=true \
  SUPPORTER_PROMPT_ENABLED=false \
  DISABLE_REGISTRATION=false \
  DATA_PATH=/data \
  DATABASE_TYPE=sqlite \
  DATABASE_SCHEMA=/data/sqlite3.db \
  FILE_STORAGE_TYPE=local \
  --skip-deploys

if ! railway volume list --json | grep -q '"mountPath"[[:space:]]*:[[:space:]]*"/data"'; then
  railway volume add --mount-path /data
fi

railway up --ci
railway domain

echo "Libre Closet is deployed. Create the first account, then run:"
echo "  railway variable set DISABLE_REGISTRATION=true"
