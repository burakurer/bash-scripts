#!/bin/bash

#######################################################
#                                                     #
#     Author      : burakurer.dev                     #
#     Script      : bu-benchmark.sh                   #
#     Description : Disk I/O Performance Benchmark    #
#     Version     : 2.3.0                             #
#     Last Update : 01/12/2025                        #
#     Website     : https://burakurer.dev             #
#     Github      : https://github.com/burakurer      #
#                                                     #
#######################################################

set -uo pipefail
export LC_ALL=C

# ------------------------ Script Info ------------------------
SCRIPT_VERSION="2.3.0"
SCRIPT_NAME="bu-benchmark.sh"
GITHUB_RAW_URL="https://raw.githubusercontent.com/burakurer/bash-scripts/master"

# ------------------------ Configuration ------------------------
TEST_DIR="${TEST_DIR:-/tmp}"
VERBOSE="${VERBOSE:-false}"
QUICK_MODE="${QUICK_MODE:-false}"
ITERATIONS="${ITERATIONS:-1}"

# ------------------------ Temporary Files ------------------------
declare -a TEMP_FILES=(
    "$TEST_DIR/bench_seq_write.img"
    "$TEST_DIR/bench_small_sync.img"
    "$TEST_DIR/bench_typical.img"
    "$TEST_DIR/bench_mixed.img"
    "$TEST_DIR/bench_read.img"
    "$TEST_DIR/bench_random.img"
)

cleanup() {
    for f in "${TEMP_FILES[@]}"; do
        rm -f "$f" 2>/dev/null
    done
}
trap cleanup EXIT INT TERM

# ------------------------ Colors ------------------------
setup_colors() {
    if [[ -t 1 ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        MAGENTA='\033[0;35m'
        BOLD='\033[1m'
        DIM='\033[2m'
        NC='\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA='' BOLD='' DIM='' NC=''
    fi
}
setup_colors

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

# ------------------------ Helper Functions ------------------------
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_verbose() {
    [[ "$VERBOSE" == "true" ]] && log "${DIM}[VERBOSE]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}                    DD Disk Benchmark v${SCRIPT_VERSION}                      ${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${DIM}                     burakurer.dev                              ${NC}\n"
}

print_separator() {
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
}

show_usage() {
    cat << EOF
${BOLD}Usage:${NC} $0 [OPTIONS]

${BOLD}Options:${NC}
  -d, --dir DIR       Test directory (default: /tmp)
  -q, --quick         Quick mode (smaller test sizes)
  -i, --iterations N  Number of iterations per test (default: 1)
  -v, --verbose       Verbose output
  -h, --help          Show this help message

${BOLD}Environment Variables:${NC}
  TEST_DIR            Test directory
  VERBOSE             Enable verbose mode (true/false)
  QUICK_MODE          Enable quick mode (true/false)
  ITERATIONS          Number of iterations

${BOLD}Examples:${NC}
  $0                          # Run with defaults
  $0 -d /mnt/disk -i 3        # Test /mnt/disk with 3 iterations
  $0 -q -v                    # Quick mode with verbose output
EOF
}

# Parse speed value from dd output (returns MB/s)
parse_speed() {
    local output="$1"
    local match val unit mbps

    # Find speed pattern in output
    match=$(echo "$output" | grep -Eo '[0-9]+([.][0-9]+)?\s*(KiB|MiB|GiB|kB|KB|MB|GB|B)/s' | tail -n1)
    
    if [[ -z "$match" ]]; then
        echo "0"
        return 0
    fi

    val=$(echo "$match" | awk '{print $1}')
    unit=$(echo "$match" | awk '{print $2}')

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

# Run dd command and extract speed
run_dd_test() {
    local description="$1"
    local dd_cmd="$2"
    local test_num="$3"
    local total_mbps=0
    local i

    echo -e "\n${BOLD}[Test $test_num]${NC} $description"
    log_verbose "Command: $dd_cmd"

    for ((i=1; i<=ITERATIONS; i++)); do
        [[ $ITERATIONS -gt 1 ]] && echo -e "  ${DIM}Iteration $i/$ITERATIONS...${NC}"
        
        # Clear caches if running as root
        if [[ $EUID -eq 0 ]]; then
            sync
            echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        fi

        local output
        output=$( (eval "$dd_cmd") 2>&1 )
        local speed
        speed=$(parse_speed "$output")
        
        [[ "$VERBOSE" == "true" ]] && echo "$output" | tail -n1
        
        total_mbps=$(awk -v t="$total_mbps" -v s="$speed" 'BEGIN{printf "%.2f", t+s}')
    done

    # Calculate average
    local avg_mbps
    avg_mbps=$(awk -v t="$total_mbps" -v n="$ITERATIONS" 'BEGIN{printf "%.2f", t/n}')
    echo -e "  ${GREEN}►${NC} Speed: ${BOLD}${avg_mbps} MB/s${NC}"
    
    echo "$avg_mbps"
}

# Rate speed based on test type
rate_speed() {
    local test_type="$1"
    local mbps="$2"
    local rating

    case "$test_type" in
        "sequential_write"|"typical_write"|"sequential_read")
            if   awk -v m="$mbps" 'BEGIN{exit !(m < 100)}';   then rating="Poor"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 300)}';   then rating="Fair"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 600)}';   then rating="Good"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 1000)}';  then rating="Very Good"
            else rating="Excellent"; fi
            ;;
        "small_sync"|"random_io")
            if   awk -v m="$mbps" 'BEGIN{exit !(m < 0.5)}';   then rating="Poor"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 2)}';     then rating="Fair"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 10)}';    then rating="Good"
            else rating="Very Good"; fi
            ;;
        "mixed_write")
            if   awk -v m="$mbps" 'BEGIN{exit !(m < 50)}';    then rating="Poor"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 150)}';   then rating="Fair"
            elif awk -v m="$mbps" 'BEGIN{exit !(m < 400)}';   then rating="Good"
            else rating="Very Good"; fi
            ;;
    esac

    echo "$rating"
}

