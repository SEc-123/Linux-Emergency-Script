#!/bin/bash
################################################################################
# CentOS Incident Response and Analysis Script
################################################################################

# ---------------------------
# 0. 前置依赖检测
# ---------------------------
if ! command -v pandoc &>/dev/null; then
  echo "[WARN] pandoc is not installed. The report will be saved in plain text only."
  USE_PANDOC=false
else
  USE_PANDOC=true
fi

# ---------------------------
# 1. 全局变量
# ---------------------------
REPORT_FILE="incident_report_$(date +%Y%m%d%H%M%S)"
REPORT_EXT="doc"         # 可以改为 docx 或者其他适合Pandoc的格式
TEMP_FILE="temp_report.txt"
DEFAULT_TIME_RANGE=1     # 默认时间范围(天)
LOG_DIRS=("/var/log")    # 常见日志目录
SCAN_DIRS=("/")          # 根据需求修改
EXCLUDE_DIRS=("/proc" "/sys" "/dev" "/run" "/tmp" "/var/cache")

# ---------------------------
# 2. 初始化文件
# ---------------------------
> "$TEMP_FILE"

# 分割线函数
function print_line() {
    echo "========================================" >> "$TEMP_FILE"
}

# 错误处理函数
function handle_error() {
    echo "[ERROR] $1" >&2
    echo "[ERROR] $1" >> "$TEMP_FILE"
}

# 生成最终报告函数
function generate_doc_report() {
    if [ "$USE_PANDOC" = true ]; then
        pandoc "$TEMP_FILE" -o "${REPORT_FILE}.${REPORT_EXT}" 2>/dev/null
        if [ $? -ne 0 ]; then
            handle_error "Failed to generate .${REPORT_EXT} report with pandoc."
            return 1
        fi
        echo "[INFO] Report generated: ${REPORT_FILE}.${REPORT_EXT}"
    else
        mv "$TEMP_FILE" "${REPORT_FILE}.txt"
        echo "[INFO] pandoc not available, generated plain text: ${REPORT_FILE}.txt"
    fi
}

# ---------------------------
# 3. 权限检查
# ---------------------------
if [[ $EUID -ne 0 ]]; then
    handle_error "This script must be run as root."
    exit 1
fi

# ---------------------------
# 4. 交互式输入时间范围
# ---------------------------
read -p "Enter the time range for file and log analysis (in days, default: $DEFAULT_TIME_RANGE): " TIME_RANGE
TIME_RANGE=${TIME_RANGE:-$DEFAULT_TIME_RANGE}

# ---------------------------
# 5. 系统信息收集
# ---------------------------
{
    echo "CentOS Incident Response Report"
    echo "Generated on: $(date)"
    print_line
    echo "[1] System Information"
    if [ -f /etc/centos-release ]; then
        echo "Distribution: $(cat /etc/centos-release)"
    elif [ -f /etc/redhat-release ]; then
        echo "Distribution: $(cat /etc/redhat-release)"
    else
        echo "Distribution: CentOS or RHEL-like (unknown exact version)"
    fi
    echo "Hostname: $(hostname)"
    echo "IP Address: $(hostname -I)"
    echo "Kernel Version: $(uname -r)"
    echo "Current User: $(whoami)"
    echo "Logged-in Users:"
    who
    print_line
} >> "$TEMP_FILE" || handle_error "Failed to collect system information."

