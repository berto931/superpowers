# Postiz install

Install of [Postiz](https://github.com/gitroomhq/postiz-app) (open-source social
media scheduler) using its official Docker Compose stack.

## Usage

```bash
./setup.sh
```

Then open **http://localhost:4007** — the app redirects to `/auth` where you
register the first (admin) account.

## What it does

1. Clones `gitroomhq/postiz-app` (the official `docker-compose.yaml` lives in
   the repo root).
2. Writes a `docker-compose.override.yaml` that replaces the placeholder
   `JWT_SECRET` with a freshly generated random value. The upstream compose
   file is left untouched.
3. If the machine routes outbound TLS through an intercepting proxy with a CA
   bundle at `/root/.ccr/ca-bundle.crt` (as sandboxed agent environments do),
   the CA is mounted into the container and exposed via `NODE_EXTRA_CA_CERTS`.
   Without this, the container's boot-time `pnpm dlx prisma db push` fails with
   `self-signed certificate in certificate chain` when it fetches Prisma from
   the npm registry, and the container crash-loops.
4. Runs `docker compose up -d`, which starts:
   - `postiz` (frontend, backend, orchestrator under pm2; nginx on port 4007)
   - `postiz-postgres` (Postgres 17) and `postiz-redis` (Redis 7.2)
   - the Temporal workflow stack (`temporal`, `temporal-postgresql`,
     `temporal-elasticsearch`, `temporal-ui` on port 8080, admin tools)
   - `spotlight` (Sentry Spotlight debugging UI on port 8969)
5. Waits until the app responds on port 4007.

## Verified result (2026-07-30, sandboxed Linux container)

- All containers healthy; Prisma reported "Your database is now in sync with
  your Prisma schema".
- `pm2 ls` inside the container: `backend`, `frontend`, `orchestrator` all
  online.
- `http://localhost:4007/` → 307 → `/auth` → 200, page title "Postiz Register".

## Notes

- Social network posting requires provider API keys — set them in
  `docker-compose.override.yaml` (see the commented env vars in the upstream
  `docker-compose.yaml`).
- To stop: `docker compose down` (add `-v` to also delete the database
  volumes).