# Colorize rating
colorize_rating() {
    local rating="$1"
    case "$rating" in
        "Poor")      echo -e "${RED}$rating${NC}" ;;
        "Fair")      echo -e "${YELLOW}$rating${NC}" ;;
        "Good")      echo -e "${GREEN}$rating${NC}" ;;
        "Very Good") echo -e "${CYAN}$rating${NC}" ;;
        "Excellent") echo -e "${MAGENTA}${BOLD}$rating${NC}" ;;
        *)           echo "$rating" ;;
    esac
}

# Calculate linear score (0-100)
calculate_score() {
    local val="$1" min="$2" max="$3"
    awk -v v="$val" -v a="$min" -v b="$max" \
        'BEGIN{ if(b<=a){print 0; exit}
                x=(v-a)/(b-a); if(x<0)x=0; if(x>1)x=1; printf "%.1f", x*100 }'
}

# Show system information
show_system_info() {
    echo -e "${BOLD}System Information:${NC}"
    print_separator
    
    # OS Info
    if [[ -r /etc/os-release ]]; then
        source /etc/os-release
        echo -e "  ${CYAN}OS:${NC}        ${PRETTY_NAME:-$NAME $VERSION}"
    fi
    
    # Kernel
    echo -e "  ${CYAN}Kernel:${NC}    $(uname -r)"
    
    # CPU Info
    if command -v lscpu &>/dev/null; then
        local cpu_model cpu_cores cpu_threads
        cpu_model=$(lscpu | grep "Model name" | sed 's/Model name:[[:space:]]*//')
        cpu_cores=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
        cpu_threads=$(lscpu | grep "Thread(s) per core" | awk '{print $4}')
        echo -e "  ${CYAN}CPU:${NC}       $cpu_model"
        echo -e "  ${CYAN}Cores:${NC}     $cpu_cores (${cpu_threads} threads/core)"
    fi
    
    # Memory Info
    if command -v free &>/dev/null; then
        local mem_total mem_available
        mem_total=$(free -h | awk '/^Mem:/ {print $2}')
        mem_available=$(free -h | awk '/^Mem:/ {print $7}')
        echo -e "  ${CYAN}Memory:${NC}    $mem_total total, $mem_available available"
    fi
    
    # Disk Info for test directory
    if command -v df &>/dev/null; then
        local disk_info
        disk_info=$(df -h "$TEST_DIR" 2>/dev/null | tail -1)
        local disk_dev disk_size disk_used disk_avail
        disk_dev=$(echo "$disk_info" | awk '{print $1}')
        disk_size=$(echo "$disk_info" | awk '{print $2}')
        disk_avail=$(echo "$disk_info" | awk '{print $4}')
        echo -e "  ${CYAN}Test Dir:${NC}  $TEST_DIR"
        echo -e "  ${CYAN}Disk:${NC}      $disk_dev ($disk_size total, $disk_avail free)"
    fi
    
    # Check for NVMe/SSD
    if [[ -d /sys/block ]]; then
        local disk_type="Unknown"
        for dev in /sys/block/nvme* /sys/block/sd*; do
            [[ -e "$dev" ]] || continue
            if [[ "$dev" == /sys/block/nvme* ]]; then
                disk_type="NVMe SSD"
                break
            elif [[ -e "$dev/queue/rotational" ]]; then
                local rot
                rot=$(cat "$dev/queue/rotational" 2>/dev/null)
                [[ "$rot" == "0" ]] && disk_type="SSD" || disk_type="HDD"
            fi
        done
        echo -e "  ${CYAN}Disk Type:${NC} $disk_type (estimated)"
    fi
    
    echo
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dir)
                TEST_DIR="$2"
                shift 2
                ;;
            -q|--quick)
                QUICK_MODE="true"
                shift
                ;;
            -i|--iterations)
                ITERATIONS="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Validate environment
