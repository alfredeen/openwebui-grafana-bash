#!/bin/bash

##      .SYNOPSIS
##      Grafana Dashboard for Open WebUI
##
##      .DESCRIPTION
##      This script queries Open WebUI API, fetches new chat data, extracts relevant stats,
##      and sends them to InfluxDB for visualization in Grafana.
##
##      .Notes
##      NAME:  openwebui_grafana.sh
##      LASTEDIT: 2025-12-22
##      VERSION: 2.0
##      KEYWORDS: Open WebUI, AI, InfluxDB, Grafana
##
##      .Link
##      Based on the work of https://github.com/jorgedlcruz/openwebui-grafana

# Parse dry-run mode
DRY_RUN="${DRY_RUN:-false}"

# CLI flag overrides env
if [[ "$DRY_RUN" != "true" && "$cli_dry_run" == "true" ]]; then
  DRY_RUN=true
fi

# Open WebUI Configuration
webuiAPIBaseURL="${WEBUI_API_BASE_URL:-http://YOUROPENWEBUIIPORFQDN:8080}"
webuiEmail="${WEBUI_EMAIL:-YOURADMINUSER}"
webuiPassword="${WEBUI_PASSWORD:-YOURPASS}"

# InfluxDB Configuration
veeamInfluxDBBucket="${INFLUXDB_BUCKET:-openwebui}"
veeamInfluxDBToken="${INFLUXDB_TOKEN:-TOKEN}"
veeamInfluxDBOrg="${INFLUXDB_ORG:-openwebui}"

# File to store last execution timestamp
lastRunFile="lastrun.txt"

echo "============================================================"
echo "[openwebui-scraper] Starting at $(date -Is)"
echo "------------------------------------------------------------"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[mode] DRY-RUN enabled — no data will be written to InfluxDB"
fi

echo "[config] Open WebUI API base URL : ${webuiAPIBaseURL}"
echo "[config] Open WebUI user        : ${webuiEmail}"

echo "[config] InfluxDB org           : ${veeamInfluxDBOrg}"
echo "[config] InfluxDB bucket        : ${veeamInfluxDBBucket}"
echo "[config] InfluxDB host          : ${INFLUX_HOST}"
echo "[config] InfluxDB write endpoint: ${INFLUX_URL}"

echo "[config] Last-run state file    : ${lastRunFile}"

# Load last execution timestamp
if [[ -f "$lastRunFile" ]]; then
    lastRunTime=$(cat "$lastRunFile")
else
    lastRunTime=0
fi

echo "Last execution timestamp: $lastRunTime"
echo "------------------------------------------------------------"

: "${WEBUI_API_BASE_URL:?WEBUI_API_BASE_URL is not set}"
: "${WEBUI_EMAIL:?WEBUI_EMAIL is not set}"
: "${WEBUI_PASSWORD:?WEBUI_PASSWORD is not set}"

: "${INFLUXDB_BUCKET:?INFLUXDB_BUCKET is not set}"
: "${INFLUXDB_ORG:?INFLUXDB_ORG is not set}"
: "${INFLUXDB_TOKEN:?INFLUXDB_TOKEN is not set}"
echo "------------------------------------------------------------"

# Authenticate with Open WebUI
authResponse=$(curl -s -X POST "$webuiAPIBaseURL/api/v1/auths/signin" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$webuiEmail\", \"password\": \"$webuiPassword\"}")

# Extract token
webuiToken=$(echo "$authResponse" | jq -r '.token')

if [[ -z "$webuiToken" || "$webuiToken" == "null" ]]; then
    echo "Authentication failed. Check credentials."
    exit 1
fi

echo "Successfully authenticated."

# Fetch all chat sessions
chatsJSON=$(curl -s -X GET "$webuiAPIBaseURL/api/v1/chats/" \
    -H "Authorization: Bearer $webuiToken")

# **Filter chats where updated_at > lastRunTime**
filteredChats=$(echo "$chatsJSON" | jq -c --argjson lastRun "$lastRunTime" '[.[] | select(.updated_at > $lastRun)]')

# **If no new chats, exit**
if [[ "$filteredChats" == "[]" || -z "$filteredChats" ]]; then
    echo "No new or updated chats found."
    echo "Updating timestamp."
    date +"%s" > "$lastRunFile"
    exit 0
fi

# **Sort chats by updated_at to process them in order**
sortedChats=$(echo "$filteredChats" | jq -c 'sort_by(.updated_at)')

# Function to convert "0h1m11s" format to milliseconds
convert_time_to_ms() {
    local time_str="$1"
    local hours=$(echo "$time_str" | grep -oP '\d+(?=h)' || echo "0")
    local minutes=$(echo "$time_str" | grep -oP '\d+(?=m)' || echo "0")
    local seconds=$(echo "$time_str" | grep -oP '\d+(?=s)' || echo "0")
    echo $(( (hours * 3600 + minutes * 60 + seconds) * 1000 ))
}

