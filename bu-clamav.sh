#!/bin/bash

#######################################################
#                                                     #
#     Author      : burakurer.dev                     #
#     Script      : bu-clamav.sh                      #
#     Description : ClamAV Antivirus Management Tool  #
#     Version     : 2.4.1                             #
#     Last Update : 03/12/2025                        #
#     Website     : https://burakurer.dev             #
#     Github      : https://github.com/burakurer      #
#                                                     #
#######################################################

set -uo pipefail
IFS=$'\n\t'

# ------------------------ Colors ------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# ------------------------ Script Info ------------------------
SCRIPT_VERSION="2.4.1"
SCRIPT_NAME="bu-clamav.sh"
GITHUB_RAW_URL="https://raw.githubusercontent.com/burakurer/bash-scripts/master"

# ------------------------ Root Check ------------------------
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Please run the script as root.${NC}"
    exit 1
fi

# ------------------------ Auto Update ------------------------
check_for_updates() {
    local remote_version
    local current_script="$0"
    
    echo -e "${CYAN}Checking for updates...${NC}"
    
    # Fetch remote version
    if command -v curl &>/dev/null; then
        remote_version=$(curl -fsSL --connect-timeout 5 "${GITHUB_RAW_URL}/${SCRIPT_NAME}" 2>/dev/null | grep -m1 "SCRIPT_VERSION=" | cut -d'"' -f2)
    elif command -v wget &>/dev/null; then
        remote_version=$(wget -qO- --timeout=5 "${GITHUB_RAW_URL}/${SCRIPT_NAME}" 2>/dev/null | grep -m1 "SCRIPT_VERSION=" | cut -d'"' -f2)
    else
        echo -e "${YELLOW}Warning: curl or wget not found. Skipping update check.${NC}"
        return 0
    fi
    
    if [[ -z "$remote_version" ]]; then
        echo -e "${YELLOW}Could not fetch remote version. Continuing...${NC}"
        return 0
    fi
    
    # Compare versions
    if [[ "$remote_version" != "$SCRIPT_VERSION" ]]; then
        # Simple version comparison (assumes semantic versioning)
        local IFS='.'
        local i
        local -a local_parts=($SCRIPT_VERSION)
        local -a remote_parts=($remote_version)
        
        local needs_update=false
        for ((i=0; i<${#remote_parts[@]}; i++)); do
            local local_num=${local_parts[i]:-0}
            local remote_num=${remote_parts[i]:-0}
            if ((remote_num > local_num)); then
                needs_update=true
                break
            elif ((local_num > remote_num)); then
                break
            fi
        done
        
        if $needs_update; then
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}  New version available: ${GREEN}${remote_version}${YELLOW} (current: ${SCRIPT_VERSION})${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e ""
            read -rp "Do you want to update now? [y/N]: " update_choice
            
            if [[ "${update_choice,,}" == "y" ]]; then
                echo -e "${CYAN}Downloading update...${NC}"
                
                local tmp_file="/tmp/${SCRIPT_NAME}.tmp"
                
                if command -v curl &>/dev/null; then
                    curl -fsSL -o "$tmp_file" "${GITHUB_RAW_URL}/${SCRIPT_NAME}"
                else
                    wget -qO "$tmp_file" "${GITHUB_RAW_URL}/${SCRIPT_NAME}"
                fi
                
                if [[ -s "$tmp_file" ]]; then
                    chmod +x "$tmp_file"
                    mv "$tmp_file" "$current_script"
                    echo -e "${GREEN}✓ Updated to version ${remote_version}${NC}"
                    echo -e "${CYAN}Restarting script...${NC}"
                    exec "$current_script" "$@"
                else
                    echo -e "${RED}✗ Update failed. Continuing with current version.${NC}"
                    rm -f "$tmp_file"
                fi
            else
                echo -e "${CYAN}Skipping update.${NC}"
            fi
        fi
    else
        echo -e "${GREEN}✓ Already running the latest version (${SCRIPT_VERSION})${NC}"
    fi
    echo ""
}

check_for_updates

# ------------------------ Configuration ------------------------
LOG_DIR="./logs"
mkdir -p "$LOG_DIR"

DATE_NOW=$(date +"%Y-%m-%d_%H-%M-%S")

# RAM threshold for daemon mode (in MB)
RAM_THRESHOLD_MB=4096

# CPU thread limit (0 = auto, half of available cores)
CPU_THREADS=0

# ------------------------ Helper Functions ------------------------
log() {
    local msg="$1"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $msg"
}

# Get total RAM in MB
get_total_ram_mb() {
    local ram_kb
    ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    echo $((ram_kb / 1024))
}

# Check if system has enough RAM for daemon mode
has_enough_ram() {
    local total_ram
    total_ram=$(get_total_ram_mb)
    if [[ $total_ram -ge $RAM_THRESHOLD_MB ]]; then
        return 0  # Has 4GB+ RAM
    else
        return 1  # Less than 4GB RAM
    fi
}

# Get RAM info string
get_ram_info() {
    local total_ram
    total_ram=$(get_total_ram_mb)
    local total_gb
    total_gb=$(awk "BEGIN {printf \"%.1f\", $total_ram / 1024}")
    echo "${total_gb}GB"
}

get_log_files() {
    local scan_type=$1
    LOG_OUTPUT="$LOG_DIR/${scan_type}_scan_output_${DATE_NOW}.log"
    LOG_ERRORS="$LOG_DIR/${scan_type}_scan_errors_${DATE_NOW}.log"
}

# Get optimal thread count (half of available cores, minimum 1)
get_thread_count() {
    if [[ $CPU_THREADS -gt 0 ]]; then
        echo $CPU_THREADS
    else
        local cores
        cores=$(nproc 2>/dev/null || echo 2)
        local threads=$((cores / 2))
        [[ $threads -lt 1 ]] && threads=1
        echo $threads
    fi
}

# ------------------------ ClamAV Functions ------------------------
install_clamav() {
    echo -e "\n${BLUE}Starting ClamAV installation...${NC}"
    
    local ram_info
    ram_info=$(get_ram_info)
    echo -e "${CYAN}Detected RAM: ${ram_info}${NC}"
    
    sleep 1
    if command -v apt-get &>/dev/null; then
        apt-get update && apt-get install -y clamav clamav-daemon
        # Stop freshclam temporarily to update database
        systemctl stop clamav-freshclam 2>/dev/null || true
        freshclam
        systemctl start clamav-freshclam 2>/dev/null || true
        
        # Only enable daemon if RAM >= 4GB
        if has_enough_ram; then
            echo -e "${GREEN}RAM >= 4GB: Enabling daemon mode for faster scans${NC}"
            systemctl enable --now clamav-daemon 2>/dev/null || true
        else
            echo -e "${YELLOW}RAM < 4GB: Disabling daemon to save memory${NC}"
            systemctl disable --now clamav-daemon 2>/dev/null || true
        fi
    elif command -v yum &>/dev/null; then
        yum install -y epel-release && yum install -y clamav clamav-update clamd
        freshclam
        if has_enough_ram; then
            systemctl enable --now clamd@scan 2>/dev/null || true
        else
            systemctl disable --now clamd@scan 2>/dev/null || true
        fi
    elif command -v dnf &>/dev/null; then
        dnf install -y epel-release && dnf install -y clamav clamav-update clamd
        freshclam
        if has_enough_ram; then
            systemctl enable --now clamd@scan 2>/dev/null || true
        else
            systemctl disable --now clamd@scan 2>/dev/null || true
        fi
    else
        echo -e "${RED}Package manager not found. ClamAV installation failed.${NC}"
        return 1
    fi

    # Wait and show result
    sleep 3
    if has_enough_ram && check_clamd_status; then
        echo -e "${GREEN}ClamAV installed with daemon mode (RAM >= 4GB).${NC}"
    else
        echo -e "${GREEN}ClamAV installed in disk-only mode (RAM < 4GB, saves memory).${NC}"
    fi
}

# Check if clamd daemon is running
check_clamd_status() {
    if pgrep -x "clamd" > /dev/null 2>&1; then
        return 0
    elif systemctl is-active --quiet clamav-daemon 2>/dev/null; then
        return 0
    elif systemctl is-active --quiet clamd@scan 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Start clamd daemon if not running (only if RAM >= 4GB)
start_clamd() {
    # Check RAM first
    if ! has_enough_ram; then
        echo -e "${YELLOW}RAM < 4GB: Skipping daemon mode to save memory${NC}"
        return 1
    fi
    
    if ! check_clamd_status; then
        echo -e "${YELLOW}Starting ClamAV daemon...${NC}"
        systemctl start clamav-daemon 2>/dev/null || systemctl start clamd@scan 2>/dev/null || true
        sleep 3
        if check_clamd_status; then
            echo -e "${GREEN}ClamAV daemon started.${NC}"
            return 0
        else
            echo -e "${YELLOW}Could not start daemon. Using clamscan instead.${NC}"
            return 1
        fi
    fi
    return 0
}

# Stop clamd daemon to free memory
stop_clamd() {
    if check_clamd_status; then
        echo -e "${YELLOW}Stopping ClamAV daemon to free memory...${NC}"
        systemctl stop clamav-daemon 2>/dev/null || systemctl stop clamd@scan 2>/dev/null || true
        sleep 1
        if ! check_clamd_status; then
            echo -e "${GREEN}ClamAV daemon stopped.${NC}"
        fi
    fi
}

# Get the appropriate scan command based on RAM and daemon status
# Returns: "clamdscan" or "clamscan"
get_scan_command() {
    # If RAM < 4GB, always use clamscan (no daemon)
    if ! has_enough_ram; then
        echo "clamscan"
        return
    fi
    
    # If RAM >= 4GB and daemon is running, use clamdscan
    if check_clamd_status && command -v clamdscan &>/dev/null; then
        echo "clamdscan"
    else
        echo "clamscan"
    fi
}

update_clamav_db() {
    echo -e "\n${BLUE}Updating ClamAV database...${NC}"
    
    # Stop freshclam service if running (to avoid lock)
    systemctl stop clamav-freshclam 2>/dev/null || true
    
    if freshclam; then
        echo -e "${GREEN}ClamAV database updated successfully.${NC}"
        # Restart daemon to reload database
        if check_clamd_status; then
            echo -e "${BLUE}Reloading ClamAV daemon...${NC}"
            systemctl restart clamav-daemon 2>/dev/null || systemctl restart clamd@scan 2>/dev/null || true
        fi
    else
        echo -e "${RED}An error occurred while updating the ClamAV database.${NC}"
    fi
    
    # Restart freshclam service
    systemctl start clamav-freshclam 2>/dev/null || true
}

print_scan_summary() {
    local output_file=$1
    echo -e "\n${YELLOW}Scan Summary:${NC}" | tee -a "$output_file"
    local total_dirs
    local infected
    total_dirs=$(grep "Scanned directories:" "$output_file" | tail -1 | awk '{print $3}')
    infected=$(grep "Infected files:" "$output_file" | tail -1 | awk '{print $3}')
    echo "Total scanned directories: $total_dirs" | tee -a "$output_file"
    echo "Infected files found: $infected" | tee -a "$output_file"
}

scan_system() {
    update_clamav_db
    get_log_files "system"
    
    # Try to start daemon for low RAM usage
    start_clamd
    local scan_cmd
    scan_cmd=$(get_scan_command)
    local use_daemon=false
    [[ "$scan_cmd" == "clamdscan" ]] && use_daemon=true
    
    echo -e "\n${BLUE}Starting system scan with ${scan_cmd}...${NC}"
    if $use_daemon; then
        echo -e "${GREEN}Using daemon mode (low RAM usage)${NC}"
    else
        echo -e "${YELLOW}Using standalone mode (higher RAM usage)${NC}"
    fi
    
    local threads
    threads=$(get_thread_count)
    
    echo "Scan started at $(date)" >"$LOG_OUTPUT"
    echo "Scan command: $scan_cmd (threads: $threads)" >>"$LOG_OUTPUT"
    echo "Scanning: / (excluding /sys, /proc, /dev, /run)" >>"$LOG_OUTPUT"
    echo "----------------------------------------" >>"$LOG_OUTPUT"
    
    # Create temporary script for background execution (survives SSH disconnect)
    local tmp_script="/tmp/clamav_scan_$$.sh"
    
    if $use_daemon; then
        # clamdscan with fdpass (for permission issues)
        cat > "$tmp_script" << 'SCAN_EOF'
#!/bin/bash
LOG_FILE="$1"
clamdscan --fdpass / \
    --exclude-dir="^/sys" \
    --exclude-dir="^/proc" \
    --exclude-dir="^/dev" \
    --exclude-dir="^/run" \
    >> "$LOG_FILE" 2>&1
echo "" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"
echo "Scan completed at $(date)" >> "$LOG_FILE"
# Stop daemon after scan to free memory
systemctl stop clamav-daemon 2>/dev/null || systemctl stop clamd@scan 2>/dev/null || true
echo "Daemon stopped to free memory." >> "$LOG_FILE"
rm -f "$0"
SCAN_EOF
    else
        # clamscan standalone
        cat > "$tmp_script" << 'SCAN_EOF'
#!/bin/bash
LOG_FILE="$1"
clamscan -r / \
    --exclude-dir="^/sys" \
    --exclude-dir="^/proc" \
    --exclude-dir="^/dev" \
    --exclude-dir="^/run" \
    >> "$LOG_FILE" 2>&1
echo "" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"
echo "Scan completed at $(date)" >> "$LOG_FILE"
rm -f "$0"
SCAN_EOF
    fi
    
    chmod +x "$tmp_script"
    nohup "$tmp_script" "$LOG_OUTPUT" >/dev/null 2>&1 &
    local pid=$!
    disown $pid 2>/dev/null || true
    
    echo -e "${GREEN}Scan started in background (PID: $pid).${NC}"
    echo -e "${CYAN}Using $threads CPU thread(s) (of $(nproc 2>/dev/null || echo '?') available)${NC}"
    echo "Output logs: $LOG_OUTPUT"
    echo ""
    echo -e "${GREEN}✓ Scan will continue even if you disconnect SSH${NC}"
    echo -e "${CYAN}Tip: Use option 3 to monitor progress in real-time${NC}"
    echo -e "${DIM}Tip: Use option 4 to list only infected files (FOUND)${NC}"
    if $use_daemon; then
        echo -e "${DIM}Note: Daemon will auto-stop after scan to free memory${NC}"
    fi
}

scan_directory() {
    read -rp "Enter the full path of the directory to scan: " directory

    if [[ ! -d "$directory" ]]; then
        echo -e "${RED}Error: The entered directory is not available or cannot be accessed.${NC}"
        return 1
    fi

    update_clamav_db
    get_log_files "directory"
    
    # Try to start daemon for low RAM usage
    start_clamd
    local scan_cmd
    scan_cmd=$(get_scan_command)
    local use_daemon=false
    [[ "$scan_cmd" == "clamdscan" ]] && use_daemon=true
    
    echo -e "\n${BLUE}Starting scan of directory: $directory with ${scan_cmd}${NC}"
    if $use_daemon; then
        echo -e "${GREEN}Using daemon mode (low RAM usage)${NC}"
    else
        echo -e "${YELLOW}Using standalone mode (higher RAM usage)${NC}"
    fi
    
    local threads
    threads=$(get_thread_count)
    
    echo "Scan started at $(date)" >"$LOG_OUTPUT"
    echo "Scan command: $scan_cmd (threads: $threads)" >>"$LOG_OUTPUT"
    echo "Scanning: $directory" >>"$LOG_OUTPUT"
    echo "----------------------------------------" >>"$LOG_OUTPUT"
    
    # Create temporary script for background execution (survives SSH disconnect)
    local tmp_script="/tmp/clamav_scan_$$.sh"
    
    if $use_daemon; then
        # clamdscan with fdpass (for permission issues)
        cat > "$tmp_script" << 'SCAN_EOF'
#!/bin/bash
LOG_FILE="$1"
SCAN_DIR="$2"
clamdscan --fdpass "$SCAN_DIR" >> "$LOG_FILE" 2>&1
echo "" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"
echo "Scan completed at $(date)" >> "$LOG_FILE"
# Stop daemon after scan to free memory
systemctl stop clamav-daemon 2>/dev/null || systemctl stop clamd@scan 2>/dev/null || true
echo "Daemon stopped to free memory." >> "$LOG_FILE"
rm -f "$0"
SCAN_EOF
    else
        # clamscan standalone
        cat > "$tmp_script" << 'SCAN_EOF'
#!/bin/bash
LOG_FILE="$1"
SCAN_DIR="$2"
clamscan -r "$SCAN_DIR" \
    --exclude-dir="^/sys" \
    --exclude-dir="^/proc" \
    --exclude-dir="^/dev" \
    --exclude-dir="^/run" \
    >> "$LOG_FILE" 2>&1
echo "" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"
echo "Scan completed at $(date)" >> "$LOG_FILE"
rm -f "$0"
SCAN_EOF
    fi
    
    chmod +x "$tmp_script"
    nohup "$tmp_script" "$LOG_OUTPUT" "$directory" >/dev/null 2>&1 &
    local pid=$!
    disown $pid 2>/dev/null || true
    
    echo -e "${GREEN}Scan started in the background (PID: $pid).${NC}"
    echo -e "${CYAN}Using $threads CPU thread(s) (of $(nproc 2>/dev/null || echo '?') available)${NC}"
    echo "Output logs: $LOG_OUTPUT"
    echo ""
    echo -e "${GREEN}✓ Scan will continue even if you disconnect SSH${NC}"
    echo -e "${CYAN}Tip: Use option 3 to monitor progress in real-time${NC}"
    echo -e "${DIM}Tip: Use option 4 to list only infected files (FOUND)${NC}"
    if $use_daemon; then
        echo -e "${DIM}Note: Daemon will auto-stop after scan to free memory${NC}"
    fi
}

show_progress() {
    echo -e "\n${CYAN}Monitoring scan progress (press CTRL+C to exit)...${NC}"
    read -rp "Enter log file path (or press Enter for last system scan log): " logfile

    if [[ -z "$logfile" ]]; then
        logfile=$(ls -1t "$LOG_DIR"/*_scan_output_*.log 2>/dev/null | head -n1)
        if [[ -z "$logfile" ]]; then
            echo -e "${RED}No scan logs found.${NC}"
            return 1
        fi
    fi

    echo -e "${YELLOW}Showing logs from: $logfile${NC}"
    tail -f "$logfile"
}

show_found() {
    local logfile
    logfile=$(ls -1t "$LOG_DIR"/*_scan_output_*.log 2>/dev/null | head -n1)
    if [[ -z "$logfile" ]]; then
        echo -e "${RED}No scan logs found.${NC}"
        return 1
    fi

    echo -e "\n${RED}Listing infected files from latest scan:${NC}"
    grep "FOUND" "$logfile" || echo -e "${GREEN}No infected files found in the latest scan.${NC}"
}

stop_scan() {
    local pids
    pids=$(pgrep -f "clamscan|clamdscan" || true)
    if [[ -n "$pids" ]]; then
        echo -e "${YELLOW}Stopping all ClamAV scan processes...${NC}"
        kill -9 $pids
        echo -e "${GREEN}Scan processes stopped.${NC}"
    else
        echo -e "${GREEN}No active scan process found.${NC}"
    fi
}

clear_logs() {
    echo -e "\n${YELLOW}Clearing old log files in $LOG_DIR ...${NC}"
    rm -f "$LOG_DIR"/*.log
    echo -e "${GREEN}Log files cleared.${NC}"
}

# ------------------------ Menu ------------------------
menu() {
    clear
    echo -e "${BLUE}======================================${NC}"
    echo -e "${CYAN}       ClamAV Scan Management         ${NC}"
    echo -e "${BLUE}======================================${NC}"
    
    # Show RAM and mode info
    local ram_info
    ram_info=$(get_ram_info)
    
    if has_enough_ram; then
        echo -e " ${CYAN}RAM: ${ram_info} (>= 4GB)${NC}"
        if check_clamd_status; then
            echo -e " ${GREEN}● Mode: Daemon (fast, uses ~500MB RAM)${NC}"
        else
            echo -e " ${YELLOW}○ Mode: Daemon available but stopped${NC}"
        fi
    else
        echo -e " ${YELLOW}RAM: ${ram_info} (< 4GB)${NC}"
        echo -e " ${CYAN}● Mode: Disk-only (slow but saves RAM)${NC}"
    fi
    echo -e "${BLUE}--------------------------------------${NC}"
    
    echo -e " ${GREEN}0)${NC} Install ClamAV"
    echo -e " ${GREEN}1)${NC} Start background system scan"
    echo -e " ${GREEN}2)${NC} Scan a specific directory"
    echo -e " ${GREEN}3)${NC} Show scan progress in real-time"
    echo -e " ${GREEN}4)${NC} List infected files from latest scan"
    echo -e " ${GREEN}5)${NC} Stop ongoing background scan"
    echo -e " ${GREEN}6)${NC} Update ClamAV virus database"
    echo -e " ${GREEN}7)${NC} Clear log files"
    if has_enough_ram; then
        echo -e " ${CYAN}8)${NC} Start/Restart ClamAV daemon"
    else
        echo -e " ${DIM}8) Start daemon (disabled: RAM < 4GB)${NC}"
    fi
    echo -e " ${RED}9)${NC} Exit"
    echo -e "${BLUE}======================================${NC}"
}

# Restart ClamAV daemon (only if RAM >= 4GB)
restart_clamd() {
    if ! has_enough_ram; then
        local ram_info
        ram_info=$(get_ram_info)
        echo -e "\n${RED}Cannot start daemon: RAM (${ram_info}) is less than 4GB${NC}"
        echo -e "${YELLOW}Daemon mode requires at least 4GB RAM.${NC}"
        echo -e "${CYAN}Your system will use disk-only mode (clamscan) which doesn't use extra RAM.${NC}"
        return 1
    fi
    
    echo -e "\n${BLUE}Restarting ClamAV daemon...${NC}"
    systemctl restart clamav-daemon 2>/dev/null || systemctl restart clamd@scan 2>/dev/null || true
    sleep 3
    if check_clamd_status; then
        echo -e "${GREEN}ClamAV daemon is now running.${NC}"
        echo -e "${GREEN}Scans will use daemon mode (clamdscan).${NC}"
    else
        echo -e "${RED}Failed to start ClamAV daemon.${NC}"
        echo -e "${YELLOW}Try running: sudo systemctl start clamav-daemon${NC}"
    fi
}

# ------------------------ Main Loop ------------------------
while true; do
    menu
    read -rp "Please choose an option: " choice

    case $choice in
        0) install_clamav ;;
        1) scan_system ;;
        2) scan_directory ;;
        3) show_progress ;;
        4) show_found ;;
        5) stop_scan ;;
        6) update_clamav_db ;;
        7) clear_logs ;;
        8) restart_clamd ;;
        9) echo -e "${CYAN}Exiting. Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid choice. Please try again.${NC}" ;;
    esac

    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
done
