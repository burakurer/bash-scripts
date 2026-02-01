#!/bin/bash
#===============================================================================
#
#          FILE: bu-tools.sh
#
#         USAGE: ./bu-tools.sh [module] [options]
#
#   DESCRIPTION: Modüler Bash Framework - Gelişmiş modül ve hata yönetimi
#
#        AUTHOR: burakurer (burakurer.dev)
#       CREATED: 2026-02-01
#       VERSION: 1.0.0
#
#===============================================================================

#===============================================================================
# CONFIGURATION - Buradan yapılandırın
#===============================================================================
SCRIPT_NAME="BU-TOOLS"
SCRIPT_VERSION="1.0.0"
SCRIPT_AUTHOR="burakurer (burakurer.dev)"
GITHUB_REPO="burakurer/bash-scripts"
GITHUB_BRANCH="master"
GITHUB_VERSION_FILE="version.txt"
AUTO_UPDATE_CHECK="true"
LOG_FILE="/tmp/bu-tools.log"

#===============================================================================
# RENK TANIMLARI
#===============================================================================
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

#===============================================================================
# GLOBAL DEĞİŞKENLER
#===============================================================================
declare -a MODULE_NAMES=()
declare -a MODULE_DESCRIPTIONS=()
declare -a MODULE_VERSIONS=()
declare -a MODULE_CALLBACKS=()
declare -a LOADED_MODULES=()
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"

# Sabit genişlik
readonly BOX_WIDTH=62

#===============================================================================
# HATA YÖNETİMİ
#===============================================================================
error_handler() {
    local exit_code=$1
    local line_no=$2
    local last_command=$3
    
    log "ERROR" "Hata kodu: $exit_code"
    log "ERROR" "Satır: $line_no"
    log "ERROR" "Komut: $last_command"
    
    msg_error "Bir hata oluştu! (Satır: $line_no, Kod: $exit_code)"
    msg_error "Komut: $last_command"
}

cleanup() {
    log "INFO" "Script sonlandırılıyor..."
}

trap 'error_handler $? $LINENO "$BASH_COMMAND"' ERR
trap 'cleanup' EXIT

#===============================================================================
# LOG FONKSİYONLARI
#===============================================================================
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

#===============================================================================
# MESAJ FONKSİYONLARI - Tutarlı çıktı formatı
#===============================================================================
print_line() {
    local char="${1:-─}"
    local width="${2:-$BOX_WIDTH}"
    printf "${CYAN}"
    for ((i=0; i<width; i++)); do printf "%s" "$char"; done
    printf "${RESET}\n"
}

print_box_top() {
    printf "${CYAN}╭"
    for ((i=0; i<BOX_WIDTH; i++)); do printf "─"; done
    printf "╮${RESET}\n"
}

print_box_bottom() {
    printf "${CYAN}╰"
    for ((i=0; i<BOX_WIDTH; i++)); do printf "─"; done
    printf "╯${RESET}\n"
}

print_box_separator() {
    printf "${CYAN}├"
    for ((i=0; i<BOX_WIDTH; i++)); do printf "─"; done
    printf "┤${RESET}\n"
}

