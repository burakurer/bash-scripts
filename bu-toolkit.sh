#!/bin/bash

#######################################################
#                                                     #
#     Author      : burakurer.dev                     #
#     Script      : bu-toolkit.sh                     #
#     Description : Server Management Toolkit         #
#     Version     : 4.1.0                             #
#     Last Update : 01/12/2025                        #
#     Website     : https://burakurer.dev             #
#     Github      : https://github.com/burakurer      #
#                                                     #
#######################################################

set -euo pipefail
IFS=$'\n\t'

# ------------------------ Colors ------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ------------------------ Variables ------------------------
OS=""
VERSION=""
SCRIPT_VERSION="4.1.0"
SCRIPT_NAME="bu-toolkit.sh"
GITHUB_RAW_URL="https://raw.githubusercontent.com/burakurer/bash-scripts/master"

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
check_for_updates

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
        timedatectl set-timezone Europe/Istanbul
        timedatectl set-ntp true
        # hwclock --systohc  # kaldırıldı
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

installRedis() {
    clear
    log "${YELLOW}Installing Redis... (Ctrl+C to cancel)${NC}"
    sleep 2

    case $OS in
        ubuntu|debian)
            apt update -y
            apt install -y redis-server
            systemctl enable --now redis-server
            ;;
        centos|rocky|almalinux)
            yum install -y epel-release
            yum install -y redis
            systemctl enable --now redis
            ;;
    esac

    log "${GREEN}Redis installation completed.${NC}"
    sleep 1
}

installMemcached() {
    clear
    log "${YELLOW}Installing Memcached... (Ctrl+C to cancel)${NC}"
    sleep 2

    case $OS in
        ubuntu|debian)
            apt update -y
            apt install -y memcached libmemcached-tools
            systemctl enable --now memcached
            ;;
        centos|rocky|almalinux)
            yum install -y epel-release
            yum install -y memcached
            systemctl enable --now memcached
            ;;
    esac

    log "${GREEN}Memcached installation completed.${NC}"
    sleep 1
}

# ------------------------ Node.js Functions ------------------------
installNodeJS() {
    clear
    log "${YELLOW}Installing Node.js via NVM... (Ctrl+C to cancel)${NC}"
    sleep 2

    # Install NVM
    if [[ ! -d "$HOME/.nvm" ]]; then
        log "${BLUE}Installing NVM (Node Version Manager)...${NC}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        
        # Load NVM
        export NVM_DIR="$HOME/.nvm"
        # shellcheck source=/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        log "${BLUE}NVM already installed, loading...${NC}"
        export NVM_DIR="$HOME/.nvm"
        # shellcheck source=/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi

    # Ask for Node.js version
    echo -e "\n${CYAN}Available options:${NC}"
    echo -e "  1) LTS (Recommended)"
    echo -e "  2) Latest"
    echo -e "  3) Specific version (e.g., 20, 18.19.0)"
    read -rp "Choose option [1]: " node_choice
    node_choice=${node_choice:-1}

    case $node_choice in
        1) nvm install --lts && nvm use --lts && nvm alias default 'lts/*' ;;
        2) nvm install node && nvm use node ;;
        3) 
            read -rp "Enter Node.js version: " node_version
            nvm install "$node_version" && nvm use "$node_version" && nvm alias default "$node_version"
            ;;
        *) nvm install --lts && nvm use --lts && nvm alias default 'lts/*' ;;
    esac

    log "${GREEN}Node.js installation completed.${NC}"
    echo -e "${CYAN}Node version:${NC} $(node --version 2>/dev/null || echo 'Reload shell to use')"
    echo -e "${CYAN}NPM version:${NC} $(npm --version 2>/dev/null || echo 'Reload shell to use')"
    echo -e "\n${YELLOW}Note: Run 'source ~/.bashrc' or restart your shell to use Node.js${NC}"
    sleep 2
}

