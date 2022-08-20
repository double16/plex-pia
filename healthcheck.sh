#!/usr/bin/env bash

PORT="$(piactl get portforward)"
if [[ "${PORT}" =~ [0-9][0-9][0-9][0-9] ]]; then
  exit 0
fi

if [[ "${PORT}" == "Attempting" ]]; then
  exit 0
fi

piactl get connectionstate

exit 1
