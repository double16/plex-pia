#!/usr/bin/env bash

#
# Configure Plex remote access from VPN IP and PORT
#
# vars:
#   IP - Public IP address of the VPN connection
#   PORT - Public port provided by the VPN
#

if [[ -z "${IP}" ]]; then
    echo "IP missing" >&2
    exit 1
fi

if [[ -z "${PORT}" ]]; then
    echo "PORT missing" >&2
    exit 1
fi

if [[ -z "${PLEX_TOKEN}" ]] && [[ -s /config/plex-token.txt ]]; then
    PLEX_TOKEN="$(</config/plex-token.txt)"
fi

export CURL_OPTS="--verbose --retry 9 --retry-connrefused --retry-delay 10"

#curl ${CURL_OPTS} -X PUT "http://localhost:32400/:/prefs?customConnections=http%3A%2F%2F${IP}%3A${PORT}%2F&X-Plex-Token=${PLEX_TOKEN}"
curl ${CURL_OPTS} -X PUT "http://localhost:32400/:/prefs?ManualPortMappingMode=1&X-Plex-Token=${PLEX_TOKEN}"
curl ${CURL_OPTS} -X PUT "http://localhost:32400/:/prefs?ManualPortMappingPort=${PORT}&X-Plex-Token=${PLEX_TOKEN}"
