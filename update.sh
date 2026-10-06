#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

./backup.sh
git pull --ff-only
docker compose --env-file .env.production -f docker-compose.production.yml build --pull app
docker compose --env-file .env.production -f docker-compose.production.yml up -d
docker compose --env-file .env.production -f docker-compose.production.yml ps
