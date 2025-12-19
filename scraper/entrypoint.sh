#!/usr/bin/env bash
set -euo pipefail

: "${SCRAPE_INTERVAL_SECONDS:=60}"

# Help influx CLI find InfluxDB
export INFLUX_HOST="${INFLUX_HOST:-${INFLUXDB_URL#http://}:${INFLUXDB_PORT:-8086}}"
export INFLUX_URL="${INFLUX_URL:-${INFLUXDB_URL:-http://influxdb}:${INFLUXDB_PORT:-8086}}"

# state dir for persistent state of the lastrun timestamp
mkdir -p /state

while true; do
  echo "[scraper] $(date -Is) running..."
  /bin/bash /app/openwebui_grafana.sh || echo "[scraper] run failed"
  sleep "${SCRAPE_INTERVAL_SECONDS}"
done
