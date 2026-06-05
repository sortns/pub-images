#!/bin/sh
set -eu

# ── Auth server defaults ──────────────────────────────────────────────────────
# Auth listens on 5300 (internal); recursor owns 53 (external / user-facing).
export PDNS_LAUNCH="${PDNS_LAUNCH:-gpgsql}"
export PDNS_LOCAL_ADDRESS="${PDNS_LOCAL_ADDRESS:-0.0.0.0}"
export PDNS_LOCAL_PORT="${PDNS_LOCAL_PORT:-5300}"
export PDNS_WEBSERVER_ADDRESS="${PDNS_WEBSERVER_ADDRESS:-0.0.0.0}"
export PDNS_WEBSERVER_PORT="${PDNS_WEBSERVER_PORT:-8081}"
export PDNS_WEBSERVER_ALLOW_FROM="${PDNS_WEBSERVER_ALLOW_FROM:-127.0.0.1,::1}"
export PDNS_WEBSERVER_PASSWORD="${PDNS_WEBSERVER_PASSWORD:-}"
export PDNS_API_KEY="${PDNS_API_KEY:-}"
export PDNS_GPGSQL_HOST="${PDNS_GPGSQL_HOST:-db}"
export PDNS_GPGSQL_PORT="${PDNS_GPGSQL_PORT:-5432}"
export PDNS_GPGSQL_USER="${PDNS_GPGSQL_USER:-pdns}"
export PDNS_GPGSQL_PASSWORD="${PDNS_GPGSQL_PASSWORD:-pdns}"
export PDNS_GPGSQL_DBNAME="${PDNS_GPGSQL_DBNAME:-pdns}"
export PDNS_GPGSQL_PREPARED_STATEMENTS="${PDNS_GPGSQL_PREPARED_STATEMENTS:-no}"
export PDNS_ALLOW_AXFR_IPS="${PDNS_ALLOW_AXFR_IPS:-127.0.0.1}"
export PDNS_ALLOW_NOTIFY_FROM="${PDNS_ALLOW_NOTIFY_FROM:-}"
export PDNS_CACHE_TTL="${PDNS_CACHE_TTL:-60}"
export PDNS_NEGQUERY_CACHE_TTL="${PDNS_NEGQUERY_CACHE_TTL:-60}"
export PDNS_QUERY_CACHE_TTL="${PDNS_QUERY_CACHE_TTL:-20}"
export PDNS_LOGLEVEL="${PDNS_LOGLEVEL:-4}"
export PDNS_LOG_DNS_QUERIES="${PDNS_LOG_DNS_QUERIES:-no}"

# ── Auth address/port exposed to recursor and sync script ─────────────────────
export PDNS_AUTH_LOCAL_ADDRESS="${PDNS_AUTH_LOCAL_ADDRESS:-127.0.0.1}"
export PDNS_AUTH_LOCAL_PORT="${PDNS_AUTH_LOCAL_PORT:-${PDNS_LOCAL_PORT}}"

# ── Recursor defaults ─────────────────────────────────────────────────────────
export PDNS_RECURSOR_LOCAL_ADDRESS="${PDNS_RECURSOR_LOCAL_ADDRESS:-0.0.0.0}"
export PDNS_RECURSOR_LOCAL_PORT="${PDNS_RECURSOR_LOCAL_PORT:-53}"
export PDNS_RECURSOR_ALLOW_FROM="${PDNS_RECURSOR_ALLOW_FROM:-0.0.0.0/0}"
export PDNS_RECURSOR_FORWARD_ZONES_FILE="${PDNS_RECURSOR_FORWARD_ZONES_FILE:-/etc/powerdns/forward-zones.yml}"
export PDNS_RECURSOR_NTA_LUA_FILE="${PDNS_RECURSOR_NTA_LUA_FILE:-/etc/powerdns/forward-zones-ntas.lua}"
export PDNS_RECURSOR_LUA_CONFIG_FILE="${PDNS_RECURSOR_LUA_CONFIG_FILE:-/etc/powerdns/recursor.lua}"
export PDNS_RECURSOR_UPSTREAM_RESOLVER_1="${PDNS_RECURSOR_UPSTREAM_RESOLVER_1:-8.8.8.8}"
export PDNS_RECURSOR_UPSTREAM_RESOLVER_2="${PDNS_RECURSOR_UPSTREAM_RESOLVER_2:-77.88.8.8}"
export PDNS_RECURSOR_THREADS="${PDNS_RECURSOR_THREADS:-2}"
export PDNS_RECURSOR_MAX_CACHE_TTL="${PDNS_RECURSOR_MAX_CACHE_TTL:-300}"
export PDNS_RECURSOR_MAX_NEGATIVE_TTL="${PDNS_RECURSOR_MAX_NEGATIVE_TTL:-60}"
export PDNS_RECURSOR_SERVE_STALE_EXTENSIONS="${PDNS_RECURSOR_SERVE_STALE_EXTENSIONS:-2880}"
export PDNS_RECURSOR_LOG_LEVEL="${PDNS_RECURSOR_LOG_LEVEL:-4}"
export PDNS_RECURSOR_WEBSERVER_ENABLED="${PDNS_RECURSOR_WEBSERVER_ENABLED:-false}"
export PDNS_RECURSOR_WEBSERVER_ADDRESS="${PDNS_RECURSOR_WEBSERVER_ADDRESS:-0.0.0.0}"
export PDNS_RECURSOR_WEBSERVER_PORT="${PDNS_RECURSOR_WEBSERVER_PORT:-8082}"
export PDNS_RECURSOR_WEBSERVER_ALLOW_FROM="${PDNS_RECURSOR_WEBSERVER_ALLOW_FROM:-0.0.0.0/0}"
export PDNS_RECURSOR_WEBSERVER_PASSWORD="${PDNS_RECURSOR_WEBSERVER_PASSWORD:-}"
export PDNS_RECURSOR_API_KEY="${PDNS_RECURSOR_API_KEY:-}"

