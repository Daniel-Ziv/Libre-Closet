#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

compose=(docker compose --env-file .env.production -f docker-compose.production.yml)
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
archive="backups/libre-closet-${timestamp}.tar.gz"
was_running=false

mkdir -p backups data

if [[ "$("${compose[@]}" ps --status running --services 2>/dev/null | grep -c '^app$' || true)" -gt 0 ]]; then
  was_running=true
  "${compose[@]}" stop app
fi

restart_app() {
  if [[ "$was_running" == true ]]; then
    "${compose[@]}" start app >/dev/null
  fi
}
trap restart_app EXIT

tar -czf "$archive" data
tar -tzf "$archive" >/dev/null

echo "Backup created: $archive"
