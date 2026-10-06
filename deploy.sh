#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v fly >/dev/null 2>&1; then
  echo "Fly CLI is required: https://fly.io/docs/flyctl/install/" >&2
  exit 1
fi

fly auth whoami >/dev/null

secret="$(openssl rand -hex 48)"
fly secrets set --stage ACCESS_TOKEN_SECRET="$secret"
unset secret

fly deploy

echo "Libre Closet is deployed. Create the first account, then run:"
echo "  fly secrets set DISABLE_REGISTRATION=true"