print_box_line() {
    local text="$1"
    local color="${2:-$WHITE}"
    local text_len=${#text}
    local padding=$((BOX_WIDTH - text_len - 2))
    
    printf "${CYAN}│${RESET} ${color}%s${RESET}" "$text"
    for ((i=0; i<padding; i++)); do printf " "; done
    printf " ${CYAN}│${RESET}\n"
}

print_box_center() {
    local text="$1"
    local color="${2:-$WHITE}"
    local text_len=${#text}
    local left_pad=$(( (BOX_WIDTH - text_len) / 2 ))
    local right_pad=$((BOX_WIDTH - text_len - left_pad))
    
    printf "${CYAN}│${RESET}"
    for ((i=0; i<left_pad; i++)); do printf " "; done
    printf "${color}%s${RESET}" "$text"
    for ((i=0; i<right_pad; i++)); do printf " "; done
    printf "${CYAN}│${RESET}\n"
}

print_box_empty() {
    printf "${CYAN}│"
    for ((i=0; i<BOX_WIDTH; i++)); do printf " "; done
    printf "│${RESET}\n"
}

# Standart mesaj fonksiyonları
msg_success() {
    printf "${GREEN}│ ✓ │${RESET} %s\n" "$1"
}

msg_error() {
    printf "${RED}│ ✗ │${RESET} %s\n" "$1"
}

msg_warning() {
    printf "${YELLOW}│ ⚠ │${RESET} %s\n" "$1"
}

msg_info() {
    printf "${CYAN}│ ℹ │${RESET} %s\n" "$1"
}

msg_step() {
    printf "${MAGENTA}│ ➤ │${RESET} %s\n" "$1"
}

#===============================================================================
# ASCII BANNER
#===============================================================================
show_banner() {
    local version="v$SCRIPT_VERSION"
    local author="by $SCRIPT_AUTHOR"
    
    echo ""
    printf "${MAGENTA}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                       ║
║    ███████████  █████  █████            ███████████                   ████            ║
║   ░░███░░░░░███░░███  ░░███            ░█░░░███░░░█                  ░░███            ║
║    ░███    ░███ ░███   ░███            ░   ░███  ░   ██████   ██████  ░███   █████    ║
║    ░██████████  ░███   ░███  ██████████    ░███     ███░░███ ███░░███ ░███  ███░░     ║
║    ░███░░░░░███ ░███   ░███ ░░░░░░░░░░     ░███    ░███ ░███░███ ░███ ░███ ░░█████    ║
║    ░███    ░███ ░███   ░███                ░███    ░███ ░███░███ ░███ ░███  ░░░░███   ║
║    ███████████  ░░████████                 █████   ░░██████ ░░██████  █████ ██████    ║
║   ░░░░░░░░░░░    ░░░░░░░░                 ░░░░░     ░░░░░░   ░░░░░░  ░░░░░ ░░░░░░     ║
║                                                                                       ║
EOF
    printf "${RESET}"
    
    # Versiyon ve yazar bilgisi
    printf "${MAGENTA}║${RESET}"
    printf "${DIM}                        %s  •  %s${RESET}" "$version" "$author"
    local info_text="$version  •  $author"
    local info_len=$((22 + ${#info_text}))
    local remaining=$((62 - info_len))
    for ((i=0; i<remaining; i++)); do printf " "; done
    printf "${MAGENTA}                       ║${RESET}\n"
    
    printf "${MAGENTA}╚═══════════════════════════════════════════════════════════════════════════════════════╝${RESET}\n"
    echo ""
}

#===============================================================================
# GÜNCELLEME KONTROLÜ
#===============================================================================
check_for_updates() {
    if [[ "$AUTO_UPDATE_CHECK" != "true" ]]; then
        return 0
    fi
    
    msg_info "Güncelleme kontrolü yapılıyor..."
    
    local repo="$GITHUB_REPO"
    local branch="$GITHUB_BRANCH"
    local version_file="$GITHUB_VERSION_FILE"
    local current_version="$SCRIPT_VERSION"
    
    local raw_url="https://raw.githubusercontent.com/${repo}/${branch}/${version_file}"
    
    local remote_version=""
    if command -v curl &> /dev/null; then
        remote_version=$(curl -sL --connect-timeout 5 "$raw_url" 2>/dev/null || echo "")
    elif command -v wget &> /dev/null; then
        remote_version=$(wget -qO- --timeout=5 "$raw_url" 2>/dev/null || echo "")
    else
        msg_warning "curl veya wget bulunamadı. Güncelleme kontrolü yapılamıyor."
        return 1
    fi
    
    if [[ -z "$remote_version" ]]; then
        msg_warning "Güncelleme kontrolü yapılamadı (ağ hatası veya dosya bulunamadı)"
        return 1
    fi
    
    remote_version=$(echo "$remote_version" | tr -d '[:space:]')
    
    if [[ "$remote_version" != "$current_version" ]]; then
        echo ""
        print_box_top
        print_box_center "🔄 YENİ GÜNCELLEME MEVCUT!" "$YELLOW"
        print_box_separator
        print_box_line "Mevcut versiyon: $current_version" "$WHITE"
        print_box_line "Yeni versiyon:   $remote_version" "$GREEN"
        print_box_empty
        print_box_line "Güncellemek için: ./$(basename "$0") --update" "$DIM"
        print_box_bottom
        echo ""
    else
        msg_success "Script güncel (v$current_version)"
    fi
    
    return 0
}

perform_update() {
    local repo="$GITHUB_REPO"
    local branch="$GITHUB_BRANCH"
    local script_name
    script_name=$(basename "$SCRIPT_PATH")
    
    local raw_url="https://raw.githubusercontent.com/${repo}/${branch}/${script_name}"
    
    msg_info "Güncelleme indiriliyor..."
    
    local tmp_file="/tmp/${script_name}.tmp"
    
    if curl -sL "$raw_url" -o "$tmp_file" 2>/dev/null; then
        if [[ -s "$tmp_file" ]]; then
            cp "$SCRIPT_PATH" "${SCRIPT_PATH}.backup"
            mv "$tmp_file" "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"
            
            msg_success "Güncelleme başarılı!"
            msg_info "Yedek: ${SCRIPT_PATH}.backup"
            msg_info "Lütfen scripti yeniden çalıştırın."
            exit 0
        else
            msg_error "İndirilen dosya boş!"
            rm -f "$tmp_file"
            return 1
        fi
    else
        msg_error "Güncelleme indirilemedi!"
        return 1
    fi
}

#===============================================================================
# MODÜL SİSTEMİ
#===============================================================================

register_module() {
    local name="$1"
    local description="$2"
    local version="${3:-1.0.0}"
    local callback="$4"
    
    MODULE_NAMES+=("$name")
    MODULE_DESCRIPTIONS+=("$description")
    MODULE_VERSIONS+=("$version")
    MODULE_CALLBACKS+=("$callback")
    
    log "INFO" "Modül kaydedildi: $name (v$version)"
}

get_module_index() {
    local name="$1"
    local i
    for i in "${!MODULE_NAMES[@]}"; do
        if [[ "${MODULE_NAMES[$i]}" == "$name" ]]; then
            echo "$i"
            return 0
        fi
    done
    echo "-1"
    return 1
}

run_module() {
    local name="$1"
    shift
    local args=("$@")
    
    local idx
    idx=$(get_module_index "$name")
    
    if [[ "$idx" == "-1" ]]; then
        msg_error "Modül bulunamadı: $name"
        return 1
    fi
    
    local callback="${MODULE_CALLBACKS[$idx]}"
    
    if declare -f "$callback" > /dev/null; then
        msg_step "Modül çalıştırılıyor: $name"
        echo ""
        LOADED_MODULES+=("$name")
        "$callback" "${args[@]}"
    else
        msg_error "Modül fonksiyonu bulunamadı: $callback"
        return 1
    fi
}

show_modules() {
    echo ""
    print_box_top
    print_box_center "📦 KAYITLI MODÜLLER" "$BOLD"
    print_box_separator
    
    if [[ ${#MODULE_NAMES[@]} -eq 0 ]]; then
        print_box_line "Kayıtlı modül bulunamadı." "$DIM"
    else
        local i
        for i in "${!MODULE_NAMES[@]}"; do
            local name="${MODULE_NAMES[$i]}"
            local desc="${MODULE_DESCRIPTIONS[$i]}"
            local ver="${MODULE_VERSIONS[$i]}"
            
            # Format: name (vX.X.X) - description (tek satır)
            printf "${CYAN}│${RESET} ${GREEN}%-12s${RESET} ${DIM}v%-6s${RESET} %s" "$name" "$ver" "$desc"
            local line_len=$((1 + 12 + 1 + 1 + ${#ver} + 1 + ${#desc}))
            local pad=$((BOX_WIDTH - line_len))
            for ((j=0; j<pad; j++)); do printf " "; done
            printf " ${CYAN}│${RESET}\n"
        done
    fi
    
    print_box_bottom
    echo ""
}

#===============================================================================
# YARDIMCI FONKSİYONLAR
#===============================================================================

check_dependency() {
    local cmd="$1"
    local install_hint="${2:-}"
    
    if ! command -v "$cmd" &> /dev/null; then
        msg_error "'$cmd' bulunamadı!"
        [[ -n "$install_hint" ]] && msg_info "Kurulum: $install_hint"
        return 1
    fi
    return 0
}

confirm() {
    local message="${1:-Devam etmek istiyor musunuz?}"
    local default="${2:-n}"
    
    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="[E/h]"
    else
        prompt="[e/H]"
    fi
    
    printf "${YELLOW}│ ? │${RESET} %s %s: " "$message" "$prompt"
    read -r response
    response=${response:-$default}
    
    [[ "$response" =~ ^[EeYy]$ ]]
}

show_spinner() {
    local pid=$1
    local message="${2:-İşlem yapılıyor...}"
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while kill -0 "$pid" 2>/dev/null; do
        local i
        for (( i=0; i<${#spinstr}; i++ )); do
            printf "\r${CYAN}│ %s │${RESET} %s" "${spinstr:$i:1}" "$message"
            sleep 0.1
        done
    done
    printf "\r%*s\r" $((${#message} + 8)) ""
}

#===============================================================================
# ÖRNEK MODÜLLER - Kendi modüllerinizi buraya ekleyin
#===============================================================================

# ============ MODÜL: system_info ============
module_system_info() {
    print_box_top
    print_box_center "🖥️  SYSTEM INFORMATION" "$BOLD"
    print_box_bottom
    echo ""
    
    # ─────────────────────────────────────────────────────────────
    # İşletim Sistemi Bilgileri
    # ─────────────────────────────────────────────────────────────
    printf "${BOLD}Operating System:${RESET}\n"
    
    local os_name
    if [[ "$(uname)" == "Darwin" ]]; then
        os_name="macOS $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"
    elif [[ -f /etc/os-release ]]; then
        os_name=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2)
    else
        os_name="$(uname -s) $(uname -r)"
    fi
    
    printf "  ${CYAN}OS:${RESET}         %s\n" "$os_name"
    printf "  ${CYAN}Kernel:${RESET}     %s\n" "$(uname -r)"
    printf "  ${CYAN}Arch:${RESET}       %s\n" "$(uname -m)"
    printf "  ${CYAN}Hostname:${RESET}   %s\n" "$(hostname)"
    
    # ─────────────────────────────────────────────────────────────
    # Uptime
    # ─────────────────────────────────────────────────────────────
    printf "\n${BOLD}Uptime:${RESET}\n"
    
    local uptime_info boot_time
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        local boot_sec
        boot_sec=$(sysctl -n kern.boottime 2>/dev/null | awk -F'[= ,]' '{print $4}')
        if [[ -n "$boot_sec" ]]; then
            boot_time=$(date -r "$boot_sec" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "N/A")
        fi
        uptime_info=$(uptime | sed 's/.*up //' | sed 's/,.*//')
    else
        # Linux
        boot_time=$(uptime -s 2>/dev/null || echo "N/A")
        uptime_info=$(uptime -p 2>/dev/null | sed 's/up //' || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    fi
    
    printf "  ${CYAN}Up since:${RESET}   %s\n" "${boot_time:-N/A}"
    printf "  ${CYAN}Uptime:${RESET}     %s\n" "${uptime_info:-N/A}"
    
    # ─────────────────────────────────────────────────────────────
    # CPU Bilgileri
    # ─────────────────────────────────────────────────────────────
    printf "\n${BOLD}CPU:${RESET}\n"
    
    local cpu_model cpu_cores load_avg
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        cpu_model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
        cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "N/A")
        load_avg=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2, $3, $4}' || uptime | awk -F'load averages?: ' '{print $2}')
    else
        # Linux
        if command -v lscpu &>/dev/null; then
            cpu_model=$(lscpu | grep "Model name" | sed 's/Model name:[[:space:]]*//')
            cpu_cores=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
            local cpu_threads
            cpu_threads=$(lscpu | grep "Thread(s) per core" | awk '{print $4}')
            [[ -n "$cpu_threads" ]] && cpu_cores="$cpu_cores ($cpu_threads threads/core)"
        else
            cpu_model=$(cat /proc/cpuinfo 2>/dev/null | grep "model name" | head -1 | cut -d':' -f2 | xargs)
            cpu_cores=$(nproc 2>/dev/null || grep -c processor /proc/cpuinfo 2>/dev/null || echo "N/A")
        fi
        load_avg=$(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}' || uptime | awk -F'load average: ' '{print $2}')
    fi
    
    printf "  ${CYAN}Model:${RESET}      %s\n" "${cpu_model:-Unknown}"
    printf "  ${CYAN}Cores:${RESET}      %s\n" "${cpu_cores:-N/A}"
    printf "  ${CYAN}Load Avg:${RESET}   %s\n" "${load_avg:-N/A}"
    
    # ─────────────────────────────────────────────────────────────
    # Bellek Bilgileri
    # ─────────────────────────────────────────────────────────────
    printf "\n${BOLD}Memory:${RESET}\n"
    
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        local mem_total_bytes mem_total_gb page_size pages_free mem_free_gb
        mem_total_bytes=$(sysctl -n hw.memsize 2>/dev/null)
        mem_total_gb=$(awk "BEGIN {printf \"%.1f\", $mem_total_bytes/1024/1024/1024}")
        
        # vm_stat çıktısını parse et
        page_size=$(vm_stat 2>/dev/null | head -1 | grep -oE '[0-9]+')
        pages_free=$(vm_stat 2>/dev/null | grep "Pages free" | awk '{print $3}' | tr -d '.')
        if [[ -n "$page_size" && -n "$pages_free" ]]; then
            mem_free_gb=$(awk "BEGIN {printf \"%.1f\", ($pages_free * $page_size)/1024/1024/1024}")
        fi
        
        printf "  ${CYAN}Total:${RESET}      %s GB\n" "${mem_total_gb:-N/A}"
        printf "  ${CYAN}Free:${RESET}       %s GB\n" "${mem_free_gb:-N/A}"
    else
        # Linux
        if command -v free &>/dev/null; then
            local mem_total mem_used mem_free mem_available swap_total swap_used
            mem_total=$(free -h | awk '/^Mem:/ {print $2}')
            mem_used=$(free -h | awk '/^Mem:/ {print $3}')
            mem_free=$(free -h | awk '/^Mem:/ {print $4}')
            mem_available=$(free -h | awk '/^Mem:/ {print $7}')
            swap_total=$(free -h | awk '/^Swap:/ {print $2}')
            swap_used=$(free -h | awk '/^Swap:/ {print $3}')
            
            printf "  ${CYAN}Total:${RESET}      %s\n" "$mem_total"
            printf "  ${CYAN}Used:${RESET}       %s\n" "$mem_used"
            printf "  ${CYAN}Free:${RESET}       %s\n" "$mem_free"
            printf "  ${CYAN}Available:${RESET}  %s\n" "$mem_available"
            printf "  ${CYAN}Swap:${RESET}       %s / %s\n" "$swap_used" "$swap_total"
        fi
    fi
    
    # ─────────────────────────────────────────────────────────────
    # Disk Bilgileri
    # ─────────────────────────────────────────────────────────────
    printf "\n${BOLD}Disk Usage:${RESET}\n"
    
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        df -h | grep -E '^/dev/' | head -5 | while read -r line; do
            printf "  %s\n" "$line"
        done
    else
        # Linux
        df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs 2>/dev/null | head -6 | while read -r line; do
            printf "  %s\n" "$line"
        done
    fi
    
    # ─────────────────────────────────────────────────────────────
    # Ağ Bilgileri
    # ─────────────────────────────────────────────────────────────
    printf "\n${BOLD}Network:${RESET}\n"
    
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print "  " $2}' | head -5
    elif command -v ip &>/dev/null; then
        # Linux with ip command
        ip -4 addr show 2>/dev/null | grep inet | grep -v '127.0.0.1' | awk '{print "  " $NF ": " $2}' | head -5
    elif command -v ifconfig &>/dev/null; then
        # Fallback to ifconfig
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print "  " $2}' | head -5
    fi
    
    # Public IP
    local public_ip
    public_ip=$(curl -s --connect-timeout 3 ifconfig.me 2>/dev/null || echo "N/A")
    printf "  ${CYAN}Public IP:${RESET}  %s\n" "$public_ip"
    
    echo ""
    print_line "─"
}

#===============================================================================
# MODÜL: benchmark - Disk I/O Performans Testi
#===============================================================================
# Versiyon: 2.4.0
# Açıklama: dd kullanarak disk okuma/yazma performansını ölçer
#===============================================================================

# Benchmark için geçici dosyalar
declare -a BENCH_TEMP_FILES=()

# Benchmark temizlik fonksiyonu
_bench_cleanup() {
    for f in "${BENCH_TEMP_FILES[@]}"; do
        rm -f "$f" 2>/dev/null
    done
    BENCH_TEMP_FILES=()
}

# dd çıktısından hız değerini parse et (MB/s olarak döner)
_bench_parse_speed() {
    local output="$1"
    local speed_line val unit mbps

    speed_line=$(echo "$output" | tail -n1)
    
    if echo "$speed_line" | grep -qE '[0-9]+([.,][0-9]+)?\s*(GB|MB|KB|kB|GiB|MiB|KiB|B)/s'; then
        val=$(echo "$speed_line" | grep -oE '[0-9]+([.,][0-9]+)?\s*(GB|MB|KB|kB|GiB|MiB|KiB|B)/s' | tail -1 | awk '{gsub(",", "."); print $1}')
        unit=$(echo "$speed_line" | grep -oE '[0-9]+([.,][0-9]+)?\s*(GB|MB|KB|kB|GiB|MiB|KiB|B)/s' | tail -1 | awk '{print $2}')
    else
        val=$(echo "$speed_line" | grep -oE '[0-9]+([.,][0-9]+)?' | tail -1 | sed 's/,/./')
        if echo "$speed_line" | grep -qiE 'GB/s|GiB/s'; then unit="GB/s"
        elif echo "$speed_line" | grep -qiE 'MB/s|MiB/s'; then unit="MB/s"
        elif echo "$speed_line" | grep -qiE 'KB/s|KiB/s|kB/s'; then unit="KB/s"
        else unit="B/s"; fi
    fi
    
    [[ -z "$val" || "$val" == "0" ]] && { echo "0"; return 0; }
    val=$(echo "$val" | sed 's/,/./')

    case "$unit" in
        kB/s|KB/s)  mbps=$(awk -v v="$val" 'BEGIN{printf "%.2f", v/1000}') ;;
        KiB/s)      mbps=$(awk -v v="$val" 'BEGIN{printf "%.2f", v/1024}') ;;
        MB/s)       mbps=$(awk -v v="$val" 'BEGIN{printf "%.2f", v}') ;;
        MiB/s)      mbps=$(awk -v v="$val" 'BEGIN{printf "%.2f", v*1.048576}') ;;
        GB/s)       mbps=$(awk -v v="$val" 'BEGIN{printf "%.2f", v*1000}') ;;
        GiB/s)      mbps=$(awk -v v="$val" 'BEGIN{printf "%.2f", v*1073.741824}') ;;
        B/s)        mbps=$(awk -v v="$val" 'BEGIN{printf "%.6f", v/1000000}') ;;
        *)          mbps="$val" ;;
    esac
    echo "$mbps"
}

# dd testini çalıştır
_bench_run_test() {
    local description="$1"
    local dd_cmd="$2"
    local test_num="$3"
    local iterations="${4:-1}"
    local total_mbps=0

    msg_step "[Test $test_num] $description"

    for ((i=1; i<=iterations; i++)); do
        [[ $iterations -gt 1 ]] && printf "  ${DIM}Iteration $i/$iterations...${RESET}\n"
        
        # Root ise cache temizle
        if [[ $EUID -eq 0 ]]; then
            sync
            echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        fi

        local output
        output=$(eval "$dd_cmd" 2>&1)
        local speed
        speed=$(_bench_parse_speed "$output")
        total_mbps=$(awk -v t="$total_mbps" -v s="$speed" 'BEGIN{printf "%.2f", t+s}')
    done

    local avg_mbps
    avg_mbps=$(awk -v t="$total_mbps" -v n="$iterations" 'BEGIN{printf "%.2f", t/n}')
    msg_success "Hız: ${avg_mbps} MB/s"
    echo "$avg_mbps"
}

# Hız değerlendirmesi
_bench_rate_speed() {
    local test_type="$1"
    local mbps="$2"
    local rating

    case "$test_type" in
        "seq_write"|"seq_read"|"typical")
            if   awk -v m="$mbps" 'BEGIN{exit !(m < 100)}';   then rating="Kötü"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 300)}';   then rating="Orta"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 600)}';   then rating="İyi"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 1000)}';  then rating="Çok İyi"
            else rating="Mükemmel"; fi
            ;;
        "small_sync"|"random")
            if   awk -v m="$mbps" 'BEGIN{exit !(m < 0.5)}';   then rating="Kötü"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 2)}';     then rating="Orta"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 10)}';    then rating="İyi"
            else rating="Çok İyi"; fi
            ;;
        "mixed")
            if   awk -v m="$mbps" 'BEGIN{exit !(m < 50)}';    then rating="Kötü"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 150)}';   then rating="Orta"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 400)}';   then rating="İyi"
            else rating="Çok İyi"; fi
            ;;
    esac
    echo "$rating"
}

