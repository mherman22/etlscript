#!/bin/bash

usage() {
    echo "Usage:"
    echo "  Bare-metal:  ./load.sh <mysql_user> <mysql_password> <mysql_host> <mysql_port>"
    echo "  Docker:      ./load.sh --docker <container_name> <mysql_user> <mysql_password>"
    echo ""
    echo "Examples:"
    echo "  ./load.sh root Admin123 localhost 3306"
    echo "  ./load.sh --docker mysql_mysql.1 root Admin123"
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_DIR="${SCRIPT_DIR}/sql_files"
DOCKER_MODE=false
CRON_ARGS=""

if [ "$1" = "--docker" ]; then
    DOCKER_MODE=true
    container=$2
    user=$3
    pass=$4

    if [ -z "$container" ] || [ -z "$user" ] || [ -z "$pass" ]; then
        usage
    fi

    MYSQL_CMD="docker exec -i ${container} mysql -u${user} -p${pass}"
    CRON_ARGS="--docker ${container} ${user} ${pass}"
else
    user=$1
    pass=$2
    host=$3
    port=$4

    if [ -z "$user" ] || [ -z "$pass" ] || [ -z "$host" ] || [ -z "$port" ]; then
        usage
    fi

    MYSQL_CMD="mysql --protocol=tcp -h ${host} -P ${port} -u ${user} -p${pass}"
    CRON_ARGS="${user} ${pass} ${host} ${port}"
fi

echo "=== iSantePlus ETL: Initial Load ==="
echo ""

echo "[1/7] Creating reporting tables (DDL)..."
${MYSQL_CMD} < "${SQL_DIR}/isanteplusreportsddlscript.sql"

echo "[2/7] Running main reports ETL (DML)..."
${MYSQL_CMD} < "${SQL_DIR}/isanteplusreportsdmlscript.sql"

echo "[3/7] Loading drug lookup data..."
${MYSQL_CMD} < "${SQL_DIR}/drug_lookup_isanteplus.sql"

echo "[4/7] Running iSante patient status migration..."
${MYSQL_CMD} < "${SQL_DIR}/run_isante_patient_status.sql"

echo "[5/7] Running daily incremental ETL..."
${MYSQL_CMD} < "${SQL_DIR}/insertion_obs_by_day.sql"

echo "[6/7] Running patient ARV status calculations..."
${MYSQL_CMD} < "${SQL_DIR}/patient_status_arv_dml.sql"

echo "[7/7] Running surveillance indicators..."
${MYSQL_CMD} < "${SQL_DIR}/indicators_report.sql"

echo ""
echo "=== Initial load complete ==="
echo ""

# Set up cron jobs for incremental ETL
"${SCRIPT_DIR}/setup-cron.sh" ${CRON_ARGS}
