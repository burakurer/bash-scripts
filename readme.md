# 🛠️ Burakurer Bash Scripts Collection

A collection of useful Bash scripts for Linux server management and maintenance.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

---

## 📦 Available Scripts

| Script | Description | Version |
|--------|-------------|---------|
| `bu-toolkit.sh` | Server Management Toolkit - System updates, package installation, cleanup, and more | v4.2.0 |
| `bu-clamav.sh` | ClamAV Antivirus Management - Install, scan, and manage ClamAV | v1.8.0 |
| `bu-benchmark.sh` | Disk I/O Performance Benchmark - Test and analyze disk performance | v2.4.0 |

### ✨ Auto-Update Feature

All scripts now include an **automatic update checker**. When you run a script, it will:
1. Check the latest version from GitHub
2. Prompt you to update if a newer version is available
3. Automatically download and restart with the new version

---

## 🚀 Quick Start

### Prerequisites

- Linux-based operating system (Ubuntu, Debian, CentOS, Rocky, AlmaLinux)
- Root or sudo access
- `wget` or `curl` installed

### 📥 One-Line Installer (Recommended)

Install all scripts with a single command:

```bash
# Interactive installer
curl -fsSL https://raw.githubusercontent.com/burakurer/bash-scripts/master/install.sh | bash

# Or with wget
wget -qO- https://raw.githubusercontent.com/burakurer/bash-scripts/master/install.sh | bash
```

**Install all scripts directly (non-interactive):**
```bash
curl -fsSL https://raw.githubusercontent.com/burakurer/bash-scripts/master/install.sh | bash -s -- --all
```

> **Note:** Scripts are downloaded to the current directory. Use `sudo` when running them if root access is needed.

### Individual Script Installation

#### bu-toolkit.sh (Server Management Toolkit)

```bash
wget -qO bu-toolkit.sh https://raw.githubusercontent.com/burakurer/bash-scripts/master/bu-toolkit.sh && chmod +x bu-toolkit.sh && sudo ./bu-toolkit.sh
```

#### bu-clamav.sh (ClamAV Management)

```bash
wget -qO bu-clamav.sh https://raw.githubusercontent.com/burakurer/bash-scripts/master/bu-clamav.sh && chmod +x bu-clamav.sh && sudo ./bu-clamav.sh
```

#### bu-benchmark.sh (Disk Benchmark)

```bash
wget -qO bu-benchmark.sh https://raw.githubusercontent.com/burakurer/bash-scripts/master/bu-benchmark.sh && chmod +x bu-benchmark.sh && ./bu-benchmark.sh
```

---

## 📖 Script Details

### 🧰 bu-toolkit.sh

A comprehensive server management toolkit with an interactive menu.

**Features:**
- 🔄 **Auto-Update** - Checks for updates on every run
- 📊 **System Information** - View detailed system stats (CPU, RAM, Disk, Network)
- 🔄 **System Updates** - Update and upgrade packages
- ⏰ **Time Sync** - Synchronize server time
- 📦 **Package Installation** - Install common packages, Node.js, Redis, Memcached
- 🖥️ **Plesk Management** - Install Plesk, manage backups, fix common errors
- 🧹 **Safe Disk Cleanup** - Clean caches, logs, and temp files safely

```
╔══════════════════════════════════════════════════════════════╗
║           BU-TOOLKIT v4.1.0                                  ║
║           Server Management Toolkit                          ║
╚══════════════════════════════════════════════════════════════╝

📊 System & Info
   [1]  System Information
   [2]  Check for system updates
   [3]  Synchronize server time

📦 Package Installation
   [4]  Install recommended packages
   [5]  Install Node.js (via NVM)
   [6]  Install Redis
   [7]  Install Memcached

🖥️  Plesk Panel
   [8]  Install Plesk
   [9]  Delete all Plesk backups
   [10] Fix Plesk cURL error 77

🧹 Maintenance
   [11] Safe Disk Cleanup

[0]  Exit
```

---

### 🛡️ bu-clamav.sh

Manage ClamAV antivirus with an easy-to-use interface. **Smart RAM detection** - automatically uses disk-only mode on systems with less than 4GB RAM.

**Features:**
- 🔄 **Auto-Update** - Checks for script updates on every run
- Install ClamAV automatically (with smart RAM detection)
- Update virus database
- Run system-wide or directory-specific scans
- Background scanning support
- Real-time scan progress monitoring
- View infected files report
- **RAM < 4GB**: Uses disk-only mode (no background RAM usage)
- **RAM >= 4GB**: Uses daemon mode (faster scans)

```
======================================
       ClamAV Scan Management         
======================================
 RAM: 8.0GB (>= 4GB)
 ● Mode: Daemon (fast, uses ~500MB RAM)
--------------------------------------
 0) Install ClamAV
 1) Start background system scan
 2) Scan a specific directory
 3) Show scan progress in real-time
 4) List infected files from latest scan
 5) Stop ongoing background scan
 6) Update ClamAV virus database
 7) Clear log files
 8) Start/Restart ClamAV daemon
 9) Exit
======================================
```

---

### 📈 bu-benchmark.sh

Comprehensive disk I/O performance benchmark tool.

**Features:**
- 🔄 **Auto-Update** - Checks for updates on every run
- 6 different I/O tests (sequential, random, sync, cached)
- System information display
- Performance scoring (0-100)
- Color-coded ratings
- Quick mode for faster testing
- Multiple iteration support

**Usage:**
```bash
./bu-benchmark.sh              # Run with defaults
./bu-benchmark.sh -q           # Quick mode
./bu-benchmark.sh -d /mnt/ssd  # Test specific directory
./bu-benchmark.sh -i 3         # Run 3 iterations per test
./bu-benchmark.sh -v           # Verbose output
```

**Sample Output:**
```
═══════════════════════════════════════════════════════════════
                        BENCHMARK RESULTS                        
═══════════════════════════════════════════════════════════════

Test   │ Description                              │        Speed │ Rating
───────┼──────────────────────────────────────────┼──────────────┼─────────────
1      │ Sequential Write (throughput)            │    452.00 MB/s │ Good
2      │ Small Sync Write (latency)               │      0.12 MB/s │ Fair
3      │ Typical Write (fdatasync)                │    677.00 MB/s │ Very Good
4      │ Mixed/Cached Write                       │    362.00 MB/s │ Good
5      │ Sequential Read                          │   1700.00 MB/s │ Excellent
6      │ Random I/O                               │      0.94 MB/s │ Fair

Overall Performance Score: 72.5/100
Overall Rating: Very Good
```

---

## 🖥️ Supported Operating Systems

| OS | Version | Status |
|----|---------|--------|
| Ubuntu | 20.04, 22.04, 24.04 | ✅ Fully Supported |
| Debian | 10, 11, 12 | ✅ Fully Supported |
| CentOS | 7, 8, 9 | ✅ Fully Supported |
| Rocky Linux | 8, 9 | ✅ Fully Supported |
| AlmaLinux | 8, 9 | ✅ Fully Supported |


---

## 👤 Author

**Burak Urer**
- Website: [burakurer.dev](https://burakurer.dev)
- GitHub: [@burakurer](https://github.com/burakurer)

---

## ⭐ Support

If you find these scripts helpful, please consider giving a star ⭐ to this repository!
