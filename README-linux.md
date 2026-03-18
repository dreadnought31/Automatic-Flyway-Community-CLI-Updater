# Flyway Auto-Updater for Linux

A Bash script that automatically detects, downloads, and installs the latest version of [Flyway](https://flywaydb.org/) on Linux. It queries the GitHub Releases API to find the newest version, attempts to download from GitHub first, and falls back to the Redgate mirror if needed.

---

## Features

- **Auto-detects the latest version** via the GitHub Releases API — no hardcoded version numbers
- **Dual download sources** — GitHub primary, Redgate CDN fallback
- **Clean installs** — wipes the existing Flyway directory before installing the new version
- **Full logging** — all output is appended to `/var/log/flywayinstall.log`, with an automatic fallback to `./flywayinstall.log` if the system log directory is not writable
- **`curl` / `wget` support** — works with whichever HTTP tool is available on the system
- **Environment variable overrides** — all paths are configurable without editing the script
- **Post-install verification** — runs `flyway --version` to confirm a successful install
- **Automatic temp cleanup** — removes downloaded archives and extracted folders after install
- **Safe scripting** — runs with `set -euo pipefail` and an ERR trap that reports the failing line number

---

## Requirements

- Linux (x86-64)
- Bash 4.0 or later
- `curl` **or** `wget`
- `tar` (standard on all Linux distributions)
- Internet access to reach `api.github.com` and either `github.com` or `download.red-gate.com`
- Write access to the install path (default `/opt/flyway`) — run as root or with `sudo`

---

## Installation & Usage

1. Download or clone `flyway-autoupdater.sh` to your machine.

2. Make the script executable:
   ```bash
   chmod +x flyway-autoupdater.sh
   ```

3. Run the script (root or sudo required for the default install path):
   ```bash
   sudo ./flyway-autoupdater.sh
   ```

4. Once complete, confirm the install:
   ```bash
   /opt/flyway/flyway --version
   ```

5. Optionally add Flyway to your `PATH`:
   ```bash
   export PATH="/opt/flyway:$PATH"
   ```
   To make this permanent, add the line above to your `~/.bashrc`, `~/.bash_profile`, or `/etc/profile.d/flyway.sh`.

---

## Configuration

All paths can be overridden via environment variables — no need to edit the script:

| Variable | Default | Description |
|---|---|---|
| `FLYWAY_INSTALL_PATH` | `/opt/flyway` | Where Flyway will be installed |
| `DOWNLOADS_DIR` | `/tmp/flywaydownloads` | Temporary folder for downloaded archives |
| `TEMP_EXTRACT_ROOT` | `/tmp/flyway_extract` | Temporary folder for archive extraction |

**Example — install to a custom path:**
```bash
sudo FLYWAY_INSTALL_PATH=/usr/local/flyway ./flyway-autoupdater.sh
```

**Example — install without root (to a user-writable path):**
```bash
FLYWAY_INSTALL_PATH=$HOME/flyway \
DOWNLOADS_DIR=$HOME/tmp/flywaydownloads \
TEMP_EXTRACT_ROOT=$HOME/tmp/flyway_extract \
./flyway-autoupdater.sh
```

---

## How It Works

```
1.  Determine log file (/var/log/flywayinstall.log or ./flywayinstall.log)
2.  Ensure required directories exist
3.  Clean the existing Flyway install directory
4.  Query GitHub API → resolve the latest Flyway release tag
5.  Build the download URL for the Linux x64 tarball
6.  Attempt download via curl (with retry) or wget
    └── If failed → retry from Redgate CDN
7.  Extract tarball to temp folder
8.  Copy contents to $FLYWAY_INSTALL_PATH
9.  Verify the flyway executable exists and is executable
10. Clean up temp files and folders
11. Run `flyway --version` to confirm success
12. Print install path, log path, and PATH export hint
```

---

## Logging

All output from each run is appended to the log file. The script tries `/var/log/flywayinstall.log` first; if that path is not writable (e.g. running as a non-root user), it falls back to `flywayinstall.log` in the current working directory.

The active log path is printed at the end of every successful run.

---

## Scheduled Automation

To run this script on a schedule, add a cron job. For example, to run on the first of every month at 2:00 AM:

```bash
sudo crontab -e
```

Add the following line:
```
0 2 1 * * /path/to/flyway-autoupdater.sh >> /var/log/flywayinstall.log 2>&1
```

Alternatively, place the script in `/etc/cron.monthly/`:
```bash
sudo cp flyway-autoupdater.sh /etc/cron.monthly/flyway-autoupdater
sudo chmod +x /etc/cron.monthly/flyway-autoupdater
```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `GitHub response missing tag_name` | GitHub API rate limit or network block | Check connectivity to `api.github.com` |
| `Neither curl nor wget is installed` | Missing HTTP tool | Install curl: `sudo apt install curl` / `sudo yum install curl` |
| `Could not download Flyway` | Both GitHub and Redgate unreachable | Verify outbound HTTPS access; check proxy settings |
| `flyway executable not found` | Unexpected archive structure | Check log for extracted folder contents |
| `Permission denied` on `/opt/flyway` | Script not run with sufficient privileges | Re-run with `sudo` |
| Script exits unexpectedly | `set -euo pipefail` caught an error | Check the log — the ERR trap will report the failing line number |

---

## Version History

| Version | Notes |
|---|---|
| 1.0 | Initial release — GitHub primary + Redgate fallback, auto-version detection, env var path overrides |

---

## Author

**Alan O'Brien**

---

## License

This project is provided as-is for personal and organisational use. No warranty is expressed or implied.