# ------------------------ System Info Functions ------------------------
showSystemInfo() {
    clear
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║                     SYSTEM INFORMATION                       ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"

    # OS Info
    echo -e "${BOLD}Operating System:${NC}"
    echo -e "  ${CYAN}OS:${NC}         $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "$OS $VERSION")"
    echo -e "  ${CYAN}Kernel:${NC}     $(uname -r)"
    echo -e "  ${CYAN}Arch:${NC}       $(uname -m)"
    echo -e "  ${CYAN}Hostname:${NC}   $(hostname)"
    
    # Uptime
    echo -e "\n${BOLD}Uptime:${NC}"
    echo -e "  ${CYAN}Up since:${NC}   $(uptime -s 2>/dev/null || echo 'N/A')"
    echo -e "  ${CYAN}Uptime:${NC}     $(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"

    # CPU Info
    echo -e "\n${BOLD}CPU:${NC}"
    if command -v lscpu &>/dev/null; then
        local cpu_model cpu_cores cpu_threads
        cpu_model=$(lscpu | grep "Model name" | sed 's/Model name:[[:space:]]*//')
        cpu_cores=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
        cpu_threads=$(lscpu | grep "Thread(s) per core" | awk '{print $4}')
        echo -e "  ${CYAN}Model:${NC}      $cpu_model"
        echo -e "  ${CYAN}Cores:${NC}      $cpu_cores"
        echo -e "  ${CYAN}Threads:${NC}    $cpu_threads per core"
    fi
    
    # Load Average
    echo -e "  ${CYAN}Load Avg:${NC}   $(cat /proc/loadavg | awk '{print $1, $2, $3}')"

    # Memory Info
    echo -e "\n${BOLD}Memory:${NC}"
    if command -v free &>/dev/null; then
        local mem_total mem_used mem_free mem_available
        mem_total=$(free -h | awk '/^Mem:/ {print $2}')
        mem_used=$(free -h | awk '/^Mem:/ {print $3}')
        mem_free=$(free -h | awk '/^Mem:/ {print $4}')
        mem_available=$(free -h | awk '/^Mem:/ {print $7}')
        echo -e "  ${CYAN}Total:${NC}      $mem_total"
        echo -e "  ${CYAN}Used:${NC}       $mem_used"
        echo -e "  ${CYAN}Free:${NC}       $mem_free"
        echo -e "  ${CYAN}Available:${NC}  $mem_available"
        
        # Swap
        local swap_total swap_used
        swap_total=$(free -h | awk '/^Swap:/ {print $2}')
        swap_used=$(free -h | awk '/^Swap:/ {print $3}')
        echo -e "  ${CYAN}Swap:${NC}       $swap_used / $swap_total"
    fi

    # Disk Info
    echo -e "\n${BOLD}Disk Usage:${NC}"
    df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs 2>/dev/null | head -10 | while read -r line; do
        echo -e "  $line"
    done

    # Network Info
    echo -e "\n${BOLD}Network:${NC}"
    if command -v ip &>/dev/null; then
        ip -4 addr show | grep inet | grep -v '127.0.0.1' | awk '{print "  " $NF ": " $2}' | head -5
    fi
    
    # Public IP (optional, commented by default for privacy)
    echo -e "  ${CYAN}Public IP:${NC}  $(curl -s ifconfig.me 2>/dev/null || echo 'N/A')"

    echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════════════════════════${NC}"
    sleep 1
}

# ------------------------ Disk Cleanup Functions ------------------------
diskCleanup() {
    clear
    echo -e "${BOLD}${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║              SAFE DISK CLEANUP UTILITY                       ║${NC}"
    echo -e "${BOLD}${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}\n"

    log "${BLUE}Analyzing disk usage...${NC}"
    
    # Calculate sizes BEFORE cleanup
    local apt_cache_size="0"
    local journal_size="0"
    local tmp_size="0"
    local thumb_size="0"
    local old_kernels_count=0
    
    # APT cache (Debian/Ubuntu)
    if [[ -d /var/cache/apt/archives ]]; then
        apt_cache_size=$(du -sh /var/cache/apt/archives 2>/dev/null | awk '{print $1}')
    fi
    
    # Journal logs
    if command -v journalctl &>/dev/null; then
        journal_size=$(journalctl --disk-usage 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)?[KMGT]?' | head -1)
    fi
    
    # Temp files older than 7 days
    if [[ -d /tmp ]]; then
        tmp_size=$(find /tmp -type f -atime +7 2>/dev/null | xargs du -ch 2>/dev/null | tail -1 | awk '{print $1}')
    fi
    
    # Thumbnail cache
    if [[ -d /home ]]; then
        thumb_size=$(find /home -type d -name ".cache" -exec find {} -name "thumbnails" -type d \; 2>/dev/null | xargs du -ch 2>/dev/null | tail -1 | awk '{print $1}')
    fi
    
    # Old kernels (Ubuntu/Debian)
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        old_kernels_count=$(dpkg -l 'linux-image-*' 2>/dev/null | grep -c '^ii' || echo 0)
        old_kernels_count=$((old_kernels_count - 1))  # Exclude current kernel
        [[ $old_kernels_count -lt 0 ]] && old_kernels_count=0
    fi

    echo -e "\n${BOLD}Items that can be safely cleaned:${NC}\n"
    echo -e "  ${GREEN}[1]${NC} APT package cache              ${CYAN}~${apt_cache_size:-0}${NC}"
    echo -e "  ${GREEN}[2]${NC} Old journal logs (keep 7 days) ${CYAN}~${journal_size:-0}${NC}"
    echo -e "  ${GREEN}[3]${NC} Temp files older than 7 days   ${CYAN}~${tmp_size:-0}${NC}"
    echo -e "  ${GREEN}[4]${NC} Thumbnail caches               ${CYAN}~${thumb_size:-0}${NC}"
    [[ $old_kernels_count -gt 0 ]] && echo -e "  ${GREEN}[5]${NC} Old kernel images              ${CYAN}($old_kernels_count old kernels)${NC}"
    echo -e "  ${GREEN}[A]${NC} Clean ALL of the above"
    echo -e "  ${RED}[0]${NC} Cancel and go back"
    
    echo -e "\n${DIM}Note: This cleanup is safe and won't delete any user data or important system files.${NC}"
    read -rp "Choose option: " cleanup_choice

    case $cleanup_choice in
        1)
            log "${YELLOW}Cleaning APT cache...${NC}"
            apt-get clean -y 2>/dev/null || yum clean all 2>/dev/null
            log "${GREEN}APT cache cleaned.${NC}"
            ;;
        2)
            log "${YELLOW}Cleaning old journal logs (keeping last 7 days)...${NC}"
            journalctl --vacuum-time=7d 2>/dev/null
            log "${GREEN}Journal logs cleaned.${NC}"
            ;;
        3)
            log "${YELLOW}Cleaning temp files older than 7 days...${NC}"
            find /tmp -type f -atime +7 -delete 2>/dev/null
            find /var/tmp -type f -atime +7 -delete 2>/dev/null
            log "${GREEN}Old temp files cleaned.${NC}"
            ;;
        4)
            log "${YELLOW}Cleaning thumbnail caches...${NC}"
            find /home -type d -name ".cache" -exec find {} -name "thumbnails" -type d -exec rm -rf {} \; \; 2>/dev/null
            log "${GREEN}Thumbnail caches cleaned.${NC}"
            ;;
        5)
            if [[ $old_kernels_count -gt 0 ]]; then
                log "${YELLOW}Removing old kernel images...${NC}"
                if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
                    apt-get autoremove --purge -y
                fi
                log "${GREEN}Old kernels removed.${NC}"
            else
                log "${BLUE}No old kernels to remove.${NC}"
            fi
            ;;
        [Aa])
            log "${YELLOW}Performing full safe cleanup...${NC}"
            
            # APT/YUM cache
            apt-get clean -y 2>/dev/null || yum clean all 2>/dev/null
            apt-get autoremove -y 2>/dev/null || yum autoremove -y 2>/dev/null
            
            # Journal logs
            journalctl --vacuum-time=7d 2>/dev/null
            
            # Temp files
            find /tmp -type f -atime +7 -delete 2>/dev/null
            find /var/tmp -type f -atime +7 -delete 2>/dev/null
            
            # Thumbnail caches
            find /home -type d -name ".cache" -exec find {} -name "thumbnails" -type d -exec rm -rf {} \; \; 2>/dev/null
            
            log "${GREEN}Full cleanup completed!${NC}"
            ;;
        0|*)
            log "Cleanup cancelled."
            return
            ;;
    esac

    # Show disk usage after cleanup
    echo -e "\n${BOLD}Current disk usage:${NC}"
    df -h / | tail -1 | awk '{print "  Root partition: " $3 " used of " $2 " (" $5 " full)"}'
    sleep 2
}

