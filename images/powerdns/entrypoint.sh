#!/bin/sh
set -eu

# Render pdns.conf from template using environment variables
if [ -f /etc/powerdns/pdns.conf.template ]; then
  envsubst < /etc/powerdns/pdns.conf.template > /etc/powerdns/pdns.conf
fi

## Ensure directories exist
mkdir -p /var/lib/powerdns
mkdir -p /etc/powerdns/pdns.d

# If drop-in directory exists and contains conf fragments, leave them in place.
chown -R root:root /etc/powerdns || true

# If PDNS_API_ALLOW_FROM is provided as a comma-separated list, convert to newline/appropriate form
# (PowerDNS accepts commas/semicolons depending on option; we pass through value as-is)

## Render recursor config if template exists
if [ -f /etc/powerdns/recursor.conf.template ]; then
  envsubst < /etc/powerdns/recursor.conf.template > /etc/powerdns/recursor.conf
fi

# Ensure recursor directories exist
mkdir -p /var/lib/pdns-recursor

exec "$@"