# ---------------------------
# 6. 日志分析
# ---------------------------
{
    echo "[2] Recent Logs (Last $TIME_RANGE day(s))"

    # 对于 CentOS 7 或更高版本可能有 systemd，可尝试 journalctl
    if command -v journalctl &>/dev/null; then
        echo "Systemd Journal (last $TIME_RANGE day(s)):"
        journalctl --since="$TIME_RANGE days ago" --no-pager | tail -n 50 2>/dev/null || echo "No journal logs found."
    fi
    
    # 分析 /var/log/messages
    echo "Last 50 lines of /var/log/messages (filtered by date range):"
    if [ -f /var/log/messages ]; then
        # 用 awk 示例，仅对日期进行大致匹配
        awk -v d="$(date -d "$TIME_RANGE days ago" +%s)" '
            {
              # CentOS messages格式: "MMM DD HH:MM:SS Host ...",
              # 拆分前两个字段作为日期即可(需调整到与Ubuntu略不同的日志格式)
              cmd="date -d \""$1" "$2"\" +%s 2>/dev/null"
              cmd | getline logtime
              close(cmd)
              if (logtime >= d) print $0
            }
        ' /var/log/messages | tail -n 50
    else
        echo "/var/log/messages not found."
    fi
    
    # 分析 /var/log/secure
    echo "Last 50 lines of /var/log/secure (filtered by date range):"
    if [ -f /var/log/secure ]; then
        awk -v d="$(date -d "$TIME_RANGE days ago" +%s)" '
            {
              cmd="date -d \""$1" "$2"\" +%s 2>/dev/null"
              cmd | getline logtime
              close(cmd)
              if (logtime >= d) print $0
            }
        ' /var/log/secure | tail -n 50
    else
        echo "/var/log/secure not found."
    fi

    print_line
} >> "$TEMP_FILE" || handle_error "Failed to analyze logs."

# ---------------------------
# 7. 进程与网络监控
# ---------------------------
{
    echo "[3] Process and Network Monitoring"
    echo "Currently Running Processes (Top 10 by CPU Usage):"
    ps aux --sort=-%cpu | head -n 10 || echo "Process data unavailable."
    
    echo "Open Network Connections:"
    if command -v netstat &>/dev/null; then
        netstat -tulnp 2>/dev/null || echo "Netstat unavailable."
    elif command -v ss &>/dev/null; then
        ss -tulnp 2>/dev/null || echo "ss unavailable."
    else
        echo "Neither netstat nor ss found."
    fi
    print_line
} >> "$TEMP_FILE" || handle_error "Failed to monitor processes and network."

# ---------------------------
# 8. 可疑文件检测
# ---------------------------
{
    echo "[4] Suspicious File Detection"
    echo "Searching recently modified files (Last $TIME_RANGE day(s))"
    echo "Excluding directories: ${EXCLUDE_DIRS[*]}"

    EXCLUDE_ARGS=()
    for dir in "${EXCLUDE_DIRS[@]}"; do
        EXCLUDE_ARGS+=( -path "$dir" -prune -o )
    done
    
    find "${SCAN_DIRS[@]}" \
        "${EXCLUDE_ARGS[@]}" \
        -type f -mtime -"$TIME_RANGE" -ls 2>/dev/null | head -n 20 || echo "No recent files found."

    echo "Files with SUID/SGID Permissions:"
    find "${SCAN_DIRS[@]}" \
        "${EXCLUDE_ARGS[@]}" \
        -perm /6000 -type f 2>/dev/null | head -n 20 || echo "No SUID/SGID files found."

    echo "Large Files (>100MB):"
    find "${SCAN_DIRS[@]}" \
        "${EXCLUDE_ARGS[@]}" \
        -type f -size +100M 2>/dev/null | head -n 20 || echo "No large files found."

    print_line
} >> "$TEMP_FILE" || handle_error "Failed to detect suspicious files."

# ---------------------------
# 9. 用户活动审计
# ---------------------------
{
    echo "[5] User Activity Audit (Last $TIME_RANGE day(s))"
    echo "Recent Login Attempts:"
    last -a | head -n 20 2>/dev/null || echo "No login data available."
    
    echo "Failed Login Attempts (from /var/log/secure):"
    if [ -f /var/log/secure ]; then
        grep "Failed password" /var/log/secure | tail -n 20 2>/dev/null || echo "No failed logins found."
    else
        echo "/var/log/secure not found."
    fi

    echo "Recently Added/Modified Users (useradd|usermod in /var/log/secure):"
    if [ -f /var/log/secure ]; then
        grep -E "useradd|usermod" /var/log/secure | tail -n 20 2>/dev/null || echo "No recent user changes found."
    else
        echo "/var/log/secure not found."
    fi

    print_line
} >> "$TEMP_FILE" || handle_error "Failed to audit user activity."

# ---------------------------
# 10. 生成报告 & 清理
# ---------------------------
generate_doc_report

if [ -f "$TEMP_FILE" ] && [ "$USE_PANDOC" = true ]; then
    rm -f "$TEMP_FILE"
fi

exit 0