# ------------------------ Plesk Functions ------------------------
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
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}           ${BOLD}${CYAN}BU-TOOLKIT${NC} ${DIM}v${SCRIPT_VERSION}${NC}                              ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}║${NC}           ${DIM}Server Management Toolkit${NC}                        ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}║${NC}           ${DIM}burakurer.dev${NC}                                    ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${BOLD}${GREEN}📊 System & Info${NC}"
    echo -e "   ${GREEN}[1]${NC}  System Information"
    echo -e "   ${GREEN}[2]${NC}  Check for system updates"
    echo -e "   ${GREEN}[3]${NC}  Synchronize server time (Europe/Istanbul)"
    
    echo -e "\n${BOLD}${CYAN}📦 Package Installation${NC}"
    echo -e "   ${CYAN}[4]${NC}  Install recommended packages (wget, curl, nano, htop, btop)"
    echo -e "   ${CYAN}[5]${NC}  Install Node.js (via NVM)"
    echo -e "   ${CYAN}[6]${NC}  Install Redis"
    echo -e "   ${CYAN}[7]${NC}  Install Memcached"
    
    echo -e "\n${BOLD}${MAGENTA}🖥️  Plesk Panel${NC}"
    echo -e "   ${MAGENTA}[8]${NC}  Install Plesk"
    echo -e "   ${MAGENTA}[9]${NC}  Delete all Plesk backups"
    echo -e "   ${MAGENTA}[10]${NC} Fix Plesk cURL error 77"
    
    echo -e "\n${BOLD}${YELLOW}🧹 Maintenance${NC}"
    echo -e "   ${YELLOW}[11]${NC} Safe Disk Cleanup"
    
    echo -e "\n${BOLD}${RED}[0]${NC}  Exit"
    echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"
    
    read -rp "Enter an option: " choice

    case $choice in
        1) showSystemInfo ;;
        2) updateSystem ;;
        3) dateSync ;;
        4) installRecommendedPackages ;;
        5) installNodeJS ;;
        6) installRedis ;;
        7) installMemcached ;;
        8) installPlesk ;;
        9) removePleskBackups ;;
        10) fixPleskCurlError ;;
        11) diskCleanup ;;
        0)
            echo -e "\n${CYAN}Goodbye! 👋${NC}"
            log "Exiting script as requested."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option! Please try again.${NC}"
            sleep 1
            ;;
    esac

    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
done
