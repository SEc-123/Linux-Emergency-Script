# Linux Emergency Response Script

This script provides an automated solution for Linux incident response and forensic analysis. It collects critical system information, analyzes logs, monitors processes and networks, detects suspicious files, and audits user activities. The results are compiled into a `.doc` report for easy sharing and further investigation.

---

## Features

### 1. System Information Collection
- Collects essential system details like:
  - Hostname
  - IP address
  - Kernel version
  - Current logged-in users

### 2. Log Analysis
- Analyzes key system and authentication logs:
  - `/var/log/syslog`
  - `/var/log/auth.log` (or `/var/log/secure` for RHEL-based systems)
- Extracts logs from the last customizable time range (default: 1 day).

### 3. Process and Network Monitoring
- Monitors running processes, including:
  - Top 10 CPU-intensive processes
  - Open network ports and connections (using `netstat`).

### 4. Suspicious File Detection
- Identifies potentially malicious files:
  - Recently modified files (within the custom time range).
  - Files with SUID/SGID permissions.
  - Large files (over 100MB).

### 5. User Activity Audit
- Audits user behavior by analyzing:
  - Recent login attempts.
  - Failed login attempts.
  - Recently added or modified users.

### 6. Customizable Time Range
- Allows users to define the time range for log and file analysis at runtime.

### 7. Report Generation
- Automatically generates a `.doc` report using `pandoc` for seamless documentation and sharing.

---

## Requirements

### Software Dependencies
- **Linux OS**: Compatible with most distributions (Debian, Ubuntu, CentOS, RHEL).
- **Required tools**:
  - `pandoc`: For generating `.doc` reports.
  - `net-tools`: For network monitoring.

### Installation
Install the required tools using the following commands:

For Debian/Ubuntu:
```bash
sudo apt-get update
sudo apt-get install pandoc net-tools -y
```

For CentOS/RHEL:
```bash
sudo yum update
sudo yum install pandoc net-tools -y
```

---

## Usage

### Running the Script
1. Save the script as `linux_emergency_response.sh`.
2. Make the script executable:
   ```bash
   chmod +x linux_emergency_response.sh
   ```
3. Run the script with `sudo`:
   ```bash
   sudo ./linux_emergency_response.sh
   ```
4. When prompted, specify the time range (in days) for analysis or press `Enter` to use the default (1 day).

### Example Output
- The script generates a report file in the current directory named:
  ```
  incident_report_YYYYMMDDHHMMSS.doc
  ```
- Open the report using a compatible word processor (e.g., Microsoft Word or LibreOffice).

---

## Error Handling

- **Permission Errors**:
  - Ensure the script is run with `sudo`.

- **Missing Tools**:
  - Install dependencies like `pandoc` and `net-tools`.

- **File or Log Unavailability**:
  - The script handles missing files gracefully by logging errors in the report.

---

## Customization

### Default Time Range
- Modify the `DEFAULT_TIME_RANGE` variable in the script to set a different default value:
  ```bash
  DEFAULT_TIME_RANGE=3
  ```

### Additional Log Paths
- Add new log paths in the `Log Analysis` section of the script by extending the existing code.

---

## Limitations

1. The script may generate high disk I/O when scanning large directories or entire file systems.
2. Logs outside the specified time range will not be included.
3. Requires `pandoc` for generating `.doc` reports.

---

## Future Enhancements

1. **Real-time Monitoring**:
   - Integrate tools like `inotify` for real-time log and file monitoring.
2. **Advanced Log Parsing**:
   - Add support for JSON and XML log formats.
3. **Remote Reporting**:
   - Upload reports to a central server or email them automatically.

---

## Disclaimer
This script is intended for educational and diagnostic purposes. Ensure proper authorization before running it in production environments.

