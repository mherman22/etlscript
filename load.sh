#!/bin/bash

set -e

user=$1
pass=$2
host=$3
port=$4

if [ -z "$user" ] || [ -z "$pass" ] || [ -z "$host" ] || [ -z "$port" ]; then
    echo "Usage: ./load.sh <mysql_user> <mysql_password> <mysql_host> <mysql_port>"
    exit 1
fi

MYSQL_CMD="mysql --protocol=tcp -h ${host} -P ${port} -u ${user} -p${pass}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_DIR="${SCRIPT_DIR}/sql_files"

echo "=== iSantePlus ETL: Initial Load ==="
echo ""

echo "[1/7] Creating reporting tables (DDL)..."
$MYSQL_CMD < "${SQL_DIR}/isanteplusreportsddlscript.sql"

echo "[2/7] Running main reports ETL (DML)..."
$MYSQL_CMD < "${SQL_DIR}/isanteplusreportsdmlscript.sql"

echo "[3/7] Loading drug lookup data..."
$MYSQL_CMD < "${SQL_DIR}/drug_lookup_isanteplus.sql"

echo "[4/7] Running iSante patient status migration..."
$MYSQL_CMD < "${SQL_DIR}/run_isante_patient_status.sql"

echo "[5/7] Running daily incremental ETL..."
$MYSQL_CMD < "${SQL_DIR}/insertion_obs_by_day.sql"

echo "[6/7] Running patient ARV status calculations..."
$MYSQL_CMD < "${SQL_DIR}/patient_status_arv_dml.sql"

echo "[7/7] Running surveillance indicators..."
$MYSQL_CMD < "${SQL_DIR}/indicators_report.sql"

echo ""
echo "=== Initial load complete ==="
echo ""

# Set up cron jobs for incremental ETL
"${SCRIPT_DIR}/setup-cron.sh" "$user" "$pass" "$host" "$port"
