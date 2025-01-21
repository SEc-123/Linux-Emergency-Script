Linux Incident Response & Analysis Scripts
This repository contains two scripts designed for quick incident response and system auditing on Linux systems:

ubuntu_incident_report.sh: Intended for Ubuntu/Debian-based distributions.
centos_incident_report.sh: Intended for CentOS/RHEL-based distributions.
Both scripts collect various system details, analyze logs, scan for suspicious files, and perform user activity audits.

Table of Contents
Overview
Prerequisites
Usage
Ubuntu Script
CentOS Script
Main Features
Report Output
Notes and Caveats
Future Enhancements
License & Disclaimer
Overview
These scripts are designed to assist system administrators and security teams in performing a quick incident response or security audit on Linux servers. Key functionalities include:

Collecting basic system information (hostname, IP, kernel version, logged-in users, etc.).
Analyzing relevant log files (e.g., /var/log/syslog and /var/log/auth.log on Ubuntu; /var/log/messages and /var/log/secure on CentOS).
Listing recently modified files, SUID/SGID files, and large files that could be suspicious.
Checking running processes and open network connections.
Auditing user activities (recent logins, failed logins, user additions/modifications).
Prerequisites
Root Privileges
Most log files and system commands require elevated privileges. Make sure to run these scripts as root (or via sudo).
Pandoc (Optional)
If Pandoc is installed, the script can convert the report to .doc (or .docx) format. Otherwise, it will generate a .txt file.
Usage
After cloning or downloading this repository, choose the appropriate script for your distribution.

Ubuntu Script
Make it executable:
bash
Copy
chmod +x ubuntu_incident_report.sh
Run as root:
bash
Copy
sudo ./ubuntu_incident_report.sh
Specify time range: You’ll be prompted for a time range (in days), defaulting to 1 day. Enter any integer you like, or just press Enter for the default.
CentOS Script
Make it executable:
bash
Copy
chmod +x centos_incident_report.sh
Run as root:
bash
Copy
sudo ./centos_incident_report.sh
Specify time range: Similar prompt for the number of days (default is 1).
Main Features
System Information
Distribution, hostname, IP address, kernel version, current user, logged-in users.
Log Analysis
Ubuntu: Parses /var/log/syslog, /var/log/auth.log, and, if available, uses journalctl to retrieve logs from the last n days.
CentOS: Parses /var/log/messages, /var/log/secure, and optionally uses journalctl if available.
Processes & Network
Lists processes sorted by CPU usage (top 10).
Checks open network connections via netstat or ss.
Suspicious File Detection
Finds recently modified files within the specified days.
Locates SUID/SGID files and large files (>100MB).
Supports excluding certain directories to reduce I/O (e.g., /proc, /sys, /dev).
User Activity Audit
Shows recent login attempts, failed logins, and user creation/modification records.
Report Output
Default Filename: incident_report_YYYYMMDDHHMMSS, where the timestamp is auto-generated.
File Format:
If pandoc is installed, the script produces a .doc (or .docx if you change the extension).
Otherwise, it falls back to a .txt file.
Contents:
Includes all captured audit data during script execution.
For secure environments, consider transferring or archiving the report securely (e.g., upload to a security dashboard, encrypt the file, or store it offline).

Notes and Caveats
High Disk I/O:
Scanning large directories (especially /) can lead to heavy disk usage. Adjust SCAN_DIRS or exclude unnecessary paths to reduce overhead.
Time Range Limit:
By default, logs and file searches are constrained by $TIME_RANGE days. If you need more complex date handling (like multi-day ranges), modify or extend the logic for parsing log dates (journalctl --since=... --until=...) or use more advanced date matching.
Distribution Compatibility:
Scripts are tailored for Ubuntu (or Debian-based) and CentOS (or RHEL-based).
On minimal installations, commands like lsb_release or journalctl may be missing—install or comment out related parts as necessary.
Permission Requirements:
Running as root is critical to access restricted logs and system information.
