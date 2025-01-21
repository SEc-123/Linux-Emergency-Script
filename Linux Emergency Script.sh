#!/bin/bash

# Output file for the report
REPORT_FILE="incident_report_$(date +%Y%m%d%H%M%S).doc"

# Temporary working file for plain-text content
TEMP_FILE="temp_report.txt"

# Default time range for file and log analysis (in days)
DEFAULT_TIME_RANGE=1

# Create or overwrite the temp file
> $TEMP_FILE

# Function to print a separator line
function print_line() {
    echo "========================================" >> $TEMP_FILE
}

# Function to handle errors
function handle_error() {
    echo "[ERROR] $1" >&2
    echo "[ERROR] $1" >> $TEMP_FILE
}

# Function to generate the final report as a .doc file
function generate_doc_report() {
    pandoc $TEMP_FILE -o $REPORT_FILE 2>/dev/null
    if [ $? -ne 0 ]; then
        handle_error "Failed to generate .doc report. Ensure 'pandoc' is installed."
        return 1
    fi
    echo "[INFO] Report generated: $REPORT_FILE"
    echo "[INFO] Report generated: $REPORT_FILE" >> $TEMP_FILE
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    handle_error "This script must be run as root."
    exit 1
fi

# Prompt user for custom time range
read -p "Enter the time range for file and log analysis (in days, default: $DEFAULT_TIME_RANGE): " TIME_RANGE
TIME_RANGE=${TIME_RANGE:-$DEFAULT_TIME_RANGE}

# 1. Collect system information
{
    echo "Linux Incident Response Report"
    echo "Generated on: $(date)"
    print_line
    echo "[1] System Information"
    echo "Hostname: $(hostname)"
    echo "IP Address: $(hostname -I)"
    echo "Kernel Version: $(uname -r)"
    echo "Current User: $(whoami)"
    echo "Logged-in Users:"
    who
    print_line
} >> $TEMP_FILE || handle_error "Failed to collect system information."

# 2. Analyze logs
{
    echo "[2] Recent Logs"
    echo "Logs from the past $TIME_RANGE day(s):"
    echo "Last 50 lines of /var/log/syslog:" >> $TEMP_FILE
    grep -i "$(date --date="$TIME_RANGE days ago" "+%b %e")" /var/log/syslog 2>/dev/null | tail -n 50 || echo "File not available or no logs in range." >> $TEMP_FILE
    echo "Last 50 lines of /var/log/auth.log:" >> $TEMP_FILE
    grep -i "$(date --date="$TIME_RANGE days ago" "+%b %e")" /var/log/auth.log 2>/dev/null | tail -n 50 || echo "File not available or no logs in range." >> $TEMP_FILE
    print_line
} >> $TEMP_FILE || handle_error "Failed to analyze logs."

# 3. Monitor processes and network
{
    echo "[3] Process and Network Monitoring"
    echo "Currently Running Processes (Top 10 by CPU Usage):"
    ps aux --sort=-%cpu | head -n 10 || echo "Process data unavailable."
    echo "Open Network Connections:"
    netstat -tulnp 2>/dev/null || echo "Netstat unavailable."
    print_line
} >> $TEMP_FILE || handle_error "Failed to monitor processes and network."

# 4. Detect suspicious files
{
    echo "[4] Suspicious File Detection"
    echo "Recently Modified Files (Last $TIME_RANGE day(s)):"
    find / -type f -mtime -$TIME_RANGE -ls 2>/dev/null | head -n 20 || echo "No recent files found."
    echo "Files with SUID/SGID Permissions:"
    find / -perm /6000 -type f 2>/dev/null | head -n 20 || echo "No SUID/SGID files found."
    echo "Large Files (>100MB):"
    find / -type f -size +100M 2>/dev/null | head -n 20 || echo "No large files found."
    print_line
} >> $TEMP_FILE || handle_error "Failed to detect suspicious files."

# 5. Audit user activity
{
    echo "[5] User Activity Audit"
    echo "Recent Login Attempts (Last $TIME_RANGE day(s)):"
    last -a | grep -E "$(date --date="$TIME_RANGE days ago" "+%b %e")" | head -n 20 || echo "Login data unavailable."
    echo "Failed Login Attempts:" >> $TEMP_FILE
    grep "Failed password" /var/log/auth.log 2>/dev/null | grep -i "$(date --date="$TIME_RANGE days ago" "+%b %e")" | tail -n 20 || echo "No failed logins found."
    echo "Recently Added/Modified Users:" >> $TEMP_FILE
    grep -E "useradd|usermod" /var/log/auth.log 2>/dev/null | grep -i "$(date --date="$TIME_RANGE days ago" "+%b %e")" | tail -n 20 || echo "No recent user changes found."
    print_line
} >> $TEMP_FILE || handle_error "Failed to audit user activity."

# Generate the .doc report
generate_doc_report

# Clean up temporary file
rm -f $TEMP_FILE
