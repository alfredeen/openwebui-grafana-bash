FROM influxdb:2.7

RUN apt-get update \
  && apt-get install -y --no-install-recommends bash curl jq \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY scraper/openwebui_grafana.sh /app/openwebui_grafana.sh
COPY scraper/entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh /app/openwebui_grafana.sh

ENTRYPOINT ["/bin/bash","-lc","/app/entrypoint.sh"]