# Değerlendirmeyi renklendir
_bench_colorize() {
    local rating="$1"
    case "$rating" in
        "Kötü")    echo -e "${RED}$rating${RESET}" ;;
        "Orta")     echo -e "${YELLOW}$rating${RESET}" ;;
        "İyi")      echo -e "${GREEN}$rating${RESET}" ;;
        "Çok İyi")  echo -e "${CYAN}$rating${RESET}" ;;
        "Mükemmel") echo -e "${MAGENTA}${BOLD}$rating${RESET}" ;;
        *)          echo "$rating" ;;
    esac
}

# Skor hesapla (0-100)
_bench_calc_score() {
    local val="$1" min="$2" max="$3"
    awk -v v="$val" -v a="$min" -v b="$max" \
        'BEGIN{ if(b<=a){print 0; exit}
                x=(v-a)/(b-a); if(x<0)x=0; if(x>1)x=1; printf "%.1f", x*100 }'
}

# Ana benchmark modülü
module_benchmark() {
    local test_dir="${1:-/tmp}"
    local quick_mode="${2:-false}"
    local iterations="${3:-1}"
    
    # Bağımlılık kontrolü
    if ! command -v dd &>/dev/null; then
        msg_error "'dd' komutu bulunamadı!"
        return 1
    fi
    
    # Test dizini kontrolü
    if [[ ! -d "$test_dir" ]] || [[ ! -w "$test_dir" ]]; then
        msg_error "Test dizini '$test_dir' mevcut değil veya yazılabilir değil!"
        return 1
    fi
    
    # Geçici dosyaları ayarla
    BENCH_TEMP_FILES=(
        "$test_dir/bench_seq_write.img"
        "$test_dir/bench_small_sync.img"
        "$test_dir/bench_typical.img"
        "$test_dir/bench_mixed.img"
        "$test_dir/bench_read.img"
        "$test_dir/bench_random.img"
    )
    trap '_bench_cleanup' RETURN
    
    # Test boyutlarını ayarla
    local bs_large bs_medium count_large count_medium count_small
    if [[ "$quick_mode" == "true" || "$quick_mode" == "quick" ]]; then
        bs_large="256M"; count_large=2
        bs_medium="64k"; count_medium=4096
        count_small=500
        msg_info "Hızlı mod aktif - küçük test boyutları"
    else
        bs_large="1G"; count_large=1
        bs_medium="64k"; count_medium=16384
        count_small=1000
    fi
    
    echo ""
    print_box_top
    print_box_center "⚡ DISK BENCHMARK" "$BOLD"
    print_box_separator
    print_box_line "Test Dizini: $test_dir"
    print_box_line "Iterasyon:   $iterations"
    print_box_bottom
    echo ""
    
    local start_time
    start_time=$(date +%s)
    
    # Test 1: Sequential Write
    local mbps_seq_write
    mbps_seq_write=$(_bench_run_test \
        "Sequential Write (throughput)" \
        "dd if=/dev/zero of='${BENCH_TEMP_FILES[0]}' bs=$bs_large count=$count_large oflag=dsync 2>&1" \
        1 "$iterations")
    
    # Test 2: Small Sync Write
    local mbps_small_sync
    mbps_small_sync=$(_bench_run_test \
        "Small Block Sync Write (latency)" \
        "dd if=/dev/zero of='${BENCH_TEMP_FILES[1]}' bs=512 count=$count_small oflag=dsync 2>&1" \
        2 "$iterations")
    
    # Test 3: Typical Write
    local mbps_typical
    mbps_typical=$(_bench_run_test \
        "Typical Write (fdatasync)" \
        "dd if=/dev/zero of='${BENCH_TEMP_FILES[2]}' bs=$bs_medium count=$count_medium conv=fdatasync 2>&1" \
        3 "$iterations")
    
    # Test 4: Mixed Write
    local mixed_count=$((count_medium * 64))
    local mbps_mixed
    mbps_mixed=$(_bench_run_test \
        "Mixed/Cached Write (1KB)" \
        "dd if=/dev/zero of='${BENCH_TEMP_FILES[3]}' bs=1k count=$mixed_count 2>&1" \
        4 "$iterations")
    
    # Test 5: Sequential Read
    dd if=/dev/zero of="${BENCH_TEMP_FILES[4]}" bs=$bs_large count=$count_large conv=fdatasync 2>/dev/null
    sync
    [[ $EUID -eq 0 ]] && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    local mbps_seq_read
    mbps_seq_read=$(_bench_run_test \
        "Sequential Read" \
        "dd if='${BENCH_TEMP_FILES[4]}' of=/dev/null bs=$bs_large 2>&1" \
        5 "$iterations")
    
    # Test 6: Random I/O
    local mbps_random
    mbps_random=$(_bench_run_test \
        "Random I/O (4KB)" \
        "dd if=/dev/zero of='${BENCH_TEMP_FILES[5]}' bs=4k count=256 seek=\$((RANDOM % 1000)) conv=notrunc oflag=dsync 2>&1" \
        6 "$iterations")
    
    # Sonuçlar
    echo ""
    print_box_top
    print_box_center "📊 BENCHMARK SONUÇLARI" "$BOLD"
    print_box_separator
    
    local r1 r2 r3 r4 r5 r6
    r1=$(_bench_rate_speed "seq_write" "$mbps_seq_write")
    r2=$(_bench_rate_speed "small_sync" "$mbps_small_sync")
    r3=$(_bench_rate_speed "typical" "$mbps_typical")
    r4=$(_bench_rate_speed "mixed" "$mbps_mixed")
    r5=$(_bench_rate_speed "seq_read" "$mbps_seq_read")
    r6=$(_bench_rate_speed "random" "$mbps_random")
    
    printf "${CYAN}│${RESET} %-30s %10s MB/s  %s\n" "1. Sequential Write" "$mbps_seq_write" "$(_bench_colorize "$r1")"
    printf "${CYAN}│${RESET} %-30s %10s MB/s  %s\n" "2. Small Sync Write" "$mbps_small_sync" "$(_bench_colorize "$r2")"
    printf "${CYAN}│${RESET} %-30s %10s MB/s  %s\n" "3. Typical Write" "$mbps_typical" "$(_bench_colorize "$r3")"
    printf "${CYAN}│${RESET} %-30s %10s MB/s  %s\n" "4. Mixed/Cached Write" "$mbps_mixed" "$(_bench_colorize "$r4")"
    printf "${CYAN}│${RESET} %-30s %10s MB/s  %s\n" "5. Sequential Read" "$mbps_seq_read" "$(_bench_colorize "$r5")"
    printf "${CYAN}│${RESET} %-30s %10s MB/s  %s\n" "6. Random I/O" "$mbps_random" "$(_bench_colorize "$r6")"
    
    print_box_separator
    
    # Genel skor hesapla
    local s1 s2 s3 s4
    s1=$(_bench_calc_score "$mbps_seq_write" 50 1500)
    s2=$(_bench_calc_score "$mbps_typical" 50 1500)
    s3=$(_bench_calc_score "$mbps_seq_read" 50 2000)
    s4=$(_bench_calc_score "$mbps_mixed" 50 800)
    
    local overall_score
    overall_score=$(awk -v s1="$s1" -v s2="$s2" -v s3="$s3" -v s4="$s4" \
        'BEGIN{printf "%.1f", s1*0.25 + s2*0.30 + s3*0.25 + s4*0.20}')
    
    local overall_rating overall_color
    if   awk -v s="$overall_score" 'BEGIN{exit !(s < 25)}';  then overall_rating="Kötü"; overall_color="$RED"
    elif awk -v s="$overall_score" 'BEGIN{exit !(s < 50)}';  then overall_rating="Orta"; overall_color="$YELLOW"
    elif awk -v s="$overall_score" 'BEGIN{exit !(s < 70)}';  then overall_rating="İyi"; overall_color="$GREEN"
    elif awk -v s="$overall_score" 'BEGIN{exit !(s < 85)}';  then overall_rating="Çok İyi"; overall_color="$CYAN"
    else overall_rating="Mükemmel"; overall_color="$MAGENTA"; fi
    
    print_box_line "Genel Skor: ${overall_score}/100" "$BOLD"
    printf "${CYAN}│${RESET} Değerlendirme: ${overall_color}${BOLD}${overall_rating}${RESET}\n"
    print_box_separator
    
    local end_time duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    print_box_line "Toplam Süre: ${duration} saniye" "$DIM"
    print_box_bottom
    
    msg_success "Benchmark tamamlandı!"
}