validate_environment() {
    # Check if test directory exists and is writable
    if [[ ! -d "$TEST_DIR" ]]; then
        echo -e "${RED}Error: Test directory '$TEST_DIR' does not exist.${NC}"
        exit 1
    fi
    
    if [[ ! -w "$TEST_DIR" ]]; then
        echo -e "${RED}Error: Test directory '$TEST_DIR' is not writable.${NC}"
        exit 1
    fi
    
    # Check available space (need at least 2GB)
    local avail_kb
    avail_kb=$(df -k "$TEST_DIR" | tail -1 | awk '{print $4}')
    local required_kb=2097152  # 2GB
    [[ "$QUICK_MODE" == "true" ]] && required_kb=524288  # 512MB for quick mode
    
    if [[ $avail_kb -lt $required_kb ]]; then
        echo -e "${YELLOW}Warning: Low disk space. Results may be affected.${NC}"
    fi
    
    # Check for dd
    if ! command -v dd &>/dev/null; then
        echo -e "${RED}Error: 'dd' command not found.${NC}"
        exit 1
    fi
    
    log_verbose "Environment validated successfully"
}

# Run all benchmark tests
run_benchmarks() {
    local bs_large bs_medium count_large count_medium count_small
    
    if [[ "$QUICK_MODE" == "true" ]]; then
        bs_large="256M"; count_large=2       # 512MB
        bs_medium="64k"; count_medium=4096   # 256MB
        count_small=500
    else
        bs_large="1G"; count_large=1         # 1GB
        bs_medium="64k"; count_medium=16384  # 1GB
        count_small=1000
    fi
    
    echo -e "${BOLD}Starting Benchmark Tests...${NC}"
    [[ "$QUICK_MODE" == "true" ]] && echo -e "${YELLOW}(Quick mode enabled - smaller test sizes)${NC}"
    print_separator
    
    # Test 1: Sequential Large Block Write (measures throughput)
    MBPS_SEQ_WRITE=$(run_dd_test \
        "Sequential Write (Large Blocks - throughput test)" \
        "dd if=/dev/zero of='${TEMP_FILES[0]}' bs=$bs_large count=$count_large oflag=dsync 2>&1" \
        1)
    
    # Test 2: Small Block Sync Write (measures latency/IOPS)
    MBPS_SMALL_SYNC=$(run_dd_test \
        "Small Block Sync Write (latency/IOPS test)" \
        "dd if=/dev/zero of='${TEMP_FILES[1]}' bs=512 count=$count_small oflag=dsync 2>&1" \
        2)
    
    # Test 3: Typical Write Pattern (fdatasync)
    MBPS_TYPICAL=$(run_dd_test \
        "Typical Write Pattern (64KB blocks with fdatasync)" \
        "dd if=/dev/zero of='${TEMP_FILES[2]}' bs=$bs_medium count=$count_medium conv=fdatasync 2>&1" \
        3)
    
    # Test 4: Mixed Write (1KB blocks, no sync - cached)
    local mixed_count=$((count_medium * 64))
    MBPS_MIXED=$(run_dd_test \
        "Mixed/Cached Write (1KB blocks)" \
        "dd if=/dev/zero of='${TEMP_FILES[3]}' bs=1k count=$mixed_count 2>&1" \
        4)
    
    # Test 5: Sequential Read Test
    # First create a file to read
    dd if=/dev/zero of="${TEMP_FILES[4]}" bs=$bs_large count=$count_large conv=fdatasync 2>/dev/null
    sync
    [[ $EUID -eq 0 ]] && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    MBPS_SEQ_READ=$(run_dd_test \
        "Sequential Read (Large Blocks)" \
        "dd if='${TEMP_FILES[4]}' of=/dev/null bs=$bs_large 2>&1" \
        5)
    
    # Test 6: Random I/O simulation (using seek)
    MBPS_RANDOM=$(run_dd_test \
        "Random I/O Simulation (small blocks with seek)" \
        "dd if=/dev/zero of='${TEMP_FILES[5]}' bs=4k count=256 seek=\$((RANDOM % 1000)) conv=notrunc oflag=dsync 2>&1" \
        6)
}

