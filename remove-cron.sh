#!/bin/bash

CRON_ID="# isanteplus-etl"

echo "=== Removing ETL cron jobs ==="

(crontab -l 2>/dev/null || true) | grep -v "${CRON_ID}" | grep -v "insertion_obs_by_day" | grep -v "indicators_report" | crontab -

echo "Done. Cron jobs removed."
echo "To verify: crontab -l"
