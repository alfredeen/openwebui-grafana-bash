#!/usr/bin/env sh
set -eu

: "${SCRAPE_INTERVAL_SECONDS:=60}"

export INFLUX_HOST="${INFLUXDB_URL}:${INFLUXDB_PORT:-8086}"
export INFLUX_URL="${INFLUXDB_URL}:${INFLUXDB_PORT:-8086}"


while true; do
  echo "[scraper] running at $(date -Is)"
  /bin/bash /app/openwebui_grafana.sh || echo "[scraper] run failed"
  sleep "$SCRAPE_INTERVAL_SECONDS"
done
