#!/usr/bin/env bash
# Flyway Updater (Linux) - latest + GitHub primary + Redgate fallback + install + verify
# Logs to /var/log/flywayinstall.log by default, or ./flywayinstall.log if not writable
# version 1.0
# Alan O'Brien

set -euo pipefail

FLYWAY_INSTALL_PATH="${FLYWAY_INSTALL_PATH:-/opt/flyway}"
DOWNLOADS_DIR="${DOWNLOADS_DIR:-/tmp/flywaydownloads}"
TEMP_EXTRACT_ROOT="${TEMP_EXTRACT_ROOT:-/tmp/flyway_extract}"
ARCHIVE_NAME=""

DEFAULT_LOG_FILE="/var/log/flywayinstall.log"
if touch "$DEFAULT_LOG_FILE" >/dev/null 2>&1; then
  LOG_FILE="$DEFAULT_LOG_FILE"
else
  LOG_FILE="$(pwd)/flywayinstall.log"
  touch "$LOG_FILE"
fi

exec > >(tee -a "$LOG_FILE") 2>&1

ensure_dir() {
  local p="$1"
  mkdir -p "$p"
}

cleanup_on_error() {
  echo "ERROR: Script failed at line $1"
}
trap 'cleanup_on_error $LINENO' ERR

get_latest_flyway_version() {
  local api="https://api.github.com/repos/flyway/flyway/releases/latest"
  local tag

  if command -v curl >/dev/null 2>&1; then
    tag="$(curl -fsSL \
      -H 'User-Agent: FlywayUpdaterScript' \
      -H 'Accept: application/vnd.github+json' \
      "$api" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  elif command -v wget >/dev/null 2>&1; then
    tag="$(wget -qO- \
      --header='User-Agent: FlywayUpdaterScript' \
      --header='Accept: application/vnd.github+json' \
      "$api" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  else
    echo "Neither curl nor wget is installed." >&2
    return 1
  fi

  if [[ -z "$tag" ]]; then
    echo "GitHub response missing tag_name." >&2
    return 1
  fi

  echo "${tag#flyway-}"
}

try_download() {
  local url="$1"
  local out_path="$2"

  echo "Downloading: $url"

  if command -v curl >/dev/null 2>&1; then
    if curl -fL --retry 3 --connect-timeout 20 -o "$out_path" "$url"; then
      return 0
    fi
  elif command -v wget >/dev/null 2>&1; then
    if wget -O "$out_path" "$url"; then
      return 0
    fi
  else
    echo "Neither curl nor wget is installed." >&2
    return 1
  fi

  echo "WARNING: Download failed: $url" >&2
  return 1
}

fast_extract_tarball() {
  local tar_path="$1"
  local dest_path="$2"

  rm -rf "$dest_path"
  mkdir -p "$dest_path"

  echo "Extracting..."
  tar -xzf "$tar_path" -C "$dest_path"
}

echo "Preparing folders..."
ensure_dir "$DOWNLOADS_DIR"
ensure_dir "$TEMP_EXTRACT_ROOT"
ensure_dir "$FLYWAY_INSTALL_PATH"

echo "Cleaning up old Flyway installation..."
rm -rf "${FLYWAY_INSTALL_PATH:?}"/*

echo "Detecting latest Flyway version..."
ONLINE_VERSION="$(get_latest_flyway_version)"
echo "Latest Flyway version detected: $ONLINE_VERSION"

ARCHIVE_NAME="flyway-commandline-${ONLINE_VERSION}-linux-x64.tar.gz"
ARCHIVE_PATH="$DOWNLOADS_DIR/$ARCHIVE_NAME"

GITHUB_URL="https://github.com/flyway/flyway/releases/download/flyway-${ONLINE_VERSION}/${ARCHIVE_NAME}"
REDGATE_URL="https://download.red-gate.com/maven/release/com/redgate/flyway/flyway-commandline/${ONLINE_VERSION}/${ARCHIVE_NAME}"

rm -f "$ARCHIVE_PATH"

echo "Downloading Flyway ${ONLINE_VERSION}..."
DOWNLOADED=false
if try_download "$GITHUB_URL" "$ARCHIVE_PATH"; then
  DOWNLOADED=true
else
  echo "GitHub download failed, trying Redgate..."
  if try_download "$REDGATE_URL" "$ARCHIVE_PATH"; then
    DOWNLOADED=true
  fi
fi

if [[ "$DOWNLOADED" != true ]] || [[ ! -f "$ARCHIVE_PATH" ]]; then
  echo "Could not download Flyway ${ONLINE_VERSION}." >&2
  exit 1
fi

echo "Extracting to $TEMP_EXTRACT_ROOT ..."
fast_extract_tarball "$ARCHIVE_PATH" "$TEMP_EXTRACT_ROOT"

EXTRACTED_FOLDER="$TEMP_EXTRACT_ROOT/flyway-${ONLINE_VERSION}"
if [[ ! -d "$EXTRACTED_FOLDER" ]]; then
  CANDIDATE="$(find "$TEMP_EXTRACT_ROOT" -maxdepth 1 -mindepth 1 -type d -name 'flyway-*' | head -n 1 || true)"

  if [[ -z "$CANDIDATE" ]]; then
    echo "Could not find extracted Flyway folder under $TEMP_EXTRACT_ROOT" >&2
    exit 1
  fi

  EXTRACTED_FOLDER="$CANDIDATE"
fi

echo "Installing to $FLYWAY_INSTALL_PATH..."
cp -a "$EXTRACTED_FOLDER"/. "$FLYWAY_INSTALL_PATH/"

INSTALLED_CMD="$FLYWAY_INSTALL_PATH/flyway"

if [[ ! -x "$INSTALLED_CMD" ]]; then
  echo "Install folder contents:"
  find "$FLYWAY_INSTALL_PATH" -maxdepth 3 -print
  echo "Install failed: flyway executable not found in $FLYWAY_INSTALL_PATH" >&2
  exit 1
fi

echo "Cleanup temporary files..."
rm -f "$ARCHIVE_PATH"
rm -rf "$TEMP_EXTRACT_ROOT"

echo "Confirm Flyway is updated:"
"$INSTALLED_CMD" --version

echo
echo "Flyway installed in: $FLYWAY_INSTALL_PATH"
echo "Log file: $LOG_FILE"
echo "Optional PATH update: export PATH=\"$FLYWAY_INSTALL_PATH:\$PATH\""
