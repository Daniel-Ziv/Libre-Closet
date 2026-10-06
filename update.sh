#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

./backup.sh
git pull --ff-only
fly deploy
fly status
