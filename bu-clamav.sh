#!/bin/bash

#######################################################
#                    burakurer.dev                    #
#                                                     #
#     Script      : bu-clamav.sh                      #
#     Version     : 1.0.0                             #
#     Last Update : 11/03/2025                        #
#     Website     : https://burakurer.dev             #
#     Github      : https://github.com/burakurer      #
#                                                     #
#######################################################

if [[ $EUID -ne 0 ]]; then
    echo "Please run the script as root."
    exit 1
fi

LOG_OUTPUT="scan_output.txt"
LOG_ERRORS="scan_errors.txt"

# Install ClamAV based on the package manager
function install_clamav() {
    echo "Starting ClamAV installation..."
    sleep 3
    if command -v apt-get &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y clamav clamav-daemon
    elif command -v yum &>/dev/null; then
        sudo yum install -y epel-release && sudo yum install -y clamav clamav-update
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y epel-release && sudo dnf install -y clamav clamav-update
    else
        echo "Package manager not found. ClamAV installation failed."
        return 1
    fi

    sudo freshclam
    if [[ $? -eq 0 ]]; then
        echo "ClamAV installed successfully, and the database was updated."
    else
        echo "An error occurred while updating ClamAV's database."
    fi
}

# Scan the entire system
function scan_system() {
    update_clamav
    echo "Starting system scan..."
    nohup clamscan -r / >"$LOG_OUTPUT" 2>"$LOG_ERRORS" &
    echo "Scan started in the background. Output will be written to $LOG_OUTPUT and $LOG_ERRORS."
}

# Scan a specific directory
function scan_directory() {
    update_clamav
    read -rp "Enter the path of the directory to scan: " directory
    echo "Scanning directory: $directory..."
    clamscan -r "$directory" >"$LOG_OUTPUT" 2>"$LOG_ERRORS"
    echo "Scan completed. Results are written to $LOG_OUTPUT and $LOG_ERRORS."
}

# Clear log files
function clear_logs() {
    echo "Clearing old log files..."
    rm -f "$LOG_OUTPUT" "$LOG_ERRORS"
    echo "Log files cleared."
}

# Show scan progress in real-time
function show_progress() {
    echo "Monitoring scan status (press CTRL+C to exit)..."
    tail -f "$LOG_OUTPUT"
}

# Display infected files
function show_found() {
    echo "Listing infected files (FOUND):"
    grep "FOUND" "$LOG_OUTPUT"
}

# Stop an ongoing scan
function stop_scan() {
    local pid
    pid=$(pgrep -f "clamscan -r /")
    if [[ -n $pid ]]; then
        echo "Stopping the scan..."
        kill -9 $pid
        echo "Scan stopped."
    else
        echo "No active scan found."
    fi
}

# Update ClamAV virus database
function update_clamav() {
    echo "Updating ClamAV database..."
    sudo freshclam
    if [[ $? -eq 0 ]]; then
        echo "ClamAV database updated successfully."
    else
        echo "An error occurred while updating the ClamAV database."
    fi
}

# User Menu
while true; do
    echo "=== ClamAV Scan Management ==="
    echo "0) Install ClamAV"
    echo "1) Start background system scan"
    echo "2) Scan a specific directory"
    echo "3) Show scan progress in real-time"
    echo "4) List infected files"
    echo "5) Stop ongoing background scan"
    echo "6) Update ClamAV virus database"
    echo "7) Clear log files"
    read -rp "Please choose an option: " choice

    case $choice in
    0) install_clamav ;;
    1) scan_system ;;
    2) scan_directory ;;
    3) show_progress ;;
    4) show_found ;;
    5) stop_scan ;;
    6) update_clamav ;;
    7) clear_logs ;;
    *) echo "Invalid choice. Please try again." ;;
    esac
done
