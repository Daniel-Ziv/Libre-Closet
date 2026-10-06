# Personal production deployment

This deployment runs Libre Closet and Caddy on one small Linux VM. Caddy is the
only public container. It terminates HTTPS and proxies to Libre Closet over the
private Compose network. Libre Closet uses SQLite and local image storage in
`./data`, which is bind-mounted at `/app/data`.

## Host requirements

- A Linux VM with a public IP
- Docker Engine with the Compose v2 plugin
- TCP ports 22, 80, and 443 allowed; UDP 443 is optional but enables HTTP/3
- A DuckDNS hostname pointed at the VM's public IP

No PostgreSQL, Redis, S3 service, or DuckDNS update token is needed when the VM
has a stable public IP.

## Deploy

```bash
cp .env.production.example .env.production
chmod 600 .env.production
```

Set `DOMAIN` in `.env.production` to the full DuckDNS hostname, then run:

```bash
./deploy.sh
```

The script generates the JWT signing secret automatically. Open the HTTPS URL,
create the first account with a strong unique password, then set
`DISABLE_REGISTRATION=true` in `.env.production` and rerun `./deploy.sh`.

## Operations

All commands run from the repository directory:

```bash
./update.sh
./backup.sh
./restore.sh backups/libre-closet-TIMESTAMP.tar.gz
docker compose --env-file .env.production -f docker-compose.production.yml ps
docker compose --env-file .env.production -f docker-compose.production.yml logs -f
docker compose --env-file .env.production -f docker-compose.production.yml restart
```

Backups briefly stop the application so the SQLite database, WAL files, and
photos are captured consistently. Copy backup archives off the VM periodically;
backups left only on the VM do not protect against VM or disk loss.

## Persistent state

- `data/sqlite3.db`: application database
- `data/*.webp`: uploaded and processed clothing photos
- `data/app.log`: application log
- Docker volume `libre-closet_caddy_data`: TLS certificates and Caddy state

The application data survives container recreation, Docker restart, and host
reboot. The Caddy volume is convenient but not essential to back up because
certificates can be reissued automatically.

## iPhone

Open the HTTPS URL in Safari, sign in, then choose **Share → Add to Home Screen**.
`PWA_ENABLED=true` enables the manifest and service worker used by the installed
web app.