#===============================================================================
# YENİ MODÜLÜNÜZÜ BURAYA EKLEYİN
#===============================================================================
# Şablon:
# module_your_module_name() {
#     local arg1="${1:-default_value}"
#     print_box_top
#     print_box_center "🔧 Modül Başlığı" "$BOLD"
#     print_box_separator
#     print_box_line "Bilgi satırı 1"
#     print_box_line "Bilgi satırı 2"
#     print_box_bottom
# }

#===============================================================================
# MODÜL KAYITLARI - Modüllerinizi burada kaydedin
#===============================================================================
init_modules() {
    # register_module "modül_adı" "açıklama" "versiyon" "callback_fonksiyon"
    register_module "sysinfo" "Sistem bilgilerini gösterir" "1.0.0" "module_system_info"
    register_module "benchmark" "Disk I/O performans testi" "2.4.0" "module_benchmark"
    
    # ============ YENİ MODÜL KAYITLARINIZI BURAYA EKLEYİN ============
    # register_module "your_module" "Modül açıklaması" "1.0.0" "module_your_module_name"
}

#===============================================================================
# YARDIM MENÜSÜ
#===============================================================================
show_help() {
    echo ""
    print_box_top
    print_box_center "📖 YARDIM" "$BOLD"
    print_box_separator
    print_box_line "Kullanım: $(basename "$0") [SEÇENEK] [MODÜL]" "$WHITE"
    print_box_empty
    print_box_line "Seçenekler:" "$CYAN"
    print_box_line "  -h, --help        Bu yardım mesajını göster"
    print_box_line "  -v, --version     Versiyon bilgisini göster"
    print_box_line "  -l, --list        Kayıtlı modülleri listele"
    print_box_line "  -r, --run MODULE  Belirtilen modülü çalıştır"
    print_box_line "  -u, --update      Scripti güncelle"
    print_box_empty
    print_box_line "Örnekler:" "$CYAN"
    print_box_line "  $(basename "$0") --list"
    print_box_line "  $(basename "$0") --run sysinfo"
    print_box_line "  $(basename "$0") --run process 20"
    print_box_bottom
    echo ""
}

#===============================================================================
# ANA PROGRAM
#===============================================================================
main() {
    # Modülleri yükle
    init_modules
    
    # Parametre yoksa varsayılan davranış
    if [[ $# -eq 0 ]]; then
        show_banner
        check_for_updates
        show_modules
        msg_info "Yardım için: $(basename "$0") --help"
        echo ""
        exit 0
    fi
    
    # Parametre işleme
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_banner
                show_help
                exit 0
                ;;
            -v|--version)
                echo "$SCRIPT_NAME v$SCRIPT_VERSION"
                exit 0
                ;;
            -l|--list)
                show_banner
                show_modules
                exit 0
                ;;
            -r|--run)
                if [[ -z "${2:-}" ]]; then
                    msg_error "Modül adı belirtilmedi!"
                    exit 1
                fi
                shift
                local module_name="$1"
                shift
                run_module "$module_name" "$@"
                exit 0
                ;;
            -u|--update)
                perform_update
                exit 0
                ;;
            *)
                msg_error "Bilinmeyen parametre: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Script çalıştır
main "$@"
