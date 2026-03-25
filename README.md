## iSantePlus ETL Scripts

ETL scripts that populate the `isanteplus` reporting database from the live `openmrs` database.

### Setup

1. Clone the repository:
```bash
git clone https://github.com/IsantePlus/etlscript
cd etlscript
```

2. Run the initial load (creates tables, runs full ETL, sets up cron):
```bash
./load.sh <mysql_user> <mysql_password> <mysql_host> <mysql_port>
```

Example:
```bash
./load.sh root Admin123 localhost 3306
```

This runs all 7 SQL scripts in sequence, then sets up cron jobs for the two incremental ETL scripts that need to run periodically.

**Note:** Requires `mysql` client and `flock` installed locally.

### What gets scheduled

After `load.sh` completes, two cron jobs run every 10 minutes:

| Script | Purpose |
|--------|---------|
| `insertion_obs_by_day.sql` | Incremental daily ETL — copies new obs, encounters, dispensing, lab results, ARV status |
| `indicators_report.sql` | Surveillance indicators — updates weekly monitoring report data |

Logs are written to `/var/log/isanteplus-etl/`. Each run is protected by `flock` to prevent overlapping executions.

### Managing cron jobs

```bash
# Check what's scheduled
crontab -l

# Set up cron jobs manually (if not run via load.sh)
./setup-cron.sh <mysql_user> <mysql_password> <mysql_host> <mysql_port>

# Remove cron jobs
./remove-cron.sh
```

### Scripts

| Script | Runs | Purpose |
|--------|------|---------|
| `isanteplusreportsddlscript.sql` | Once (initial) | Creates `isanteplus` database and reporting tables |
| `isanteplusreportsdmlscript.sql` | Once (initial) | Full ETL — populates all reporting tables from `openmrs` |
| `drug_lookup_isanteplus.sql` | Once (initial) | Loads drug reference data |
| `run_isante_patient_status.sql` | Once (initial) | Legacy iSante patient status migration |
| `insertion_obs_by_day.sql` | Every 10 min (cron) | Incremental daily ETL |
| `patient_status_arv_dml.sql` | Once (initial) | Patient ARV status and alerts |
| `indicators_report.sql` | Every 10 min (cron) | Surveillance indicator reports |

### Docker

If MySQL is running in Docker, pass the container's exposed host and port:

```bash
./load.sh root Admin123 127.0.0.1 3306
```

Or if using `docker exec` instead of TCP:

```bash
docker exec -i <mysql_container> mysql -uroot -pAdmin123 < sql_files/isanteplusreportsddlscript.sql
# ... repeat for each script
./setup-cron.sh root Admin123 127.0.0.1 3306
```
