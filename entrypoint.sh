#!/bin/sh
set -e

# Generate bcrypt hash from plain password
AUTH_PASS_HASH=$(python3 -c "import bcrypt; print(bcrypt.hashpw(b'$AUTH_PASS', bcrypt.gensalt(rounds=10)).decode())")

# Export for Caddy
export AUTH_PASS_HASH

# Start Caddy
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
