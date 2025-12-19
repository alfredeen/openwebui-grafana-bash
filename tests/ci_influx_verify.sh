#!/usr/bin/env bash
set -euo pipefail

: "${INFLUX_URL:?missing INFLUX_URL (e.g. http://localhost:8086)}"
: "${INFLUXDB_TOKEN:?missing INFLUXDB_TOKEN}"
: "${INFLUXDB_ORG:?missing INFLUXDB_ORG}"
: "${INFLUXDB_BUCKET:?missing INFLUXDB_BUCKET}"

MEAS="ci_smoke"
TS="$(date +%s)"

echo "Waiting for InfluxDB..."
for i in $(seq 1 60); do
  if curl -fsS "${INFLUX_URL}/health" >/dev/null; then
    break
  fi
  sleep 2
done

echo "Writing a test point..."
LINE="${MEAS},source=github_actions value=1 ${TS}"
curl -fsS -X POST "${INFLUX_URL}/api/v2/write?org=${INFLUXDB_ORG}&bucket=${INFLUXDB_BUCKET}&precision=s" \
  -H "Authorization: Token ${INFLUXDB_TOKEN}" \
  --data-binary "${LINE}" >/dev/null

echo "Querying back the point..."
QUERY="from(bucket: \"${INFLUXDB_BUCKET}\") |> range(start: -5m) |> filter(fn: (r) => r._measurement == \"${MEAS}\") |> last()"
RESP="$(curl -fsS -X POST "${INFLUX_URL}/api/v2/query?org=${INFLUXDB_ORG}" \
  -H "Authorization: Token ${INFLUXDB_TOKEN}" \
  -H "Content-Type: application/vnd.flux" \
  --data-binary "${QUERY}")"

echo "${RESP}" | grep -q "${MEAS}" || { echo "Did not find measurement ${MEAS} in query response"; exit 1; }

echo "InfluxDB write+query OK"
