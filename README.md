# Caddy Auth Proxy

Fork of [rubenszinho/caddy-zero-trust](https://github.com/rubenszinho/caddy-zero-trust) used by
[Sudanstorebh/mtgrsd](https://github.com/Sudanstorebh/mtgrsd) as the Railway
`caddy-auth-proxy` service in front of staging (`staging.mtgr-sd.com`).

```
Browser → Cloudflare → this proxy (basic auth, with PUBLIC_PATHS bypass)
                     → upstream (e.g. mtgrsd.railway.internal:3000)
```

The app’s raw `*.up.railway.app` origin stays **ungated** and is what external
monitors, QStash crons, and provider **webhooks** should keep using.

## Features

- Basic authentication via `AUTH_USER` / `AUTH_PASS` (bcrypt-hashed at boot)
- Optional **path exemptions** via `PUBLIC_PATHS` (comma-separated Caddy `path` matchers)
- `/api/health` is always public so container healthchecks work without credentials
- Accepts `UPSTREAM_URL` as `host:port` or full `http(s)://…` URL
- Designed to sit behind a TLS-terminating edge (Railway, Cloudflare)

## Configuration

| Variable | Required | Description |
| --- | --- | --- |
| `AUTH_USER` | yes | Basic-auth username |
| `AUTH_PASS` | yes | Plain password (hashed at boot into the in-memory Caddyfile) |
| `UPSTREAM_URL` | yes | Upstream `host:port` or URL |
| `PUBLIC_PATHS` | no | Comma-separated absolute path matchers skipped by basic auth |

### Recommended `PUBLIC_PATHS` for mtgrsd staging

Exempt Didit’s browser return URL **and** everything the SPA needs to render
and call the API without a second basic-auth prompt. App-level auth still
applies. Keep `/cron/*` gated here (QStash targets the ungated origin).

```
/kyc/callback,/kyc/callback/*,/assets/*,/api/*,/webhooks/*,/auth/*,/manifest.json,/sw.js,/favicon.ico,/robots.txt,/sitemap.xml
```

## Railway

1. Connect this repo as the service source (branch `main`, **empty** root directory).
2. Set `AUTH_USER`, `AUTH_PASS`, `UPSTREAM_URL`, and `PUBLIC_PATHS`.
3. Custom domain on port **80**.
4. After deploy:

```bash
curl -sS -o /dev/null -w "%{http_code}\n" https://<domain>/kyc/callback  # 200
curl -sS -o /dev/null -w "%{http_code}\n" https://<domain>/             # 401
curl -sS -o /dev/null -w "%{http_code}\n" https://<domain>/api/health   # 200
```

Then point `DIDIT_CALLBACK_URL` at `https://<domain>/kyc/callback`. Leave
`POST /webhooks/didit` on the ungated origin.

## Local run

```bash
docker build -t caddy-auth-proxy .
docker run --rm -p 8080:80 \
  -e AUTH_USER=dev -e AUTH_PASS=dev \
  -e UPSTREAM_URL=host.docker.internal:3000 \
  -e PUBLIC_PATHS='/kyc/callback,/assets/*,/api/*' \
  caddy-auth-proxy
```

## License

GPL-3.0 (inherited from upstream). See [LICENSE](LICENSE).
