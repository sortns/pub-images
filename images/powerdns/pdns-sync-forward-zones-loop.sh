#!/bin/sh
# Runs pdns_sync_forward_zones every 5 minutes under supervisord.
# An initial sync is attempted immediately on start; failures are logged but do not
# abort the loop so the recursor can still start with a stale/empty zone file.
set -u

ENV_FILE=/etc/pdns/pdns-sync-forward-zones.env
SCRIPT=/usr/local/sbin/pdns-sync-forward-zones
INTERVAL=${PDNS_SYNC_INTERVAL:-300}

while true; do
  python3 "$SCRIPT" --env-file "$ENV_FILE" || true
  sleep "$INTERVAL"
done
