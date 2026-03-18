Automatic Flyway Community CLI Updater

This repository provides scripts to automatically install or update the Flyway Community CLI on both:

🪟 Windows (PowerShell)

🐧 Linux (Bash)

The scripts detect the latest Flyway release, download it, install or upgrade the CLI, and verify the installation.

🚀 Features

Automatically detects the latest Flyway version from GitHub

Downloads from GitHub with fallback support

Installs or upgrades Flyway in a defined location

Cleans up temporary files after installation

Verifies installation using flyway --version

Supports custom install paths

Logging for troubleshooting

Cross-platform support (Windows + Linux)

📦 Requirements
Windows

PowerShell 5.1 or later

Internet access

Permissions to write to install directory

Linux

Linux OS (Ubuntu/Debian tested)

curl or wget

tar

sudo privileges (recommended)

📂 Default Paths
Windows
Purpose	Path
Install Location	D:\Flyway
Download Temp	D:\FlywayDownloads
Extract Temp	D:\FlywayExtract
Log File	D:\FlywayInstall.log
Linux
Purpose	Path
Install Location	/opt/flyway
Download Temp	/tmp/flywaydownloads
Extract Temp	/tmp/flyway_extract
Log File	/var/log/flywayinstall.log (fallback: local dir)
⚙️ Installation & Usage
🪟 Windows (PowerShell)
1. Run the script
.\Flyway-autoupdater.ps1
2. Verify installation
flyway -v
3. Optional: Add to PATH
[Environment]::SetEnvironmentVariable(
  "Path",
  $env:Path + ";D:\Flyway",
  [EnvironmentVariableTarget]::Machine
)
🐧 Linux (Bash)
1. Make script executable
chmod +x flyway-autoupdater.sh
2. Run the script
sudo ./flyway-autoupdater.sh
3. Verify installation
flyway --version

If not in PATH:

/opt/flyway/flyway --version
🔧 Custom Configuration
Windows

Edit variables inside the script:

$FlywayInstallPath = "D:\Flyway"
Linux

Override via environment variable:

sudo FLYWAY_INSTALL_PATH=/usr/local/flyway ./flyway-autoupdater.sh
🔗 Optional: Add Flyway to PATH
Windows
setx PATH "$env:PATH;D:\Flyway"
Linux
Option 1 — Symlink
sudo ln -s /opt/flyway/flyway /usr/local/bin/flyway
Option 2 — Profile
export PATH=$PATH:/opt/flyway
📝 Logging
Windows
D:\FlywayInstall.log
Linux
/var/log/flywayinstall.log

Fallback:

./flywayinstall.log
⚠️ Notes

Installs Flyway Community Edition

Existing installations are replaced during upgrade

No flyway.conf is created automatically

Migration script locations must be configured separately

Scripts are designed for automation use cases

🛠️ Troubleshooting
Permission Issues

Windows

Run PowerShell as Administrator

Linux

sudo ./flyway-autoupdater.sh
Download Failures

Check connectivity to:

GitHub Releases

Redgate Flyway distribution servers

Flyway Not Found

Use full path:

Windows

D:\Flyway\flyway -v

Linux

/opt/flyway/flyway info
Missing Migration Location Warning

Example:

WARNING: No locations configured and default location 'sql' not found

Fix by specifying:

flyway -locations=filesystem:/path/to/sql migrate
📌 Future Improvements

Version pinning support

Checksum validation

Automatic PATH configuration option

CI/CD pipeline examples

Config file templating (flyway.conf)
