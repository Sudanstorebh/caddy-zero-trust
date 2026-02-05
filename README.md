# Caddy Auth Proxy

A lightweight Caddy-based authentication proxy that protects upstream services with Basic Auth. Designed to run behind a TLS-terminating edge (e.g., Railway, Cloudflare) and proxy to internal services.

## Use Case

Protect an internal service with basic authentication before exposing it publicly:

```
User (HTTPS) → Edge/PaaS (TLS) → Caddy (Basic Auth) → Internal Service
```

The upstream service has no public access. Caddy is the only entry point and enforces authentication.

## Features

- Basic Authentication via environment variables
- Automatic password hashing at startup (plain password in, bcrypt hash generated)
- Lightweight Alpine-based image
- Works behind TLS-terminating proxies (Railway, Cloudflare, etc.)

## Configuration

| Environment Variable | Description                          | Example                        | Required |
| -------------------- | ------------------------------------ | ------------------------------ | -------- |
| `AUTH_USER`          | Basic auth username                  | `admin`                        | Yes      |
| `AUTH_PASS`          | Plain text password (hashed at boot) | `mysecurepassword`             | Yes      |
| `UPSTREAM_URL`       | Backend service URL with port        | `http://backend.internal:5555` | Yes      |

## Usage

### Build

```bash
docker build -t caddy-auth-proxy .
```

### Run

```bash
docker run -d \
  -e AUTH_USER=admin \
  -e AUTH_PASS=mysecurepassword \
  -e UPSTREAM_URL=http://your-backend:8080 \
  -p 80:80 \
  caddy-auth-proxy
```

### Railway Deployment

1. Deploy this repo to Railway
2. Set environment variables: `AUTH_USER`, `AUTH_PASS`, `UPSTREAM_URL`
3. Add custom domain pointing to port 80
4. Caddy proxies authenticated requests to your internal service

## Files

- `Dockerfile` - Builds image with Python/bcrypt for password hashing
- `Caddyfile` - Caddy config with Basic Auth and reverse proxy
- `entrypoint.sh` - Hashes password at startup, then runs Caddy
- `site/` - Static files (optional)

## License

See [LICENSE](LICENSE) for details.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/caddy-auth-proxy?referralCode=5oF91f&utm_medium=integration&utm_source=template&utm_campaign=generic)
