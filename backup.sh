#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
remote="/tmp/libre-closet-${timestamp}"
local_path="backups/libre-closet-${timestamp}"

mkdir -p backups

railway ssh -- node -e '
  const fs = require("fs");
  const Database = require("better-sqlite3");
  const target = process.argv[1];
  fs.mkdirSync(target, { recursive: true });
  const db = new Database("/data/sqlite3.db");
  db.backup(`${target}/sqlite3.db`)
    .then(() => {
      for (const name of fs.readdirSync("/data")) {
        if (name.endsWith(".webp")) fs.copyFileSync(`/data/${name}`, `${target}/${name}`);
      }
    })
    .catch((error) => {
      console.error(error);
      process.exitCode = 1;
    })
    .finally(() => db.close());
' "$remote"

railway service files download "$remote" "$local_path"
test -s "$local_path/sqlite3.db"
echo "Backup downloaded: $local_path"
