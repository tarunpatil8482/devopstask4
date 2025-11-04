#!/usr/bin/env bash
set -euo pipefail

# -----------------------
# Simple Backup Script
# -----------------------

# Load config file
CONFIG="./backup.config"
if [[ -f "$CONFIG" ]]; then
  source "$CONFIG"
else
  echo " Config file not found ($CONFIG). Exiting."
  exit 1
fi

# Create backup destination folder if it doesn't exist
mkdir -p "$BACKUP_DESTINATION"
: "${LOGFILE:=$BACKUP_DESTINATION/backup.log}"

# Function to log messages
log() {
  local level=$1; shift
  echo "[$(date '+%F %T')] $level: $*" | tee -a "$LOGFILE"
}

# Function to create a backup
create_backup() {
  local src="$1"

  if [[ ! -d "$src" ]]; then
    echo " Error: Source folder not found: $src"
    exit 1
  fi

  TIMESTAMP=$(date +%Y-%m-%d-%H%M)
  BACKUP_FILE="backup-$TIMESTAMP.tar.gz"
  CHECKSUM_FILE="$BACKUP_FILE.sha256"

  log "INFO" "Starting backup of $src"

  # Create archive
  tar -czf "$BACKUP_DESTINATION/$BACKUP_FILE" -C "$(dirname "$src")" "$(basename "$src")"
  log "SUCCESS" "Backup created: $BACKUP_FILE"

  # Create checksum
  (cd "$BACKUP_DESTINATION" && sha256sum "$BACKUP_FILE" > "$CHECKSUM_FILE")
  log "INFO" "Checksum file created: $CHECKSUM_FILE"

  # Verify checksum
  if (cd "$BACKUP_DESTINATION" && sha256sum -c "$CHECKSUM_FILE" >/dev/null 2>&1); then
    log "SUCCESS" "Checksum verified successfully for $BACKUP_FILE"
    echo " Backup successful!"
  else
    log "ERROR" "Checksum verification failed for $BACKUP_FILE"
    echo " Backup failed!"
    exit 1
  fi
}

# Function to restore a backup
restore_backup() {
  local backupfile="$1"
  local destination="$2"

  if [[ ! -f "$BACKUP_DESTINATION/$backupfile" ]]; then
    echo " Error: Backup file not found: $BACKUP_DESTINATION/$backupfile"
    exit 1
  fi

  mkdir -p "$destination"
  tar -xzf "$BACKUP_DESTINATION/$backupfile" -C "$destination"
  log "INFO" "Restored $backupfile to $destination"
  echo " Restore completed!"
}

# --------------------------
# Main menu
# --------------------------
case "${1:-}" in
  backup)
    create_backup "${2:-test_data}"
    ;;
  restore)
    restore_backup "${2:-}" "${3:-restored_data}"
    ;;
  *)
    echo "Usage:"
    echo "  ./backup.sh backup <source-folder>"
    echo "  ./backup.sh restore <backup-file> <restore-destination>"
    ;;
esac
