#!/bin/bash

#######################################################
#                    burakurer.dev                    #
#                                                     #
#     Script      : bu-clamav.sh                      #
#     Version     : 1.1.1                             #
#     Last Update : 17/06/2025                        #
#     Website     : https://burakurer.dev             #
#     Github      : https://github.com/burakurer      #
#                                                     #
#######################################################

if [[ $EUID -ne 0 ]]; then
    echo -e "\e[31mPlease run the script as root.\e[0m"
    exit 1
fi

LOG_DIR="./logs"
mkdir -p "$LOG_DIR"

DATE_NOW=$(date +"%Y-%m-%d_%H-%M-%S")

function get_log_files() {
    local scan_type=$1
    LOG_OUTPUT="$LOG_DIR/${scan_type}_scan_output_${DATE_NOW}.log"
    LOG_ERRORS="$LOG_DIR/${scan_type}_scan_errors_${DATE_NOW}.log"
}

function install_clamav() {
    echo -e "\n\e[34mStarting ClamAV installation...\e[0m"
    sleep 1
    if command -v apt-get &>/dev/null; then
        apt-get update && apt-get install -y clamav clamav-daemon
    elif command -v yum &>/dev/null; then
        yum install -y epel-release && yum install -y clamav clamav-update
    elif command -v dnf &>/dev/null; then
        dnf install -y epel-release && dnf install -y clamav clamav-update
    else
        echo -e "\e[31mPackage manager not found. ClamAV installation failed.\e[0m"
        return 1
    fi

    freshclam
    if [[ $? -eq 0 ]]; then
        echo -e "\e[32mClamAV installed successfully, and the database was updated.\e[0m"
    else
        echo -e "\e[31mAn error occurred while updating ClamAV's database.\e[0m"
    fi
}

function update_clamav_db() {
    echo -e "\n\e[34mUpdating ClamAV database...\e[0m"
    freshclam
    if [[ $? -eq 0 ]]; then
        echo -e "\e[32mClamAV database updated successfully.\e[0m"
    else
        echo -e "\e[31mAn error occurred while updating the ClamAV database.\e[0m"
    fi
}

function print_scan_summary() {
    local output_file=$1
    echo -e "\n\e[33mScan Summary:\e[0m" | tee -a "$output_file"
    local total_files=$(grep "Scanned directories:" "$output_file" | tail -1 | awk '{print $3}')
    local infected=$(grep "Infected files:" "$output_file" | tail -1 | awk '{print $3}')
    echo "Total scanned directories: $total_files" | tee -a "$output_file"
    echo "Infected files found: $infected" | tee -a "$output_file"
}

function scan_system() {
    update_clamav_db
    get_log_files "system"
    echo -e "\n\e[34mStarting system scan...\e[0m"
    echo "Scan started at $(date)" >"$LOG_OUTPUT"
    nohup clamscan -r / >>"$LOG_OUTPUT" 2>>"$LOG_ERRORS" &
    local pid=$!
    echo -e "\e[32mScan started in background (PID: $pid).\e[0m"
    echo "Output logs: $LOG_OUTPUT"
    echo "Error logs: $LOG_ERRORS"
}

function scan_directory() {
    update_clamav_db
    read -rp "Enter the full path of the directory to scan: " directory

    if [[ ! -d "$directory" ]]; then
        echo -e "\e[31mError: The entered directory is not available or cannot be accessed.\e[0m"
        return 1
    fi

    get_log_files "directory"
    echo -e "\n\e[34mStarting scan of directory: $directory\e[0m"
    echo "Scan started at $(date)" >"$LOG_OUTPUT"
    nohup clamscan -r "$directory" >>"$LOG_OUTPUT" 2>>"$LOG_ERRORS" &
    local pid=$!
    echo -e "\e[32mScan started in the background (PID: $pid).\e[0m"
    echo "Output logs: $LOG_OUTPUT"
    echo "Error logs: $LOG_ERRORS"
}

function show_progress() {
    echo -e "\n\e[36mMonitoring scan progress (press CTRL+C to exit)...\e[0m"
    read -rp "Enter log file path (or press Enter for last system scan log): " logfile

    if [[ -z "$logfile" ]]; then
        logfile=$(ls -1t $LOG_DIR/*_scan_output_*.log 2>/dev/null | head -n1)
        if [[ -z "$logfile" ]]; then
            echo -e "\e[31mNo scan logs found.\e[0m"
            return 1
        fi
    fi

    echo -e "\e[33mShowing logs from: $logfile\e[0m"
    tail -f "$logfile"
}

function show_found() {
    local logfile
    logfile=$(ls -1t $LOG_DIR/*_scan_output_*.log 2>/dev/null | head -n1)
    if [[ -z "$logfile" ]]; then
        echo -e "\e[31mNo scan logs found.\e[0m"
        return 1
    fi

    echo -e "\n\e[31mListing infected files from latest scan:\e[0m"
    grep "FOUND" "$logfile" || echo -e "\e[32mNo infected files found in the latest scan.\e[0m"
}

function stop_scan() {
    local pids
    pids=$(pgrep -f "clamscan -r")
    if [[ -n $pids ]]; then
        echo -e "\e[33mStopping all scans...\e[0m"
        kill -9 $pids
        echo -e "\e[32mScans stopped.\e[0m"
    else
        echo -e "\e[32mNo active scan found.\e[0m"
    fi
}

function clear_logs() {
    echo -e "\n\e[33mClearing old log files in $LOG_DIR ...\e[0m"
    rm -f "$LOG_DIR"/*.log
    echo -e "\e[32mLog files cleared.\e[0m"
}

function menu() {
    echo -e "\n\e[1;34m=== ClamAV Scan Management ===\e[0m"
    echo -e " 0) Install ClamAV"
    echo -e " 1) Start background system scan"
    echo -e " 2) Scan a specific directory"
    echo -e " 3) Show scan progress in real-time"
    echo -e " 4) List infected files from latest scan"
    echo -e " 5) Stop ongoing background scan"
    echo -e " 6) Update ClamAV virus database"
    echo -e " 7) Clear log files"
    echo -e " 8) Exit"
}

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
    8) echo -e "\e[36mExiting. Goodbye!\e[0m"; exit 0 ;;
    *) echo -e "\e[31mInvalid choice. Please try again.\e[0m" ;;
    esac
done
