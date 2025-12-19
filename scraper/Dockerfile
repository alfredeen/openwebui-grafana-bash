FROM influxdb:2.7

RUN apt-get update \
  && apt-get install -y --no-install-recommends bash curl jq gettext-base \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY openwebui_grafana.sh /app/openwebui_grafana.sh
COPY scraper/entrypoint.sh /app/entrypoint.sh

ENTRYPOINT ["/bin/bash","-lc","/app/entrypoint.sh"]
