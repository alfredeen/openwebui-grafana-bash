Grafana Dashboard for Open WebUI
===================

![alt tag](https://jorgedelacruz.uk/wp-content/uploads/2025/02/openwebui-grafana-001.jpg)

This project consists in a Bash Shell script to retrieve the  Open WebUI information, directly from the RESTfulAPI, about chats, messages and their stats. The information is being saved it into InfluxDB output directly into the InfluxDB database using curl, then in Grafana: a Dashboard is created to present all the information.

We use Open WebUI RESTfulAPI to reduce the workload and increase the speed of script execution. 

----------



## History
This repository is originally based on https://github.com/jorgedlcruz/openwebui-grafana, now maintained independently.

### Original setup instructions

#### Getting started
You can follow the steps on the next Blog Post - https://jorgedelacruz.uk/2025/02/15/looking-for-the-perfect-dashboard-influxdb-telegraf-and-grafana-part-xlvii-monitoring-open-webui/

Or try with this simple steps:
* Download the openwebui_grafana.sh file and change the parameters under Configuration, like username/password, etc. with your real data
* Make the script executable with the command chmod +x openwebui_grafana.sh
* Run the openwebui_grafana.sh and check on InfluxDB UI that you can retrieve the information properly
* Schedule the script execution, for example every 30 minutes using crontab
* Download the Open WebUI Grafana dashboard JSON file and import it into your Grafana
* Enjoy :)
