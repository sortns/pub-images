PowerDNS Authoritative Docker image

This image provides a lightweight PowerDNS Authoritative server based on Debian packages.

Usage

Build (use upstream PowerDNS packages):

```bash
# Example: choose upstream release branch via build-arg (default: auth-4.8)
docker build --build-arg PDNS_RELEASE=auth-4.8 -t pub-images/powerdns:latest images/powerdns
```

Run example (connects to external PostgreSQL):

```bash
docker run -d --name pdns \
  -e PDNS_GPGSQL_HOST=pg.example.local \
  -e PDNS_GPGSQL_PORT=5432 \
  -e PDNS_GPGSQL_USER=pdns \
  -e PDNS_GPGSQL_PASSWORD=secret \
  -e PDNS_GPGSQL_DBNAME=pdns \
  -e PDNS_API_KEY=changeme \
  -p 53:53/udp -p 53:53/tcp -p 8081:8081 \
  pub-images/powerdns:latest
```

Environment variables

- `PDNS_LAUNCH` (default `gpgsql`) — backend to launch
- `PDNS_API` (default `yes`) — enable API
- `PDNS_API_KEY` — API key for remote management
- `PDNS_GPGSQL_HOST` — PostgreSQL host
- `PDNS_GPGSQL_PORT` — PostgreSQL port
- `PDNS_GPGSQL_USER` — PostgreSQL user
- `PDNS_GPGSQL_PASSWORD` — PostgreSQL password
- `PDNS_GPGSQL_DBNAME` — PostgreSQL database name
- `PDNS_ALLOW_AXFR_IPS` — AXFR allowed IPs
- `PDNS_LOCAL_ADDRESS` — bind address for DNS
- `PDNS_LOGLEVEL` — logging level
- `PDNS_WEBSERVER` — enable webserver/api
- `PDNS_WEBSERVER_ADDRESS` — API bind address
- `PDNS_WEBSERVER_PORT` — API port

Additional Ansible defaults supported as environment variables

- `PDNS_API_ALLOW_FROM` — API allow-from list (comma-separated)
- `PDNS_LOCAL_PORT` — local DNS listen port (default 53)
- `PDNS_ALLOW_NOTIFY_FROM` — allow-notify-from list
- `PDNS_GPGSQL_PREPARED_STATEMENTS` — enable prepared statements for gpgsql backend (`yes`/`no`)
- `PDNS_CACHE_TTL` — cache TTL (default 60)
- `PDNS_NEGQUERY_CACHE_TTL` — negative query cache TTL (default 60)
- `PDNS_QUERY_CACHE_TTL` — query cache TTL (default 20)
- `PDNS_LOG_DNS_QUERIES` — log DNS queries (`yes`/`no`)
- `PDNS_EXTRA_OPTS` — raw extra config lines appended to `pdns.conf`

Recursor environment variables

- `PDNS_RECURSOR_LOCAL_ADDRESS` — recursor bind address (default `0.0.0.0`)
- `PDNS_RECURSOR_LOCAL_PORT` — recursor listen port (default `53`)
- `PDNS_RECURSOR_UPSTREAM_RESOLVERS` — comma-separated upstream resolvers (default `8.8.8.8,77.88.8.8`)
- `PDNS_RECURSOR_FORWARD_ZONES_FILE` — path to forward-zones file (default `/etc/powerdns/forward-zones.yml`)
- `PDNS_RECURSOR_RPZ_ENABLED` — enable RPZ handling (`yes`/`no`)
- `PDNS_RECURSOR_RPZ_ZONE_NAME` — RPZ zone name (default `rpz`)
- `PDNS_RECURSOR_RPZ_PRIMARY_ADDRESSES` — primary addresses for RPZ pulls (comma-separated)
- `PDNS_RECURSOR_SERVE_EXPIRED_TTL` — serve-expired ttl
- `PDNS_RECURSOR_MAX_CACHE_TTL` — max cache ttl
- `PDNS_RECURSOR_MAX_NEGATIVE_TTL` — max negative ttl
- `PDNS_RECURSOR_THREADS` — recursor thread count
- `PDNS_RECURSOR_WEB_ENABLED` — enable recursor webserver/API
- `PDNS_RECURSOR_WEB_ADDRESS` — recursor webserver bind address
- `PDNS_RECURSOR_WEB_PORT` — recursor webserver port
- `PDNS_RECURSOR_EXTRA_OPTS` — raw extra config lines appended to `recursor.conf`

Run recursor

To run the recursor instead of the authoritative server, run:

```bash
docker run --rm -it \
  -e PDNS_RECURSOR_UPSTREAM_RESOLVERS=8.8.8.8,1.1.1.1 \
  pub-images/powerdns:latest pdns_recursor --config-dir=/etc/powerdns --socket-dir=%t/pdns-recursor --daemon=no --write-pid=no --disable-syslog
```



Notes

- This image is suitable for running multiple PowerDNS instances connecting to a single PostgreSQL database. Ensure your PostgreSQL and PowerDNS schema are initialized according to PowerDNS documentation.
- The image now installs PowerDNS from the official PowerDNS APT repository by default when built. Use the `PDNS_RELEASE` build-arg to pick the release branch (for example `auth-4.8`, `auth-4.9`, etc.).

