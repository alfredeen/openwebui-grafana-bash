Grafana Dashboard for Open WebUI
===================

![alt tag](https://jorgedelacruz.uk/wp-content/uploads/2025/02/openwebui-grafana-001.jpg)

This project consists in a Bash Shell script to retrieve the  Open WebUI information, directly from the RESTfulAPI, about chats, messages and their stats. The information is being saved it into InfluxDB output directly into the InfluxDB database using curl, then in Grafana: a Dashboard is created to present all the information.

We use Open WebUI RESTfulAPI to reduce the workload and increase the speed of script execution. 

----------

## Local development

Copy the .env.example as .env
```bash
cp .env.example .env
```

Edit the values in the .env file. Some configuration options to note are:
* SCRAPE_INTERVAL_SECONDS: To control the frequency to request new stats from the Open WebUI host.
* DRY_RUN:  Set to true to run the scraper program without writing anything to the InfluxDB.

Run docker compose
```bash
docker compose up -d
```

## Tests

### Verify the setup

The InfluxDB service should respond:
```bash
curl -i http://localhost:8086/health
```

You should be able to login to InfluxDB:
http://localhost:8086/

### InfluxDB write test

Run test to verify write access to the InfluxDB:
```bash
chmod +x tests/ci_influx_verify.sh
```

Start InfluxDB, load .env vars and run the test script:
```bash
docker compose up -d influxdb

set -a
source .env
set +a

export INFLUX_URL="http://localhost:8086"

bash tests/ci_influx_verify.sh
```

Shutdown:
```bash
docker compose down -v
```


## Grafana dashboard

In Grafana, create a new dashboard from the JSON content in the file named "Grafana Dashboard for Open WebUI.json"


## Source attribution and history
This repository is originally based on https://github.com/jorgedlcruz/openwebui-grafana, now maintained independently.
