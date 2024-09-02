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

if [ -z "${PROXY_USER}" ]; then
  echo "PROXY_USER environment variable was not set. Exiting."
  exit 1
fi
if [ -z "${PROXY_PASS}" ]; then
  echo "PROXY_PASS environment variable was not set. Exiting."
fi

echo "creating /etc/squid/passwords from environment PROXY_*"
htpasswd -cbm /etc/squid/passwords $PROXY_USER $PROXY_PASS


# Launch squid
echo "Starting Squid..."
exec "$SQUID" -NYCd 1
