# Personal Fly.io deployment

This deployment runs one Libre Closet Docker container on Fly.io with one
persistent volume. SQLite and uploaded photos remain together under `/data`.
There is no separate database, object store, proxy, or VM to administer.

The Fly Machine uses 512 MB RAM and automatically stops after several idle
minutes. The next request starts it again. Fly bills running compute by the
second; the 1 GB persistent volume is billed continuously. Automatic HTTPS and
a shared public IP are included.

## Deploy and operate

Install and authenticate `flyctl`, create the application, and run:

```bash
./deploy.sh
```

The first deployment creates the `libre_closet_data` 1 GB volume in `iad` with
scheduled snapshots. Open the generated `https://APP.fly.dev` address, create
the first account with a strong unique password, and immediately disable new
registration:

```bash
fly secrets set DISABLE_REGISTRATION=true
```

Routine commands:

```bash
./update.sh
./backup.sh
fly status
fly logs
fly apps restart
```

`./backup.sh` creates an online-consistent SQLite copy, packages it with all
uploaded WebP images, and downloads the archive into `backups/`. Fly also takes
scheduled volume snapshots; list them with `fly volumes snapshots list VOLUME_ID`.

## Persistent state

- `/data/sqlite3.db`: users and wardrobe records
- `/data/*.webp`: uploaded and processed photos
- `/data/app.log`: application log

The volume survives Machine stops, restarts, and deployments. Keep occasional
downloaded backups outside Fly.io as protection against account or volume loss.

## iPhone

Open the HTTPS URL in Safari, sign in, then choose **Share → Add to Home Screen**.
`PWA_ENABLED=true` enables the manifest and service worker used by the installed
web app.
