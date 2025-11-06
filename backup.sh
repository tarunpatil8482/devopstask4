#!/usr/bin/env bash
set -euo pipefail

CONFIG="./backup.config"

if [[ -f "$CONFIG" ]]; then
  source "$CONFIG"
else
  echo " Config file not found ($CONFIG)."
  exit 1
fi

# Make sure backup folder and logfile exist
mkdir -p "$BACKUP_DESTINATION"
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"

# ------------------------------
# Log Function
# ------------------------------
log() {
  local level=$1; shift
  echo "[$(date '+%F %T')] $level: $*" | tee -a "$LOGFILE"
}

# ------------------------------
# Create Backup Function
# ------------------------------
create_backup() {
  local src="$1"

  # Check if source folder exists
  if [[ ! -d "$src" ]]; then
    log "ERROR" "Source folder not found: $src"
    echo "Error: Folder does not exist!"
    exit 1
  fi

  TIMESTAMP=$(date +%Y-%m-%d-%H%M)
  BACKUP_FILE="backup-$TIMESTAMP.tar.gz"
  CHECKSUM_FILE="$BACKUP_FILE.sha256"

  log "INFO" "Starting backup of $src"

  # Create compressed archive, excluding unnecessary folders
  tar --exclude='.git' --exclude='node_modules' --exclude='.cache' \
      -czf "$BACKUP_DESTINATION/$BACKUP_FILE" -C "$(dirname "$src")" "$(basename "$src")"

  log "SUCCESS" "Backup created: $BACKUP_FILE"

  # Create checksum file
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

  # Run cleanup
  cleanup_old_backups
}

# ------------------------------
# Cleanup Function (Keep last 7)
# ------------------------------
cleanup_old_backups() {
  log "INFO" "Checking for old backups..."

  local backups=($(ls -1t "$BACKUP_DESTINATION"/backup-*.tar.gz 2>/dev/null || true))
  local total=${#backups[@]}

  if (( total <= DAILY_KEEP )); then
    log "INFO" "No old backups to delete. ($total total)"
    return
  fi

  local to_delete=$((total - DAILY_KEEP))
  log "INFO" "Found $total backups, keeping latest $DAILY_KEEP, deleting $to_delete old ones."

  for old_backup in "${backups[@]:$DAILY_KEEP}"; do
    rm -f "$old_backup" "${old_backup}.sha256"
    log "INFO" "Deleted old backup: $(basename "$old_backup")"
  done

  log "SUCCESS" "Old backup cleanup complete."
}

# ------------------------------
# Restore Function
# ------------------------------
restore_backup() {
  local backupfile="$1"
  local destination="$2"

  if [[ ! -f "$BACKUP_DESTINATION/$backupfile" ]]; then
    log "ERROR" "Backup file not found: $BACKUP_DESTINATION/$backupfile"
    echo "Error: Backup file not found!"
    exit 1
  fi

  mkdir -p "$destination"
  tar -xzf "$BACKUP_DESTINATION/$backupfile" -C "$destination"
  log "SUCCESS" "Restored $backupfile to $destination"
  echo " Restore completed!"
}

# ------------------------------
# Dry Run Mode (Optional)
# ------------------------------
dry_run() {
  echo " Dry Run Mode: Showing what will happen..."
  echo "Would back up: $1"
  echo "Would create compressed file: backup-$(date +%Y-%m-%d-%H%M).tar.gz"
  echo "Would keep last $DAILY_KEEP backups and delete older ones."
  echo "Would log all actions to: $LOGFILE"
}

# ------------------------------
# Main Menu
# ------------------------------
case "${1:-}" in
  backup)
    create_backup "${2:-test_data}"
    ;;
  restore)
    restore_backup "${2:-}" "${3:-restored_data}"
    ;;
  --dry-run)
    dry_run "${2:-test_data}"
    ;;
  *)
    echo "Usage:"
    echo "  ./backup.sh backup <source-folder>"
    echo "  ./backup.sh restore <backup-file> <restore-destination>"
    echo "  ./backup.sh --dry-run <source-folder>"
    ;;
esac
