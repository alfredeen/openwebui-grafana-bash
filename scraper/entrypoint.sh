#!/usr/bin/env bash
set -euo pipefail

: "${SCRAPE_INTERVAL_SECONDS:=60}"

echo "============================================================"
echo "[entrypoint] Starting scraper loop at $(date -Is)"
echo "[entrypoint] SCRAPE_INTERVAL_SECONDS=${SCRAPE_INTERVAL_SECONDS}"
echo "[entrypoint] DRY_RUN=${DRY_RUN:-false}"
echo "============================================================"

# Help influx CLI find InfluxDB
export INFLUX_URL="${INFLUX_URL:-${INFLUXDB_URL:-http://influxdb}:${INFLUXDB_PORT:-8086}}"
export INFLUX_HOST="${INFLUX_HOST:-${INFLUX_URL}}"

# state dir for persistent state of the lastrun timestamp
mkdir -p /state

while true; do
  echo "[scraper] $(date -Is) running..."
  /bin/bash /app/openwebui_grafana.sh || echo "[scraper] run failed"
  sleep "${SCRAPE_INTERVAL_SECONDS}"
done
