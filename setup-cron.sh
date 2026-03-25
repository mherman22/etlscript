#!/bin/bash

set -e

usage() {
    echo "Usage:"
    echo "  Bare-metal:  ./setup-cron.sh <mysql_user> <mysql_password> <mysql_host> <mysql_port>"
    echo "  Docker:      ./setup-cron.sh --docker <container_name> <mysql_user> <mysql_password>"
    echo ""
    echo "Examples:"
    echo "  ./setup-cron.sh root Admin123 localhost 3306"
    echo "  ./setup-cron.sh --docker mysql_mysql.1 root Admin123"
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_DIR="${SCRIPT_DIR}/sql_files"
LOG_DIR="/var/log/isanteplus-etl"
CRON_ID="# isanteplus-etl"
DOCKER_MODE=false

if [ "$1" = "--docker" ]; then
    DOCKER_MODE=true
    container=$2
    user=$3
    pass=$4

    if [ -z "$container" ] || [ -z "$user" ] || [ -z "$pass" ]; then
        usage
    fi

    MYSQL_CMD="docker exec -i ${container} mysql -u${user} -p${pass}"
else
    user=$1
    pass=$2
    host=$3
    port=$4

    if [ -z "$user" ] || [ -z "$pass" ] || [ -z "$host" ] || [ -z "$port" ]; then
        usage
    fi

    MYSQL_CMD="mysql --protocol=tcp -h ${host} -P ${port} -u ${user} -p${pass}"
fi

echo "=== Setting up ETL cron jobs ==="
if [ "$DOCKER_MODE" = true ]; then
    echo "Mode: Docker (container: ${container})"
else
    echo "Mode: Bare-metal (host: ${host}:${port})"
fi

# Create log directory
mkdir -p "${LOG_DIR}" 2>/dev/null || sudo mkdir -p "${LOG_DIR}"

# Remove any existing isanteplus-etl cron entries
(crontab -l 2>/dev/null || true) | { grep -v "${CRON_ID}" || true; } | { grep -v "insertion_obs_by_day" || true; } | { grep -v "indicators_report" || true; } > /tmp/crontab_clean

# Add new cron entries
cat >> /tmp/crontab_clean << EOF
${CRON_ID} - insertion_obs_by_day (every 10 min)
*/10 * * * * flock -n /tmp/etl-obs.lock ${MYSQL_CMD} < ${SQL_DIR}/insertion_obs_by_day.sql >> ${LOG_DIR}/insertion_obs_by_day.log 2>&1
${CRON_ID} - indicators_report (every 10 min)
*/10 * * * * flock -n /tmp/etl-indicators.lock ${MYSQL_CMD} < ${SQL_DIR}/indicators_report.sql >> ${LOG_DIR}/indicators_report.log 2>&1
EOF

# Install the new crontab
crontab /tmp/crontab_clean
rm -f /tmp/crontab_clean

echo ""
echo "Cron jobs installed:"
echo "  - insertion_obs_by_day.sql   every 10 min"
echo "  - indicators_report.sql      every 10 min"
echo ""
echo "Logs: ${LOG_DIR}/"
echo "  - insertion_obs_by_day.log"
echo "  - indicators_report.log"
echo ""
echo "To check: crontab -l"
echo "To disable: ./remove-cron.sh"
echo ""
