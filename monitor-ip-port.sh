#!/usr/bin/env bash

set -x

finish() {
    [[ -n "${VIPIP_PID}" ]] && kill ${VIPIP_PID}
    [[ -n "${PORT_PID}" ]] && kill ${PORT_PID}
    pkill -f "piactl monitor vpnip"
    pkill -f "piactl monitor portforward"
    rm -f /var/run/vpnipport /var/run/vpnip /var/run/vpnport
}
trap finish EXIT

rm -f /var/run/vpnipport
mkfifo /var/run/vpnipport

(
    piactl monitor vpnip | grep --line-buffered '[0-9]' | while read IP; do
        echo "${IP}" > /var/run/vpnip
        if [[ -s /var/run/vpnport ]]; then
            echo "${IP}:$(</var/run/vpnport)" > /var/run/vpnipport
        fi
    done
) &
VIPIP_PID=$!

(
    piactl monitor portforward | while read PORT; do
        if [[ "${PORT}" = 'Failed' ]]; then
          # reconnect to get port forward
          piactl disconnect
          sleep 10m
          piactl connect
        elif [[ "${PORT}" =~ ^[0-9]+$ ]]; then
          echo "${PORT}" > /var/run/vpnport
          if [[ -s /var/run/vpnip ]]; then
              echo "$(</var/run/vpnip):${PORT}" > /var/run/vpnipport
          fi
        fi
    done
) &
PORT_PID=$!

while read IP_PORT < /var/run/vpnipport; do
    export IP="$(echo $IP_PORT | cut -d : -f 1)"
    export PORT="$(echo $IP_PORT | cut -d : -f 2)"
    echo "Configuring Plex to http://${IP}:${PORT}" >&2
    pkill socat
    while ! pgrep -f "socat TCP-LISTEN:${PORT},"; do
        socat TCP-LISTEN:${PORT},fork TCP4:localhost:32400 &
        sleep 2s
    done
    /usr/local/bin/return-route.sh
    bash -x /usr/local/bin/plex-configure.sh
done
