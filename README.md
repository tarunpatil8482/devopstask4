**Automated Backup System**

**Project Overview**
This project is a bash script that helps you automatically take backups of your important folders.
It saves your data safely, creates a compressed .tar.gz file, and deletes old backups to save space.
You can also restore your files whenever needed.

How to Use ?
**Step 1 – Setup**

Keep all files in one folder:

backup-system/
├── backup.sh
├── backup.config
├── test_data/
└── backups/


Give permission to run the script:

chmod +x backup.sh


Open backup.config and check the settings. Example:

BACKUP_DESTINATION="./backups"
DAILY_KEEP=7
LOGFILE="$BACKUP_DESTINATION/backup.log"

**Step 2 – Take a Backup**

Run this command:

./backup.sh backup ./test_data


 This will:

Create a file like backup-2025-11-06-1500.tar.gz

Make a checksum file to check file safety

Save details in backup.log

Delete older backups automatically (keeps last 7 only)

**Step 3 – Restore a Backup**

To get your files back:

./backup.sh restore backup-2025-11-06-1500.tar.gz ./restored_data


Your backup will be extracted into the restored_data folder.

**Step 4 – Dry Run (Test Mode)**

To see what the script will do without making changes:

./backup.sh --dry-run ./test_data


It will show which files it would back up and which old ones it would delete.

 How It Works

The script compresses your folder into a .tar.gz file.

It creates a checksum file to check if the backup is safe.

It saves a record of every step in a log file.

It removes old backups, keeping only the most recent 7.

 Folder Structure
backup-system/
├── backup.sh
├── backup.config
├── backups/
│   ├── backup-2025-11-06-1500.tar.gz
│   ├── backup-2025-11-06-1500.tar.gz.sha256
│   └── backup.log
└── test_data/
    └── sample.txt

 Why It’s Useful

You don’t need to manually copy files every time.

Old backups are deleted automatically to save space.

Logs help you check what happened and when.

Restoring is easy and fast.

 Example Log
[2025-11-06 15:00:12] INFO: Starting backup of ./test_data
[2025-11-06 15:00:13] SUCCESS: Backup created: backup-2025-11-06-1500.tar.gz
[2025-11-06 15:00:13] INFO: Checksum file created: backup-2025-11-06-1500.tar.gz.sha256
[2025-11-06 15:00:13] SUCCESS: Checksum verified successfully
[2025-11-06 15:00:13] INFO: Deleted old backup: backup-2025-10-30-0910.tar.gz

 **Notes**

Make sure the folder you want to back up exists.

The script only keeps 7 latest backups.

Works on Linux or WSL (Windows Subsystem for Linux).

In Short

Run ./backup.sh backup <folder> to back up.

Run ./backup.sh restore <backup-file> <folder> to restore.

Backups are stored in backups/ with logs and checksums

