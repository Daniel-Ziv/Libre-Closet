#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [[ $# -ne 1 || ! -f "$1" ]]; then
  echo "Usage: ./restore.sh backups/libre-closet-TIMESTAMP.tar.gz" >&2
  exit 1
fi

archive="$1"
if tar -tzf "$archive" | awk 'BEGIN { ok=1 } !/^data\// || /(^|\/)\.\.($|\/)/ { ok=0 } END { exit !ok }'; then
  :
else
  echo "Refusing archive with unexpected paths; expected only data/." >&2
  exit 1
fi

read -r -p "Replace current Libre Closet data with this backup? Type RESTORE: " answer
if [[ "$answer" != RESTORE ]]; then
  echo "Restore cancelled."
  exit 1
fi

compose=(docker compose --env-file .env.production -f docker-compose.production.yml)
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"

"${compose[@]}" stop app
if [[ -d data ]]; then
  mv data "data.pre-restore-${timestamp}"
fi

if ! tar -xzf "$archive"; then
  if [[ -d "data.pre-restore-${timestamp}" && ! -d data ]]; then
    mv "data.pre-restore-${timestamp}" data
  fi
  "${compose[@]}" start app
  exit 1
fi

"${compose[@]}" start app
echo "Restore complete. Previous data retained at data.pre-restore-${timestamp}"
