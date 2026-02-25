#!/bin/bash

# ------------------------------
# CONFIGURATION
# ------------------------------
set -e
set -u
set -o pipefail

if [ -z "$SLACK_WEBHOOK_URL" ]; then
    echo "Error: SLACK_WEBHOOK_URL not set."
    exit 1
fi


if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
    echo "Error: SLACK_WEBHOOK_URL not set."
    exit 1
fi


if [ "$#" -ne 0 ] && [ "$#" -ne 3 ]; then
    echo "Usage: $0 [CPU_THRESHOLD MEM_THRESHOLD DISK_THRESHOLD]"
    exit 1
fi

CPU_THRESHOLD=${1:-80}
MEM_THRESHOLD=${2:-80}
DISK_THRESHOLD=${3:-80}

validate_number() {
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: Thresholds must be numeric values."
        exit 1
    fi
}

validate_number "$CPU_THRESHOLD"
validate_number "$MEM_THRESHOLD"
validate_number "$DISK_THRESHOLD"

LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/server_health.log"

# ------------------------------
# SETUP
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ------------------------------

# Create logs directory if not exists


# Get timestamp


# ------------------------------
# FUNCTIONS
# ------------------------------

check_cpu() {
 local timestamp
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
 CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d. -f1)

    echo "$TIMESTAMP - CPU Usage: $CPU_USAGE%" >> "$LOG_FILE"

    if [ "$CPU_USAGE" -gt "$CPU_THRESHOLD" ]; then
        echo "$TIMESTAMP - WARNING: CPU usage exceeded threshold!" >> "$LOG_FILE"
        EXIT_STATUS=1
    fi
}


check_memory() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    MEM_USAGE=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100}')

    echo "$TIMESTAMP - Memory Usage: $MEM_USAGE%" >> "$LOG_FILE"

    if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
        echo "$TIMESTAMP - WARNING: Memory usage exceeded threshold!" >> "$LOG_FILE"
        EXIT_STATUS=1
    fi
}


check_disk() {
    local timestamp
     timestamp=$(date '+%Y-%m-%d %H:%M:%S')

     DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | cut -d'%' -f1)

    echo "$TIMESTAMP - Disk Usage: $DISK_USAGE%" >> "$LOG_FILE"

    if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
        echo "$TIMESTAMP - WARNING: Disk usage exceeded threshold!" >> "$LOG_FILE"
        EXIT_STATUS=1
    fi
}

send_slack_alert() {
    local message="$1"

    curl -s -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$message\"}" \
        "$SLACK_WEBHOOK_URL" > /dev/null

    if [ $? -ne 0 ]; then
        echo "Warning: Failed to send Slack alert."
    fi
}


# ------------------------------
# MAIN
# ------------------------------

while true; do

    EXIT_STATUS=0

    check_cpu
    check_memory
    check_disk

    echo "System Health Summary"
    echo "----------------------"
    echo "CPU Usage: $CPU_USAGE%"
    echo "Memory Usage: $MEM_USAGE%"
    echo "Disk Usage: $DISK_USAGE%"
    echo "Exit Status: $EXIT_STATUS"
    
   date +%s > /tmp/last_check

    if [ "$EXIT_STATUS" -ne 0 ]; then
        ALERT_MESSAGE="🚨 Server Health Alert!
CPU: $CPU_USAGE%
Memory: $MEM_USAGE%
Disk: $DISK_USAGE%
Thresholds -> CPU:$CPU_THRESHOLD MEM:$MEM_THRESHOLD DISK:$DISK_THRESHOLD"

        send_slack_alert "$ALERT_MESSAGE"
    fi

    echo "Waiting 5 minutes before next check..."
    sleep 300

done

