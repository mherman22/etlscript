#!/bin/bash

set -e

user=$1
pass=$2
host=$3
port=$4

if [ -z "$user" ] || [ -z "$pass" ] || [ -z "$host" ] || [ -z "$port" ]; then
    echo "Usage: ./setup-cron.sh <mysql_user> <mysql_password> <mysql_host> <mysql_port>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_DIR="${SCRIPT_DIR}/sql_files"
LOG_DIR="/var/log/isanteplus-etl"
CRON_ID="# isanteplus-etl"

MYSQL_CMD="mysql --protocol=tcp -h ${host} -P ${port} -u ${user} -p${pass}"

echo "=== Setting up ETL cron jobs ==="

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