# ── RPZ — database-backed via auth server, no local files ────────────────────
export PDNS_RECURSOR_RPZ_PRIMARY="${PDNS_RECURSOR_RPZ_PRIMARY:-${PDNS_AUTH_LOCAL_ADDRESS}:${PDNS_AUTH_LOCAL_PORT}}"
export PDNS_RECURSOR_RPZ_ZONE_NAME="${PDNS_RECURSOR_RPZ_ZONE_NAME:-rpz}"
export PDNS_RECURSOR_RPZ_REFRESH="${PDNS_RECURSOR_RPZ_REFRESH:-60}"

# ── Zone-sync defaults (forward zones pulled from auth API every 5 min) ───────
export PDNS_SYNC_API_URL="${PDNS_SYNC_API_URL:-http://${PDNS_AUTH_LOCAL_ADDRESS}:${PDNS_WEBSERVER_PORT}/api/v1}"
export PDNS_SYNC_SERVER_ID="${PDNS_SYNC_SERVER_ID:-localhost}"
export PDNS_SYNC_STATE_FILE="${PDNS_SYNC_STATE_FILE:-/var/lib/pdns-recursor/forward-zones.last.yml}"
export PDNS_SYNC_INTERVAL="${PDNS_SYNC_INTERVAL:-300}"
export PDNS_SYNC_EXCLUDE_ZONES="${PDNS_SYNC_EXCLUDE_ZONES:-rpz}"
export PDNS_SYNC_EXCLUDE_ZONE_PREFIXES="${PDNS_SYNC_EXCLUDE_ZONE_PREFIXES:-rpz.}"
export PDNS_SUPERVISOR_FILE_LOGGING="${PDNS_SUPERVISOR_FILE_LOGGING:-false}"
export PDNS_SUPERVISOR_LOG_DIR="${PDNS_SUPERVISOR_LOG_DIR:-/var/log/supervisor}"

build_rpz_lua() {
  zones_csv=$1
  primary=$2
  refresh=$3
  first=1

  printf '%s' "$zones_csv" | tr ',' '\n' | while IFS= read -r raw_zone; do
    zone=$(printf '%s' "$raw_zone" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -z "$zone" ]; then
      continue
    fi
    if [ $first -eq 0 ]; then
      printf '\n'
    fi
    first=0
    cat <<EOF
rpzPrimary(
  {"$primary"},
  "$zone",
  {refresh=$refresh}
)
EOF
  done
}

PDNS_RECURSOR_RPZ_LUA=$(build_rpz_lua \
  "$PDNS_RECURSOR_RPZ_ZONE_NAME" \
  "$PDNS_RECURSOR_RPZ_PRIMARY" \
  "$PDNS_RECURSOR_RPZ_REFRESH")
export PDNS_RECURSOR_RPZ_LUA

# ── Create runtime directories ────────────────────────────────────────────────
if [ "$PDNS_SUPERVISOR_LOG_DIR" != "/var/log/supervisor" ]; then
  mkdir -p "$PDNS_SUPERVISOR_LOG_DIR"
  rm -rf /var/log/supervisor
  ln -s "$PDNS_SUPERVISOR_LOG_DIR" /var/log/supervisor
fi

mkdir -p /var/lib/powerdns \
         /var/lib/pdns-recursor \
         /var/run/pdns-recursor \
         "$PDNS_SUPERVISOR_LOG_DIR" \
         /etc/powerdns/pdns.d \
         /etc/pdns

# Recursor exits hard if its generated include files are missing at boot.
# Seed empty placeholders so the first sync can happen after both daemons start.
: > "$PDNS_RECURSOR_FORWARD_ZONES_FILE"
: > "$PDNS_RECURSOR_NTA_LUA_FILE"
chmod 0640 "$PDNS_RECURSOR_FORWARD_ZONES_FILE" "$PDNS_RECURSOR_NTA_LUA_FILE"

# ── Render configs from templates ─────────────────────────────────────────────
envsubst < /etc/powerdns/pdns.conf.template               > /etc/powerdns/pdns.conf
envsubst < /etc/powerdns/recursor.conf.template           > /etc/powerdns/recursor.conf
envsubst < /etc/powerdns/recursor.lua.template            > /etc/powerdns/recursor.lua
envsubst < /etc/pdns/pdns-sync-forward-zones.env.template > /etc/pdns/pdns-sync-forward-zones.env

exec "$@"
