# Flyway Auto-Updater for Windows

A PowerShell script that automatically detects, downloads, and installs the latest version of [Flyway](https://flywaydb.org/) on Windows. 
It queries the GitHub Releases API to find the newest version, attempts to download from GitHub first, and falls back to the Redgate mirror if needed.

---

## Features

- **Auto-detects the latest version** via the GitHub Releases API — no hardcoded version numbers
- **Dual download sources** — GitHub primary, Redgate CDN fallback
- **Clean installs** — wipes the existing Flyway directory before installing the new version
- **Full logging** — all output is transcribed to `D:\flywayinstall.txt`
- **Post-install verification** — runs `flyway --version` to confirm a successful install
- **Automatic temp cleanup** — removes downloaded ZIPs and extracted folders after install

---

## Requirements

- Windows (x64)
- PowerShell 5.1 or later
- Internet access to reach `api.github.com` and either `github.com` or `download.red-gate.com`
- The `D:\` drive must exist (or paths must be adjusted — see [Configuration](#configuration))

---

## Installation & Usage

1. Download or clone `Flyway-autoupdater.ps1` to your machine.

2. Open PowerShell **as Administrator**.

3. If required, allow script execution:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

4. Run the script:
   ```powershell
   .\Flyway-autoupdater.ps1
   ```

5. Once complete, confirm the install:
   ```powershell
   D:\Flyway\flyway.cmd --version
   ```

---

## Configuration

The following paths are defined at the top of the script and can be changed to suit your environment:

| Variable | Default | Description |
|---|---|---|
| `$flywayInstallPath` | `D:\Flyway` | Where Flyway will be installed |
| `$Downloads` | `D:\temp\flywaydownloads` | Temporary folder for downloaded ZIPs |
| `$TempExtractRoot` | `D:\temp\flyway_extract` | Temporary folder for ZIP extraction |

The install log is always written to `D:\flywayinstall.txt`.

---

## How It Works

```
1. Ensure required directories exist
2. Clean the existing Flyway install directory
3. Query GitHub API → resolve the latest Flyway release tag
4. Build the download URL for the Windows x64 ZIP
5. Attempt download from GitHub Releases
   └── If failed → retry from Redgate CDN
6. Extract ZIP to temp folder
7. Copy contents to $flywayInstallPath
8. Verify flyway.cmd exists in the install path
9. Clean up temp files and folders
10. Run `flyway --version` to confirm success
```

---

## Logging

A full transcript of each run is appended to `D:\flywayinstall.txt`. This is useful for auditing updates or diagnosing failures in automated/scheduled deployments.

---

## Scheduled Automation

To run this script on a schedule (e.g. monthly), register it as a Windows Scheduled Task:

```powershell
$action  = New-ScheduledTaskAction -Execute "powershell.exe" `
             -Argument "-NonInteractive -ExecutionPolicy Bypass -File D:\scripts\Flyway-autoupdater.ps1"
$trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At "02:00"
Register-ScheduledTask -TaskName "Flyway Auto-Updater" -Action $action -Trigger $trigger -RunLevel Highest
```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `GitHub response missing tag_name` | GitHub API rate limit or network block | Check connectivity to `api.github.com` |
| `Could not download Flyway` | Both GitHub and Redgate unreachable | Verify outbound HTTPS access; check proxy settings |
| `flyway.cmd not found` | Unexpected ZIP structure | Check log for extracted folder contents |
| Script exits immediately | Execution policy restriction | Run `Set-ExecutionPolicy Bypass -Scope Process` |

---

## Version History

| Version | Notes |
|---|---|
| 1.0 | Initial release — GitHub primary + Redgate fallback, auto-version detection |

---

## Author

**Alan O'Brien**

---

## License

This project is provided as-is for personal and organisational use. No warranty is expressed or implied.



When you run this file you should expect an output similar to below.

PS C:\Users\aobrien> . 'D:\Flyway-autoupdater.ps1'

Transcript started, output file is D:\flywayinstall.txt

Preparing folders...

Cleaning up old Flyway installation...

Detecting latest Flyway version...

Latest Flyway version detected: 12.1.1

Downloading Flyway 12.1.1...

Downloading: https://github.com/flyway/flyway/releases/download/flyway-12.1.1/flyway-commandline-12.1.1-windows-x64.zip

Extracting to D:\temp\flyway_extract ...

Extracting...

Installing to D:\Flyway...

Cleanup temporary files...

Confirm Flyway is updated:

WARNING: No locations configured and default location 'sql' not found.

Flyway OSS Edition 12.1.1 by Redgate

See release notes here: https://rd.gt/416ObMi
Plugin Name                       | Version
--------------------------------- | ---------
DB2 for z/OS                      | 10.24.0
OceanBase                         | 10.24.0
QuestDB                           | 10.24.0
TiDB                              | 10.24.0
YugabyteDB                        | 10.24.0
ClickHouse                        | 10.24.0
CUBRID                            | 10.24.0
Databricks                        | 10.24.0
DuckDB                            | 10.24.0
Apache Ignite                     | 10.24.0
InterSystems IRIS Data Platform   | 10.24.0
Timeplus                          | 10.24.0
Transcript stopped, output file is D:\flywayinstall.txt