# **Initialize latest timestamp variable**
latestUpdatedAt=$lastRunTime

# **Iterate through new chats only**
echo "$sortedChats" | jq -c '.[]' | while read -r chat; do
    chatID=$(echo "$chat" | jq -r '.id')
    chatUpdatedAt=$(echo "$chat" | jq -r '.updated_at')

    echo "Processing updated chat: $chatID (updated at $chatUpdatedAt)"

    # Fetch chat details
    chatDetails=$(curl -s -X GET "$webuiAPIBaseURL/api/v1/chats/$chatID" \
        -H "Authorization: Bearer $webuiToken")

    # Extract messages array
    messageIDs=($(echo "$chatDetails" | jq -r '.chat.history.messages | keys[]'))

    for messageID in "${messageIDs[@]}"; do
        echo "Processing message: $messageID"

        # Extract message-specific details
        usage=$(echo "$chatDetails" | jq ".chat.history.messages.\"$messageID\".usage")
        modelUsed=$(echo "$chatDetails" | jq -r ".chat.history.messages.\"$messageID\".model" | grep -v null | awk '{gsub(/([ :,])/,"_");print}')
        responseTokens=$(echo "$usage" | jq -r '."response_token/s" // 0')
        promptTokens=$(echo "$usage" | jq -r '."prompt_token/s" // 0')
        totalDuration=$(echo "$usage" | jq -r '.total_duration // 0')
        loadDuration=$(echo "$usage" | jq -r '.load_duration // 0')
        promptEvalCount=$(echo "$usage" | jq -r '.prompt_eval_count // 0')
        promptEvalDuration=$(echo "$usage" | jq -r '.prompt_eval_duration // 0')
        evalCount=$(echo "$usage" | jq -r '.eval_count // 0')
        evalDuration=$(echo "$usage" | jq -r '.eval_duration // 0')

        # Extract and convert approximate_total to milliseconds
        approximateTotal=$(echo "$usage" | jq -r '.approximate_total // "0h0m0s"')
        approximateTotalMS=$(convert_time_to_ms "$approximateTotal")

        # **Extract original timestamp from message**
        messageTimestamp=$(echo "$chatDetails" | jq -r ".chat.history.messages.\"$messageID\".timestamp")

        # Ensure all extracted values are valid
        responseTokens=${responseTokens:-0}
        promptTokens=${promptTokens:-0}
        totalDuration=${totalDuration:-0}
        loadDuration=${loadDuration:-0}
        promptEvalCount=${promptEvalCount:-0}
        promptEvalDuration=${promptEvalDuration:-0}
        evalCount=${evalCount:-0}
        evalDuration=${evalDuration:-0}
        approximateTotalMS=${approximateTotalMS:-0}
        modelUsed=${modelUsed:-"unknown"}

        echo "Extracted Stats - Chat: $chatID | Message: $messageID | Model: $modelUsed | responseTokens: $responseTokens | promptTokens: $promptTokens | duration: $totalDuration ms | loadDuration: $loadDuration ms | promptEvalCount: $promptEvalCount | promptEvalDuration: $promptEvalDuration ms | evalCount: $evalCount | evalDuration: $evalDuration ms | approximateTotalMS: $approximateTotalMS ms | messageTimestamp: $messageTimestamp"

        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[dry-run] Would write to InfluxDB:"
            echo "[dry-run] bucket=${veeamInfluxDBBucket} org=${veeamInfluxDBOrg}"
            echo "[dry-run] Completed one iteration; exiting."
            exit 0
        fi

        # **Send data to InfluxDB using message timestamp**
        if influx write \
            -t "$veeamInfluxDBToken" \
            -b "$veeamInfluxDBBucket" \
            -o "$veeamInfluxDBOrg" \
            -p s \
            "openwebui_stats,chatID=$chatID,messageID=$messageID,model=$modelUsed responseTokens=$responseTokens,promptTokens=$promptTokens,totalDuration=$totalDuration,loadDuration=$loadDuration,promptEvalCount=$promptEvalCount,promptEvalDuration=$promptEvalDuration,evalCount=$evalCount,evalDuration=$evalDuration,approximateTotalMS=$approximateTotalMS $messageTimestamp";
        then
            echo "Data sent to InfluxDB."
        else
            echo "ERROR: failed to send data to InfluxDB" >&2
        fi
    done

    # **Ensure latest timestamp is updated**
    if (( chatUpdatedAt > latestUpdatedAt )); then
        latestUpdatedAt=$chatUpdatedAt
    fi
done

echo "Updating timestamp."
date +"%s" > "$lastRunFile"

echo "Script execution completed."