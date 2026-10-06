# Personal Railway deployment

Railway is the primary personal deployment target. Its Free plan includes $1
of monthly usage, one 0.5 GB persistent volume, free builds, automatic HTTPS,
and serverless sleeping. Libre Closet's low-traffic personal workload can sleep
between visits and wake on demand.

The `/data` volume contains both SQLite and uploaded clothing photos:

- `/data/sqlite3.db`: database
- `/data/*.webp`: uploaded and processed photos
- `/data/app.log`: application log

No PostgreSQL, Redis, S3 service, VM, Caddy, or open firewall is required.

## Deploy and operate

Install and authenticate the Railway CLI, create or link a Railway project and
service, then run `./deploy.sh`. The service uses `railway.toml` and the existing
Dockerfile. Enable Railway's Serverless option so it sleeps when idle.

After deployment, open the generated `https://*.up.railway.app` URL, create the
first account with a strong unique password, and immediately disable further
registration:

```bash
railway variable set DISABLE_REGISTRATION=true
```

Routine commands:

```bash
./update.sh
./backup.sh
railway service status
railway logs
railway service restart --yes
```

Schedule Railway volume backups under the service's **Backups** settings.
`./backup.sh` also makes an online-consistent SQLite backup, copies the photos,
and downloads the result locally. Railway's native backup restore creates a new
volume from the selected snapshot and keeps the previous volume available.

## Domain limitation

Railway provides automatic HTTPS on its generated domain. Railway custom domains
require both CNAME and TXT records. DuckDNS exposes A/AAAA updates rather than
the records Railway requires, so a DuckDNS subdomain cannot be attached safely.
Use the generated Railway HTTPS URL, or use a domain whose DNS supports CNAME
and TXT records.

## iPhone

Open the HTTPS URL in Safari, sign in, then choose **Share → Add to Home Screen**.
`PWA_ENABLED=true` enables the manifest and service worker used by the installed
web app.
