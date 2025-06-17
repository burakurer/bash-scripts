#!/bin/bash

#######################################################
#                    burakurer.dev                    #
#                                                     #
#     Script      : bu-toolkit.sh                     #
#     Version     : 3.1.1                             #
#     Last Update : 17/06/2025                        #
#     Website     : https://burakurer.dev             #
#     Github      : https://github.com/burakurer      #
#                                                     #
#######################################################

set -euo pipefail
IFS=$'\n\t'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
OS=""
VERSION=""

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Please run the script as root!${NC}"
    exit 1
fi

log() {
    local msg="$1"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $msg"
}

getOSInfo() {
    if [[ -r /etc/os-release ]]; then
        source /etc/os-release
        OS=${ID,,}
        VERSION=$VERSION_ID
    elif command -v lsb_release &>/dev/null; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        VERSION=$(lsb_release -sr)
    else
        log "${RED}Operating system detection failed!${NC}"
        exit 1
    fi

    if [[ -z "$OS" ]]; then
        log "${RED}Operating system detection failed: OS is empty${NC}"
        exit 1
    fi
}

getOSInfo

checkSupportedOS() {
    local supported=("ubuntu" "debian" "centos" "rocky" "almalinux")
    local found=0
    for os_name in "${supported[@]}"; do
        if [[ "$os_name" == "$OS" ]]; then
            found=1
            break
        fi
    done
    if [[ $found -ne 1 ]]; then
        log "${RED}Unsupported OS: $OS. This script supports: ${supported[*]}${NC}"
        exit 1
    fi
}

checkSupportedOS

updateSystem() {
    clear
    log "${YELLOW}Checking for system updates... (Ctrl+C to cancel)${NC}"
    sleep 2

    case $OS in
        ubuntu|debian)
            apt update -y && apt upgrade -y && apt autoremove -y
            ;;
        centos|rocky|almalinux)
            yum update -y && yum upgrade -y && yum autoremove -y
            ;;
    esac

    log "${GREEN}System updates completed.${NC}"
    sleep 1
}

dateSync() {
    clear
    log "${YELLOW}Syncing server time to Europe/Istanbul... (Ctrl+C to cancel)${NC}"
    sleep 2

    if [[ -f /usr/share/zoneinfo/Europe/Istanbul ]]; then
        ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
        hwclock --systohc
        timedatectl set-ntp true
        log "${GREEN}Server time synchronized.${NC}"
    else
        log "${RED}Timezone data for Europe/Istanbul not found!${NC}"
    fi
    sleep 1
}

installRecommendedPackages() {
    clear
    log "${YELLOW}Installing recommended packages... (Ctrl+C to cancel)${NC}"
    sleep 2

    case $OS in
        ubuntu|debian)
            apt update -y
            apt install -y wget curl nano htop snapd
            snap install btop
            ;;
        centos|rocky|almalinux)
            yum install -y epel-release
            yum update -y
            yum install -y wget curl nano htop snapd
            systemctl enable --now snapd.socket
            ln -sf /var/lib/snapd/snap /snap
            snap install btop
            ;;
    esac

    log "${GREEN}Recommended packages installed.${NC}"
    sleep 1
}

installClamAV() {
    clear
    log "${YELLOW}Installing ClamAV... (Ctrl+C to cancel)${NC}"
    sleep 2

    case $OS in
        ubuntu|debian)
            apt install -y clamav clamav-daemon
            systemctl enable --now clamav-freshclam.service
            freshclam
            ;;
        centos|rocky|almalinux)
            yum install -y epel-release
            yum install -y clamav clamav-update
            freshclam
            systemctl enable --now clamd@scan.service
            ;;
    esac

    log "${GREEN}ClamAV installed and updated.${NC}"
    sleep 1
}

installPlesk() {
    clear
    log "${YELLOW}Starting Plesk installation... (Ctrl+C to cancel)${NC}"
    sleep 2

    if command -v curl &>/dev/null; then
        sh <(curl -fsSL https://autoinstall.plesk.com/one-click-installer)
    elif command -v wget &>/dev/null; then
        sh <(wget -qO- https://autoinstall.plesk.com/one-click-installer)
    else
        log "${RED}Neither curl nor wget is installed! Cannot download Plesk installer.${NC}"
        return 1
    fi

    log "${GREEN}Plesk installation completed.${NC}"
    sleep 1
}

installCaching() {
    clear
    log "${YELLOW}Installing Redis & Memcached... (Ctrl+C to cancel)${NC}"
    sleep 2

    case $OS in
        ubuntu|debian)
            apt update -y
            apt install -y redis memcached
            systemctl enable --now redis memcached
            ;;
        centos|rocky|almalinux)
            yum install -y epel-release
            yum install -y redis memcached
            systemctl enable --now redis memcached
            ;;
    esac

    log "${GREEN}Redis & Memcached installation completed.${NC}"
    sleep 1
}

createPleskLoginLink() {
    clear
    if command -v plesk &>/dev/null; then
        plesk login
    else
        log "${RED}Plesk CLI tool not found.${NC}"
    fi
    sleep 1
}

removePleskBackups() {
    clear
    echo -e "${RED}Deleting all Plesk backups... This is irreversible! (Ctrl+C to cancel)${NC}"
    read -rp "Are you sure you want to proceed? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        log "Operation cancelled by user."
        return
    fi

    if [[ -d /var/lib/psa/dumps ]]; then
        rm -rf /var/lib/psa/dumps/*
        log "${GREEN}All Plesk backups deleted.${NC}"
    else
        log "${RED}Plesk backups directory not found.${NC}"
    fi
    sleep 1
}

fixPleskCurlError() {
    clear
    log "${YELLOW}[PLESK] Fixing cURL error 77... (Ctrl+C to cancel)${NC}"
    sleep 2

    systemctl restart plesk-php* || log "${RED}Failed to restart plesk-php services.${NC}"
    systemctl restart sw-engine || log "${RED}Failed to restart sw-engine service.${NC}"

    log "${GREEN}[PLESK] cURL error 77 fixed (if restarts succeeded).${NC}"
    sleep 1
}

while true; do
    clear
    echo -e "------------------------------------------"
    echo -e "${RED}Script by burakurer.dev${NC}"
    echo -e "=== General Operations ==="
    echo -e "[1] Check for system updates"
    echo -e "[2] Synchronize server time (Europe/Istanbul)"
    echo -e "\n=== Installations and Upgrades ==="
    echo -e "[3] Install recommended packages (wget, curl, nano, htop, btop, epel-release, snapd)"
    echo -e "[4] Install ClamAV (Antivirus)"
    echo -e "[5] Install Plesk"
    echo -e "[6] Install Redis & Memcached"
    echo -e "\n=== Plesk Operations ==="
    echo -e "[7] Generate Plesk login link"
    echo -e "[8] Delete all Plesk backups"
    echo -e "\n=== Error Fixes ==="
    echo -e "[9] [PLESK] Fix cURL error 77"
    echo -e "[0] Exit"
    echo -e "------------------------------------------"
    read -rp "Enter an option (0-9): " choice

    case $choice in
        1) updateSystem ;;
        2) dateSync ;;
        3) installRecommendedPackages ;;
        4) installClamAV ;;
        5) installPlesk ;;
        6) installCaching ;;
        7) createPleskLoginLink ;;
        8) removePleskBackups ;;
        9) fixPleskCurlError ;;
        0)
            log "Exiting script as requested."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option! Please try again.${NC}"
            sleep 1
            ;;
    esac

    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
done
