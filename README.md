# VMs-de-projetos-pessoais
# 🧹 Linux Weekly Maintenance Script

This repository contains a **simple and efficient weekly maintenance script for Linux systems (Debian/Ubuntu)**.  
It was initially created for **personal project VMs**, but following **production-level best practices**.

Even in homelabs and personal projects, applying good practices from day one helps improve **performance, sustainability, organization**, and prepares environments for **real production scenarios**.

---

## ⚙️ What this script does

- Updates the operating system
- Fixes broken packages
- Removes unused packages and dependencies
- Cleans APT cache
- Cleans old `journald` logs
- Frees memory cache (RAM)
- Generates execution logs for auditing

---

## ⏰ Scheduling

The script is designed to run automatically:

- **Frequency:** Weekly  
- **Day:** Sunday  
- **Time:** 00:00 (midnight)  
- **Scheduler:** `cron`

This simulates a **real production environment**, avoiding impact during business hours.

---

## 📁 Suggested structure

```bash
/usr/local/bin/weekly_maintenance.sh
/var/log/weekly_maintenance.log
