#!/bin/sh

set -e

CHOWN=$(/usr/bin/which chown)
SQUID=$(/usr/bin/which squid)

mkdir /var/spool/squid

# Ensure permissions are set correctly on the Squid cache + log dir.
"$CHOWN" -R squid:squid /var/spool/squid
"$CHOWN" -R squid:squid /var/cache/squid
"$CHOWN" -R squid:squid /var/log/squid

# Prepare the cache using Squid.
echo "Initializing cache..."
"$SQUID" -z

# start frpc
sh -c 'exec /app/frp/frpc -c /app/frp/frpc.toml' &

# Give the Squid cache some time to rebuild.
sleep 3

REMOTE_ADDR=$(curl -s http://localhost:7400/api/status | jq '.tcp[0]["remote_addr"]')
echo "local squid proxy will be forwarded from $REMOTE_ADDR"

# Launch squid
echo "Starting Squid..."
exec "$SQUID" -NYCd 1
