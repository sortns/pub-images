FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Base system packages
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    gettext-base \
    procps \
    iproute2 \
    netcat-openbsd \
    dnsutils \
    vim-tiny \
    python3 \
    supervisor \
 && rm -rf /var/lib/apt/lists/*

# PowerDNS repositories — auth-49 and rec-51 pinned to PowerDNS repo
# Note: PowerDNS repo suite names use no dots: auth-49, rec-51, etc.
RUN set -eux; \
    CODENAME=$(lsb_release -cs); \
    curl -fsSL https://repo.powerdns.com/FD380FBB-pub.asc \
      | gpg --dearmor -o /usr/share/keyrings/powerdns-archive-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/powerdns-archive-keyring.gpg] \
      http://repo.powerdns.com/debian ${CODENAME}-auth-49 main" \
      > /etc/apt/sources.list.d/pdns-auth.list; \
    echo "deb [signed-by=/usr/share/keyrings/powerdns-archive-keyring.gpg] \
      http://repo.powerdns.com/debian ${CODENAME}-rec-51 main" \
      > /etc/apt/sources.list.d/pdns-recursor.list; \
    printf 'Package: pdns-server pdns-backend-pgsql pdns-recursor\nPin: origin repo.powerdns.com\nPin-Priority: 600\n' \
      > /etc/apt/preferences.d/pdns; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      pdns-server \
      pdns-backend-pgsql \
      pdns-recursor; \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh                  /usr/local/bin/entrypoint.sh
COPY supervisor_tee.py             /usr/local/bin/supervisor_tee.py
COPY pdns.conf.template             /etc/powerdns/pdns.conf.template
COPY recursor.conf.template         /etc/powerdns/recursor.conf.template
COPY recursor.lua.template          /etc/powerdns/recursor.lua.template
COPY supervisord.conf               /etc/supervisor/supervisord.conf
COPY pdns_sync_forward_zones.py     /usr/local/sbin/pdns-sync-forward-zones
COPY pdns-sync-forward-zones-loop.sh /usr/local/sbin/pdns-sync-forward-zones-loop
COPY sync-forward-zones.env.template /etc/pdns/pdns-sync-forward-zones.env.template

RUN chmod +x \
      /usr/local/bin/entrypoint.sh \
      /usr/local/bin/supervisor_tee.py \
      /usr/local/sbin/pdns-sync-forward-zones \
      /usr/local/sbin/pdns-sync-forward-zones-loop

# 53   — DNS (recursor, user-facing)
# 8081 — pdns-server (auth) API/webserver
# 8082 — pdns-recursor API/webserver
# Port 5300 (auth internal) is NOT exposed — reachable only within the container by the recursor.
EXPOSE 53/udp 53/tcp 8081 8082

VOLUME ["/var/lib/powerdns", "/etc/powerdns"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# supervisord manages pdns_server (auth), pdns_recursor, and the zone-sync loop.
CMD ["supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
