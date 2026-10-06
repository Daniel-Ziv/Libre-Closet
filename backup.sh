#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
remote_dir="/tmp/libre-closet-${timestamp}"
remote_archive="/tmp/libre-closet-${timestamp}.tar.gz"
local_archive="backups/libre-closet-${timestamp}.tar.gz"

mkdir -p backups

fly ssh console -C "mkdir -p '$remote_dir'"
fly ssh console -C "node -e '
  const Database = require(\"better-sqlite3\");
  const target = process.argv[1];
  const db = new Database(\"/data/sqlite3.db\");
  db.backup(target)
    .catch((error) => {
      console.error(error);
      process.exitCode = 1;
    })
    .finally(() => db.close());
' '$remote_dir/sqlite3.db'"
fly ssh console -C "find /data -maxdepth 1 -type f -name '*.webp' -exec cp '{}' '$remote_dir/' \; && tar -czf '$remote_archive' -C '$remote_dir' ."
fly ssh sftp get "$remote_archive" "$local_archive"
tar -tzf "$local_archive" >/dev/null

echo "Backup downloaded: $local_archive"
