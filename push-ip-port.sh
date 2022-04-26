#!/usr/bin/env bash

set -x

#
# Pushes the current VPN IP and port in case it got lost when the target service restarted, etc.
#

export IP="$(piactl get vpnip | grep '[0-9]')"
if [[ -z "${IP}" ]]; then
    echo "IP not available"
    exit 0
fi

export PORT="$(piactl get portforward | grep '[0-9]')"
if [[ -z "${PORT}" ]]; then
    echo "Port not available"
    exit 0
fi

/usr/local/bin/return-route.sh
bash -x /usr/local/bin/plex-configure.sh
