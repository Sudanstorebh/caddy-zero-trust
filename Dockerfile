FROM caddy:2-alpine

# Python + bcrypt so entrypoint can hash AUTH_PASS at boot (plain secret in env,
# bcrypt hash only ever lives in the generated Caddyfile inside the container).
RUN apk add --no-cache python3 py3-pip \
 && pip3 install --break-system-packages bcrypt

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
