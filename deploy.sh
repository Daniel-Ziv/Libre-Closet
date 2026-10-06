#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

compose=(docker compose --env-file .env.production -f docker-compose.production.yml)

for command in docker openssl curl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command not found: $command" >&2
    exit 1
  fi
done

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required." >&2
  exit 1
fi

if [[ ! -f .env.production ]]; then
  cp .env.production.example .env.production
  chmod 600 .env.production
  echo "Created .env.production. Set DOMAIN, then run ./deploy.sh again." >&2
  exit 1
fi

chmod 600 .env.production

domain="$(sed -n 's/^DOMAIN=//p' .env.production | tail -n 1)"
if [[ ! "$domain" =~ ^[A-Za-z0-9-]+\.duckdns\.org$ ]]; then
  echo "DOMAIN in .env.production must be your full DuckDNS hostname." >&2
  exit 1
fi

if grep -q '^ACCESS_TOKEN_SECRET=GENERATE_ME$' .env.production; then
  secret="$(openssl rand -hex 48)"
  sed -i "s/^ACCESS_TOKEN_SECRET=GENERATE_ME$/ACCESS_TOKEN_SECRET=${secret}/" .env.production
  unset secret
  echo "Generated a private JWT signing secret in .env.production."
fi

mkdir -p data backups
"${compose[@]}" config --quiet
"${compose[@]}" up -d --build

echo "Waiting for Libre Closet to become healthy..."
for _ in $(seq 1 60); do
  health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}starting{{end}}' libre-closet-app-1 2>/dev/null || true)"
  if [[ "$health" == healthy ]]; then
    break
  fi
  sleep 2
done

health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}unknown{{end}}' libre-closet-app-1 2>/dev/null || true)"
if [[ "$health" != healthy ]]; then
  echo "Libre Closet did not become healthy. Recent logs:" >&2
  "${compose[@]}" logs --tail=100 app >&2
  exit 1
fi

if curl --fail --silent --show-error --max-time 10 -H "Host: ${domain}" "http://127.0.0.1/" >/dev/null; then
  echo "HTTP proxy check passed. Caddy will enable HTTPS after DuckDNS points to this server."
else
  echo "The app is healthy, but the local Caddy HTTP check is not ready yet." >&2
fi

echo "Libre Closet is running at https://${domain}"
if grep -q '^DISABLE_REGISTRATION=false$' .env.production; then
  echo "Create the first account, then set DISABLE_REGISTRATION=true and rerun ./deploy.sh."
fi
