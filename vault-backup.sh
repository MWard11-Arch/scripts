#!/usr/bin/env bash

# Arch Academic Command Center: 3-2-1 Backup Script
# Logic: 1. Snapper Snapshot (Local) -> 2. rclone Sync (Encrypted Cloud)

LOG_FILE="$HOME/.cache/academic-backup.log"
exec >> "$LOG_FILE" 2>&1

echo "--- Starting Academic Vault Backup: $(date) ---"

# PID check to prevent concurrent runs
PIDFILE="/tmp/academic-backup.pid"
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if ps -p "$PID" > /dev/null; then
        echo "Backup already running (PID: $PID). Exiting."
        exit 1
    fi
fi
echo $$ > "$PIDFILE"

# 1. Create Snapper Snapshot of /home
echo "[1/2] Creating Snapper snapshot..."
if snapper -c home create --description "Automated Academic Backup" --userdata "type=backup"; then
    echo "Snapper snapshot created successfully."
else
    echo "FAILED: Snapper snapshot creation."
fi

# 2. Sync Academic Vaults to Encrypted Cloud
echo "[2/2] Syncing to encrypted cloud vault..."

# Sync the main Academic Vault
rclone sync /vault/Academic_Vault secret_vault:Academic_Vault \
    --progress \
    --exclude ".stversions/**" \
    --fast-list

# Sync the Reports/Templates directory
rclone sync /vault/Academic secret_vault:Academic \
    --progress \
    --fast-list

rm "$PIDFILE"
echo "--- Backup Complete: $(date) ---"
echo ""