# Print results summary
print_summary() {
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                        BENCHMARK RESULTS                        ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Calculate ratings
    local R_SEQ_WRITE R_SMALL_SYNC R_TYPICAL R_MIXED R_SEQ_READ R_RANDOM
    R_SEQ_WRITE=$(rate_speed "sequential_write" "$MBPS_SEQ_WRITE")
    R_SMALL_SYNC=$(rate_speed "small_sync" "$MBPS_SMALL_SYNC")
    R_TYPICAL=$(rate_speed "typical_write" "$MBPS_TYPICAL")
    R_MIXED=$(rate_speed "mixed_write" "$MBPS_MIXED")
    R_SEQ_READ=$(rate_speed "sequential_read" "$MBPS_SEQ_READ")
    R_RANDOM=$(rate_speed "random_io" "$MBPS_RANDOM")
    
    # Print table header
    echo -e "${BOLD}Test   │ Description                              │        Speed │ Rating${NC}"
    echo "───────┼──────────────────────────────────────────┼──────────────┼─────────────"
    
    # Format and print each row using echo
    local speed_fmt
    speed_fmt=$(awk -v s="$MBPS_SEQ_WRITE" 'BEGIN{printf "%9.2f", s}')
    echo -e "1      │ Sequential Write (throughput)            │ ${speed_fmt} MB/s │ $(colorize_rating "$R_SEQ_WRITE")"
    
    speed_fmt=$(awk -v s="$MBPS_SMALL_SYNC" 'BEGIN{printf "%9.2f", s}')
    echo -e "2      │ Small Sync Write (latency)               │ ${speed_fmt} MB/s │ $(colorize_rating "$R_SMALL_SYNC")"
    
    speed_fmt=$(awk -v s="$MBPS_TYPICAL" 'BEGIN{printf "%9.2f", s}')
    echo -e "3      │ Typical Write (fdatasync)                │ ${speed_fmt} MB/s │ $(colorize_rating "$R_TYPICAL")"
    
    speed_fmt=$(awk -v s="$MBPS_MIXED" 'BEGIN{printf "%9.2f", s}')
    echo -e "4      │ Mixed/Cached Write                       │ ${speed_fmt} MB/s │ $(colorize_rating "$R_MIXED")"
    
    speed_fmt=$(awk -v s="$MBPS_SEQ_READ" 'BEGIN{printf "%9.2f", s}')
    echo -e "5      │ Sequential Read                          │ ${speed_fmt} MB/s │ $(colorize_rating "$R_SEQ_READ")"
    
    speed_fmt=$(awk -v s="$MBPS_RANDOM" 'BEGIN{printf "%9.2f", s}')
    echo -e "6      │ Random I/O                               │ ${speed_fmt} MB/s │ $(colorize_rating "$R_RANDOM")"
    
    # Calculate overall score
    local S_SEQ_WRITE S_TYPICAL S_SEQ_READ S_MIXED
    S_SEQ_WRITE=$(calculate_score "$MBPS_SEQ_WRITE" 50 1500)
    S_TYPICAL=$(calculate_score "$MBPS_TYPICAL" 50 1500)
    S_SEQ_READ=$(calculate_score "$MBPS_SEQ_READ" 50 2000)
    S_MIXED=$(calculate_score "$MBPS_MIXED" 50 800)
    
    local OVERALL_SCORE
    OVERALL_SCORE=$(awk -v s1="$S_SEQ_WRITE" -v s2="$S_TYPICAL" -v s3="$S_SEQ_READ" -v s4="$S_MIXED" \
        'BEGIN{printf "%.1f", s1*0.25 + s2*0.30 + s3*0.25 + s4*0.20}')
    
    # Determine overall rating
    local OVERALL_RATING OVERALL_COLOR
    if   awk -v s="$OVERALL_SCORE" 'BEGIN{exit !(s < 25)}';  then OVERALL_RATING="Poor"; OVERALL_COLOR="$RED"
    elif awk -v s="$OVERALL_SCORE" 'BEGIN{exit !(s < 50)}';  then OVERALL_RATING="Fair"; OVERALL_COLOR="$YELLOW"
    elif awk -v s="$OVERALL_SCORE" 'BEGIN{exit !(s < 70)}';  then OVERALL_RATING="Good"; OVERALL_COLOR="$GREEN"
    elif awk -v s="$OVERALL_SCORE" 'BEGIN{exit !(s < 85)}';  then OVERALL_RATING="Very Good"; OVERALL_COLOR="$CYAN"
    else OVERALL_RATING="Excellent"; OVERALL_COLOR="$MAGENTA"
    fi
    
    echo
    print_separator
    echo -e "\n${BOLD}Overall Performance Score:${NC} ${BLUE}${BOLD}${OVERALL_SCORE}/100${NC}"
    echo -e "${BOLD}Overall Rating:${NC} ${OVERALL_COLOR}${BOLD}${OVERALL_RATING}${NC}"
    
    # Performance hints
    echo -e "\n${BOLD}Performance Notes:${NC}"
    echo -e "  ${DIM}• Test 2 & 6 measure latency - lower values indicate sync overhead${NC}"
    echo -e "  ${DIM}• Run as root for accurate results (cache clearing)${NC}"
    echo -e "  ${DIM}• For best accuracy, close other disk-intensive applications${NC}"
    
    echo -e "\n${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}Benchmark completed successfully!${NC}"
    echo -e "${DIM}Temporary files have been cleaned up.${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"
}

# ------------------------ Main ------------------------
main() {
    parse_args "$@"
    
    print_header
    check_for_updates
    show_system_info
    validate_environment
    
    local start_time
    start_time=$(date +%s)
    
    run_benchmarks
    print_summary
    
    local end_time duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo -e "${DIM}Total benchmark time: ${duration}s${NC}\n"
}

main "$@"
