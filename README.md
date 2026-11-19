# 🧹 Linux Weekly Maintenance Script

[![CI](https://github.com/Paulo31209/linux-weekly-maintenance/actions/workflows/ci.yml/badge.svg)](https://github.com/Paulo31209/linux-weekly-maintenance/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-A81D33?style=flat-square&logo=debian&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=flat-square&logo=ubuntu&logoColor=white)

A **simple and efficient weekly maintenance script for Linux systems (Debian/Ubuntu)**.
It was initially created for **personal project VMs**, but follows **production-level best practices**.

Even in homelabs and personal projects, applying good practices from day one helps improve **performance, sustainability and organization**, and prepares environments for **real production scenarios**.

---

## ⚙️ What the script does

- Updates the operating system (`apt-get update` + `upgrade`)
- Fixes broken packages (`dpkg --configure -a`, `apt-get install -f`)
- Removes unused packages and dependencies (`autoremove --purge`)
- Cleans the APT cache
- Cleans old `journald` logs (default retention: 14 days)
- Frees the page cache (RAM)
- Writes a timestamped execution log for auditing
- Reports disk space freed and whether a reboot is required

## 🛡️ Safety features

- `set -Eeuo pipefail` with an error trap that logs the failing line
- Runs only as root and only on systems with `apt-get`
- `flock` lock file to prevent overlapping runs
- Non-interactive upgrades that keep existing config files (`--force-confold`)

---

## 🚀 Installation

```bash
git clone https://github.com/Paulo31209/linux-weekly-maintenance.git
cd linux-weekly-maintenance
sudo install -m 0755 weekly_maintenance.sh /usr/local/bin/weekly_maintenance.sh
```

Run it manually once to validate:

```bash
sudo /usr/local/bin/weekly_maintenance.sh
sudo tail -n 30 /var/log/weekly_maintenance.log
```

## ⏰ Scheduling (cron)

Runs **every Sunday at 00:00**, outside business hours, simulating a real production maintenance window.

```bash
sudo crontab -e
```

```cron
0 0 * * 0 /usr/local/bin/weekly_maintenance.sh
```

## 🔧 Configuration

Override defaults with environment variables:

| Variable | Default | Description |
|---|---|---|
| `LOG_FILE` | `/var/log/weekly_maintenance.log` | Log file path |
| `JOURNAL_RETENTION` | `14d` | How long to keep `journald` logs |
| `DROP_CACHES` | `true` | Free the page cache at the end |

Example:

```cron
0 0 * * 0 JOURNAL_RETENTION=30d DROP_CACHES=false /usr/local/bin/weekly_maintenance.sh
```

## 📁 Structure

```text
/usr/local/bin/weekly_maintenance.sh   # script
/var/log/weekly_maintenance.log        # execution log
```

## 📄 Sample log

```text
2026-11-22 00:00:01 [INFO] ===== Weekly maintenance started on vm-lab-01 =====
2026-11-22 00:00:01 [INFO] Updating package index
2026-11-22 00:00:09 [INFO] Upgrading installed packages
2026-11-22 00:01:12 [INFO] Removing unused packages
2026-11-22 00:01:15 [INFO] Vacuuming journald logs older than 14d
2026-11-22 00:01:16 [INFO] Disk space freed on /: 412 MB
2026-11-22 00:01:16 [INFO] ===== Finished in 75s =====
```
