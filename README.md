## iSantePlus ETL Scripts

ETL scripts that populate the `isanteplus` reporting database from the live `openmrs` database.

### Setup

1. Clone the repository:
```bash
git clone https://github.com/IsantePlus/etlscript
cd etlscript
```

2. Run the initial load (creates tables, runs full ETL, sets up cron):

**Bare-metal MySQL:**
```bash
./load.sh <mysql_user> <mysql_password> <mysql_host> <mysql_port>
```

**Docker MySQL:**
```bash
./load.sh --docker <container_name> <mysql_user> <mysql_password>
```

Examples:
```bash
./load.sh root Admin123 localhost 3306
./load.sh --docker mysql_mysql.1 root Admin123
```

This runs all 7 SQL scripts in sequence, then sets up cron jobs for the two incremental ETL scripts that need to run periodically.

**Requirements:** `mysql` client, `flock`, and `docker` (if using Docker mode).

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

# Set up cron jobs manually (bare-metal)
./setup-cron.sh <mysql_user> <mysql_password> <mysql_host> <mysql_port>

# Set up cron jobs manually (Docker)
./setup-cron.sh --docker <container_name> <mysql_user> <mysql_password>

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
