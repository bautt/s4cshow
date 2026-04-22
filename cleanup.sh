#!/bin/bash
# s4cshow cleanup script — removes all apps and configs deployed by ./show
# Logs to syslog + file; continues past individual failures.

APPS_DIR="/opt/splunk/etc/apps"
APPS_TO_REMOVE=(
    "splunk4champions2"
    "phyphox"
)

LOGFILE="/var/log/s4c.log"
ERRORS=0

# ---------------------------------------------------------------------------
# Logging — file + syslog
# ---------------------------------------------------------------------------

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
    logger -t s4cshow "$1"
}

log_error() {
    ERRORS=$((ERRORS + 1))
    log "ERROR: $1"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

log "Starting s4cshow cleanup (pid $$)"

for app in "${APPS_TO_REMOVE[@]}"; do
    app_path="${APPS_DIR}/${app}"
    if [ -d "$app_path" ]; then
        log "Removing $app_path"
        if rm -rf "$app_path" 2>>"$LOGFILE"; then
            log "Removed $app_path"
        else
            log_error "Failed to remove $app_path"
        fi
    else
        log "$app_path not found — already removed or never installed"
    fi
done

log "Restarting Splunk"
if systemctl restart Splunkd 2>>"$LOGFILE"; then
    log "Splunk restarted successfully"
else
    log_error "Splunk restart failed"
fi

if [ "$ERRORS" -gt 0 ]; then
    log "Cleanup completed with $ERRORS error(s)"
    exit 1
else
    log "Cleanup completed successfully"
    exit 0
fi
