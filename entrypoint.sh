#!/bin/sh
# Generate a Caddyfile from env, then exec caddy.
# Required: AUTH_USER, AUTH_PASS, UPSTREAM_URL
# Optional: PUBLIC_PATHS — comma-separated absolute path matchers exempt from
#           basic auth (Caddy `path` syntax, e.g. /kyc/callback,/assets/*).
set -e

if [ -z "${AUTH_USER}" ] || [ -z "${AUTH_PASS}" ] || [ -z "${UPSTREAM_URL}" ]; then
  echo "caddy-auth-proxy: AUTH_USER, AUTH_PASS, and UPSTREAM_URL are required" >&2
  exit 1
fi

# Hash via env (not interpolated into python -c). Export so the Caddyfile can
# reference {$AUTH_PASS_HASH} — inlining $2a$… would be parsed as Caddy
# placeholders and corrupt the bcrypt hash.
export AUTH_PASS_HASH="$(
  AUTH_PASS="$AUTH_PASS" python3 - <<'PY'
import bcrypt, os
pw = os.environ["AUTH_PASS"].encode()
print(bcrypt.hashpw(pw, bcrypt.gensalt(rounds=10)).decode())
PY
)"

case "$UPSTREAM_URL" in
  http://*|https://*) UPSTREAM="$UPSTREAM_URL" ;;
  *) UPSTREAM="http://$UPSTREAM_URL" ;;
esac

# Build a single `path a b c` matcher line (OR semantics). Always include
# /api/health for container healthchecks without credentials.
PATH_ARGS="/api/health"
if [ -n "${PUBLIC_PATHS:-}" ]; then
  OLD_IFS=$IFS
  IFS=','
  for raw in $PUBLIC_PATHS; do
    p=$(printf '%s' "$raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$p" ] && continue
    case "$p" in
      /*) ;;
      *)
        echo "caddy-auth-proxy: PUBLIC_PATHS entry must start with /: $p" >&2
        exit 1
        ;;
    esac
    case "$p" in
      *[!A-Za-z0-9_./\*-]* | *" "* | *"'"* | *"\""* )
        echo "caddy-auth-proxy: PUBLIC_PATHS entry has unsupported characters: $p" >&2
        exit 1
        ;;
    esac
    # Skip duplicate of the always-public health path.
    [ "$p" = "/api/health" ] && continue
    PATH_ARGS="${PATH_ARGS} ${p}"
  done
  IFS=$OLD_IFS
fi

CONFIG_PATH="/tmp/Caddyfile"
cat > "$CONFIG_PATH" <<CADDY
:80 {
	@public path ${PATH_ARGS}

	handle @public {
		reverse_proxy ${UPSTREAM}
	}

	handle {
		basic_auth {
			{\$AUTH_USER} {\$AUTH_PASS_HASH}
		}
		reverse_proxy ${UPSTREAM}
	}
}
CADDY

echo "caddy-auth-proxy: starting (public paths: ${PUBLIC_PATHS:-<none>})"
exec caddy run --config "$CONFIG_PATH" --adapter caddyfile
