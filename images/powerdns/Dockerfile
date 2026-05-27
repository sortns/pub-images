FROM debian:bookworm-slim

ARG PDNS_RELEASE=auth-4.8
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    gettext-base \
    procps \
    iproute2 \
    netcat \
    dnsutils \
    vim-tiny \
    supervisor \
 && rm -rf /var/lib/apt/lists/*

# Add official PowerDNS APT repository (authoritative server)
RUN set -eux; \
    CODENAME=$(lsb_release -cs); \
    curl -fsSL https://repo.powerdns.com/FD380FBB-pub.asc | gpg --dearmor -o /usr/share/keyrings/powerdns-archive-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/powerdns-archive-keyring.gpg] http://repo.powerdns.com/debian ${CODENAME}-${PDNS_RELEASE} main" \
      > /etc/apt/sources.list.d/powerdns.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends pdns-server pdns-backend-pgsql pdns-recursor; \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY pdns.conf.template /etc/powerdns/pdns.conf.template
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 53/udp 53/tcp 8081

VOLUME ["/var/lib/powerdns", "/etc/powerdns"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]



CMD ["pdns_server", "--daemon=no"]
