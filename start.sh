#!/bin/sh

set -e
TS=`date "+%Y/%m/%d %H:%M:%S"`

CHOWN=$(/usr/bin/which chown)
SQUID=$(/usr/bin/which squid)

mkdir -p /var/spool/squid

# Ensure permissions are set correctly on the Squid cache + log dir.
"$CHOWN" -R squid:squid /var/spool/squid
"$CHOWN" -R squid:squid /var/cache/squid
"$CHOWN" -R squid:squid /var/log/squid

# create and prepate fd=3 as duplicate for stdout
exec 3>&1
chmod a+w /dev/fd/3

# Prepare the cache using Squid.
echo "$TS Initializing cache..."
"$SQUID" -z

echo "$TS Starting frp client, connecting to $SERVER_ADDR"
# start frpc
sh -c 'exec /app/frp/frpc -c /app/frp/frpc.toml' &

# Give the Squid cache some time to rebuild.
sleep 3

REMOTE_ADDR=$(curl -s http://localhost:7400/api/status | jq '.tcp[0]["remote_addr"]')
echo "$TS local squid proxy will be forwarded from $REMOTE_ADDR"

if [ -z "${PROXY_USER}" ]; then
  echo "$TS PROXY_USER environment variable was not set. Exiting."
  exit 1
fi
if [ -z "${PROXY_PASS}" ]; then
  echo "$TS PROXY_PASS environment variable was not set. Exiting."
fi

echo "$TS creating /etc/squid/passwords from environment PROXY_*"
htpasswd -cbm /etc/squid/passwords $PROXY_USER $PROXY_PASS


# Launch squid
echo "$TS Starting Squid..."
exec "$SQUID" -NYCd 1
