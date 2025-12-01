#!/bin/bash

#######################################################
#                                                     #
#     Author      : burakurer.dev                     #
#     Script      : install.sh                        #
#     Description : BU-Scripts Installer              #
#     Version     : 1.1.0                             #
#     Last Update : 01/12/2025                        #
#     Website     : https://burakurer.dev             #
#     Github      : https://github.com/burakurer      #
#                                                     #
#######################################################

set -uo pipefail

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

# ------------------------ Configuration ------------------------
GITHUB_RAW_URL="https://raw.githubusercontent.com/burakurer/bash-scripts/master"
INSTALL_DIR="."

# Available scripts
declare -A SCRIPTS=(
    ["bu-toolkit"]="bu-toolkit.sh|Server Management Toolkit"
    ["bu-clamav"]="bu-clamav.sh|ClamAV Antivirus Manager"
    ["dd-benchmark"]="bu-benchmark.sh|Disk I/O Benchmark"
)

# ------------------------ Helper Functions ------------------------
print_banner() {
    clear
    echo -e "${BOLD}${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║    ██████╗ ██╗   ██╗    ███████╗ ██████╗██████╗ ██╗██████╗   ║"
    echo "║    ██╔══██╗██║   ██║    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗  ║"
    echo "║    ██████╔╝██║   ██║    ███████╗██║     ██████╔╝██║██████╔╝  ║"
    echo "║    ██╔══██╗██║   ██║    ╚════██║██║     ██╔══██╗██║██╔═══╝   ║"
    echo "║    ██████╔╝╚██████╔╝    ███████║╚██████╗██║  ██║██║██║       ║"
    echo "║    ╚═════╝  ╚═════╝     ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝       ║"
    echo "║                                                              ║"
    echo "║                    Installer v1.1.0                          ║"
    echo "║                    burakurer.dev                             ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    log_info "Checking requirements..."
    
    # Check for curl or wget
    if command -v curl &>/dev/null; then
        DOWNLOADER="curl"
        log_success "curl found"
    elif command -v wget &>/dev/null; then
        DOWNLOADER="wget"
        log_success "wget found"
    else
        log_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    echo
}

download_file() {
    local url="$1"
    local output="$2"
    
    if [[ "$DOWNLOADER" == "curl" ]]; then
        curl -fsSL "$url" -o "$output" 2>/dev/null
    else
        wget -q "$url" -O "$output" 2>/dev/null
    fi
}

install_script() {
    local name="$1"
    local filename="${SCRIPTS[$name]%%|*}"
    local description="${SCRIPTS[$name]#*|}"
    local url="${GITHUB_RAW_URL}/${filename}"
    local target="${INSTALL_DIR}/${filename}"
    
    echo -ne "  ${CYAN}→${NC} Downloading ${BOLD}${name}${NC}... "
    
    if download_file "$url" "$target"; then
        chmod +x "$target"
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

install_all() {
    log_info "Downloading all scripts to current directory..."
    echo
    
    local success=0
    local failed=0
    
    for script in "${!SCRIPTS[@]}"; do
        if install_script "$script"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    echo
    log_success "Download complete: ${success} downloaded, ${failed} failed"
}

install_selected() {
    echo -e "\n${BOLD}Available Scripts:${NC}\n"
    
    local i=1
    local script_list=()
    for script in "${!SCRIPTS[@]}"; do
        local filename="${SCRIPTS[$script]%%|*}"
        local description="${SCRIPTS[$script]#*|}"
        echo -e "  ${GREEN}[$i]${NC} ${BOLD}${script}${NC}"
        echo -e "      ${DIM}${description}${NC}"
        echo -e "      ${DIM}File: ${filename}${NC}"
        echo
        script_list+=("$script")
        ((i++))
    done
    
    echo -e "  ${CYAN}[A]${NC} Download all scripts"
    echo -e "  ${RED}[0]${NC} Cancel"
    echo
    
    read -rp "Enter your choice (comma-separated for multiple, e.g., 1,2): " choice
    
    if [[ "$choice" == "0" ]]; then
        log_info "Installation cancelled."
        exit 0
    fi
    
    if [[ "$choice" =~ ^[Aa]$ ]]; then
        install_all
        return
    fi
    
    echo
    log_info "Downloading selected scripts..."
    echo
    
    local success=0
    local failed=0
    
    IFS=',' read -ra selections <<< "$choice"
    for sel in "${selections[@]}"; do
        sel=$(echo "$sel" | tr -d ' ')
        if [[ "$sel" =~ ^[0-9]+$ ]] && [[ $sel -ge 1 ]] && [[ $sel -le ${#script_list[@]} ]]; then
            local script="${script_list[$((sel-1))]}"
            if install_script "$script"; then
                ((success++))
            else
                ((failed++))
            fi
        else
            log_warning "Invalid selection: $sel"
        fi
    done
    
    echo
    log_success "Download complete: ${success} downloaded, ${failed} failed"
}

show_usage() {
    echo
    echo -e "${BOLD}Scripts downloaded to: ${CYAN}$(pwd)${NC}"
    echo
    echo -e "${BOLD}Usage:${NC}"
    echo
    
    for script in "${!SCRIPTS[@]}"; do
        local filename="${SCRIPTS[$script]%%|*}"
        local description="${SCRIPTS[$script]#*|}"
        echo -e "  ${GREEN}sudo ./${filename}${NC}  - ${description}"
    done
    
    echo
    echo -e "${DIM}Note: Scripts will auto-update when a new version is available.${NC}"
    echo
}

# ------------------------ Main ------------------------
main() {
    print_banner
    check_requirements
    
    echo -e "${BOLD}What would you like to do?${NC}\n"
    echo -e "  ${GREEN}[1]${NC} Download all scripts"
    echo -e "  ${CYAN}[2]${NC} Select scripts to download"
    echo -e "  ${DIM}[0]${NC} Exit"
    echo
    
    read -rp "Enter your choice: " main_choice
    
    case $main_choice in
        1)
            echo
            install_all
            show_usage
            ;;
        2)
            install_selected
            show_usage
            ;;
        0|*)
            echo -e "\n${CYAN}Goodbye! 👋${NC}\n"
            exit 0
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            print_banner
            check_requirements
            install_all
            show_usage
            exit 0
            ;;
        --help|-h)
            echo "BU-Scripts Installer"
            echo
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Options:"
            echo "  --all        Download all scripts without prompts"
            echo "  --help, -h   Show this help message"
            echo
            echo "Examples:"
            echo "  $0           # Interactive installer"
            echo "  $0 --all     # Download all scripts"
            echo
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

main
