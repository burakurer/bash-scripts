#!/bin/bash
#===============================================================================
#
#          FILE: bu-tools.sh
#
#         USAGE: ./bu-tools.sh [module] [options]
#
#   DESCRIPTION: Modüler Bash Framework - Gelişmiş modül ve hata yönetimi
#
#        AUTHOR: burakurer
#       CREATED: 2026-02-01
#       VERSION: 1.0.0
#
#===============================================================================

#===============================================================================
# CONFIGURATION - Buradan yapılandırın
#===============================================================================
SCRIPT_NAME="BU-TOOLS"
SCRIPT_VERSION="1.0.0"
SCRIPT_AUTHOR="Burak Urer"
GITHUB_REPO="burakurer/bash-scripts"
GITHUB_BRANCH="main"
GITHUB_VERSION_FILE="version.txt"
AUTO_UPDATE_CHECK="true"
DEBUG_MODE="false"
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

msg_debug() {
    [[ "$DEBUG_MODE" == "true" ]] && printf "${DIM}│ ⚙ │${RESET} %s\n" "$1"
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
    printf "${CYAN}"
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
║    ░░░░░░░░░░░    ░░░░░░░░                 ░░░░░     ░░░░░░   ░░░░░░  ░░░░░ ░░░░░░    ║
║                                                                                       ║
EOF
    printf "${RESET}"
    
    # Versiyon ve yazar bilgisi
    printf "${CYAN}║${RESET}"
    printf "${DIM}                                %s  •  %s${RESET}" "$version" "$author"
    local info_text="$version  •  $author"
    local info_len=$((22 + ${#info_text}))
    local remaining=$((62 - info_len))
    for ((i=0; i<remaining; i++)); do printf " "; done
    printf "${CYAN}               ║${RESET}\n"
    
    printf "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════════════╝${RESET}\n"
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
            
            # Format: [name] v[version] - description
            local module_line
            module_line=$(printf "%-12s ${DIM}v%-6s${RESET} ${WHITE}%s${RESET}" "$name" "$ver" "$desc")
            print_box_line "$name" "$GREEN"
            printf "${CYAN}│${RESET}   ${DIM}v%s${RESET} - %s" "$ver" "$desc"
            local detail_len=$((4 + ${#ver} + 3 + ${#desc}))
            local pad=$((BOX_WIDTH - detail_len))
            for ((j=0; j<pad; j++)); do printf " "; done
            printf "${CYAN}│${RESET}\n"
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
    print_box_center "🖥️  Sistem Bilgileri" "$BOLD"
    print_box_separator
    print_box_line "Hostname:     $(hostname)"
    print_box_line "OS:           $(uname -s)"
    print_box_line "Kernel:       $(uname -r)"
    print_box_line "Architecture: $(uname -m)"
    print_box_line "User:         $(whoami)"
    print_box_line "Shell:        $SHELL"
    print_box_line "Date:         $(date '+%Y-%m-%d %H:%M:%S')"
    print_box_bottom
}

# ============ MODÜL: disk_usage ============
module_disk_usage() {
    print_box_top
    print_box_center "💾 Disk Kullanımı" "$BOLD"
    print_box_separator
    print_box_bottom
    df -h | head -10
    echo ""
}

# ============ MODÜL: network_info ============
module_network_info() {
    print_box_top
    print_box_center "🌐 Ağ Bilgileri" "$BOLD"
    print_box_separator
    
    # IP adresleri
    if [[ "$(uname)" == "Darwin" ]]; then
        local ips
        ips=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
        while IFS= read -r ip; do
            [[ -n "$ip" ]] && print_box_line "Local IP: $ip"
        done <<< "$ips"
    elif command -v ip &> /dev/null; then
        local ips
        ips=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1)
        while IFS= read -r ip; do
            [[ -n "$ip" ]] && print_box_line "Local IP: $ip"
        done <<< "$ips"
    fi
    
    # Public IP
    local public_ip
    public_ip=$(curl -s --connect-timeout 3 ifconfig.me 2>/dev/null || echo "Alınamadı")
    print_box_line "Public IP: $public_ip"
    print_box_bottom
}

# ============ MODÜL: process_list ============
module_process_list() {
    local count="${1:-10}"
    print_box_top
    print_box_center "📊 Top $count Süreç (RAM)" "$BOLD"
    print_box_separator
    print_box_bottom
    
    if [[ "$(uname)" == "Darwin" ]]; then
        ps aux -r | head -$((count + 1))
    else
        ps aux --sort=-%mem 2>/dev/null | head -$((count + 1)) || ps aux | head -$((count + 1))
    fi
    echo ""
}

# ============ YENİ MODÜLÜNÜZÜ BURAYA EKLEYİN ============
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
    register_module "disk" "Disk kullanımını gösterir" "1.0.0" "module_disk_usage"
    register_module "network" "Ağ bilgilerini gösterir" "1.0.0" "module_network_info"
    register_module "process" "Süreç listesini gösterir" "1.0.0" "module_process_list"
    
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
    print_box_line "  -d, --debug       Debug modunu aktifleştir"
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
            -d|--debug)
                DEBUG_MODE="true"
                msg_info "Debug modu aktif"
                shift
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
