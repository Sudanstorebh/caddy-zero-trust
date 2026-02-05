FROM caddy:alpine

# Install Python and bcrypt for password hashing
RUN apk add --no-cache python3 py3-pip && \
    pip3 install --break-system-packages bcrypt

COPY ./site/ /srv/
COPY ./Caddyfile /etc/caddy/Caddyfile
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
