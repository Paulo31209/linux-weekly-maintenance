#!/usr/bin/env bash
#
# weekly_maintenance.sh
# Weekly maintenance for Debian/Ubuntu servers and VMs.
#
# Install:  sudo install -m 0755 weekly_maintenance.sh /usr/local/bin/weekly_maintenance.sh
# Cron:     0 0 * * 0 /usr/local/bin/weekly_maintenance.sh
#
# Environment overrides:
#   LOG_FILE             log file path            (default: /var/log/weekly_maintenance.log)
#   JOURNAL_RETENTION    journald retention       (default: 14d)
#   DROP_CACHES          free page cache at end   (default: true)

set -Eeuo pipefail

LOG_FILE="${LOG_FILE:-/var/log/weekly_maintenance.log}"
JOURNAL_RETENTION="${JOURNAL_RETENTION:-14d}"
DROP_CACHES="${DROP_CACHES:-true}"
LOCK_FILE="/var/lock/weekly_maintenance.lock"

export DEBIAN_FRONTEND=noninteractive
APT_OPTS=(-y -q -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)

log() {
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" | tee -a "$LOG_FILE"
}

on_error() {
  log "ERROR" "Failed at line $1 (exit code $2). Check $LOG_FILE."
}
trap 'on_error $LINENO $?' ERR

step() {
  local description="$1"; shift
  log "INFO" "$description"
  "$@" >>"$LOG_FILE" 2>&1
}

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "apt-get not found: this script supports Debian/Ubuntu only." >&2
  exit 1
fi

# Prevent overlapping runs
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "Another maintenance run is in progress." >&2
  exit 1
fi

START=$(date +%s)
DISK_BEFORE=$(df --output=used -B1M / | tail -n1 | tr -d ' ')

log "INFO" "===== Weekly maintenance started on $(hostname) ====="

step "Updating package index"            apt-get update -q
step "Upgrading installed packages"      apt-get upgrade "${APT_OPTS[@]}"
step "Configuring pending packages"      dpkg --configure -a
step "Fixing broken dependencies"        apt-get install -f "${APT_OPTS[@]}"
step "Removing unused packages"          apt-get autoremove --purge "${APT_OPTS[@]}"
step "Cleaning APT cache"                apt-get clean

if command -v journalctl >/dev/null 2>&1; then
  step "Vacuuming journald logs older than $JOURNAL_RETENTION" journalctl --vacuum-time="$JOURNAL_RETENTION"
fi

if [[ "$DROP_CACHES" == "true" ]]; then
  log "INFO" "Freeing page cache"
  sync
  echo 1 > /proc/sys/vm/drop_caches
fi

DISK_AFTER=$(df --output=used -B1M / | tail -n1 | tr -d ' ')
log "INFO" "Disk space freed on /: $((DISK_BEFORE - DISK_AFTER)) MB"

if [[ -f /var/run/reboot-required ]]; then
  log "WARN" "A reboot is required to finish applying updates."
fi

log "INFO" "===== Finished in $(( $(date +%s) - START ))s ====="
