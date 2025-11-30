#!/bin/bash
# ============================================================================
# sh_package_modules.sh.sh — Per-module OTA update with backup + colors
#
# PURPOSE:
#   This script performs an over-the-air (OTA) update for each DroneEngage module
#   (e.g., de_camera, de_comm, de_mavlink, de_rpi_gpio, de_track) on the device.
#   It automatically downloads the latest version of each module, verifies its
#   integrity, backs up the current version, and installs the update. The script
#   is designed to be run on boot or manually via cockpit.
#
# USAGE:
#   sudo ./sh_package_modules.sh.sh
#
# MAIN STEPS:
#   1. Discover installed modules or use defaults if none found.
#   2. For each module:
#      - Fetch the latest version number from the release server.
#      - Download the corresponding tarball and checksum.
#      - Verify the checksum.
#      - Backup the current module directory (if present).
#      - Extract and install the new version.
#      - Fix file permissions.
#      - Prune old backups (keep 3 most recent).
#   3. Log all actions with color-coded output.
#   4. Clean up temporary files.
#
# ENVIRONMENT:
#   - BASE: Path to modules (default: /home/pi/drone_engage)
#   - URL_BASE: Base URL for release files
#   - BACKUP_DIR: Where backups are stored
#   - LOG: Log file (not actively used in this script)
#
# AUTHOR: Mohammad Hefny
# DATE:   October 30, 2025
#
# -----------------------------------------------------------------------------

set -euo pipefail

# --- Argument Handling ---
URL_BASE="${1:-}"
TARGET_MODULE="${2:-all}" # New optional parameter, defaults to 'all'
DRY_RUN=0
FORCE=0
THIRD_ARG="${3:-}"

# Allow --dry-run / --force as 2nd or 3rd argument. If passed as 2nd, default module to 'all'.
if [[ "$TARGET_MODULE" == "--dry-run" ]]; then
    DRY_RUN=1
    TARGET_MODULE="all"
elif [[ "$THIRD_ARG" == "--dry-run" ]]; then
    DRY_RUN=1
fi

if [[ "$TARGET_MODULE" == "--force" ]]; then
    FORCE=1
    TARGET_MODULE="all"
elif [[ "$THIRD_ARG" == "--force" ]]; then
    FORCE=1
fi

# Usage function
usage() {
    echo "Usage: $0 <url_base> [module_name|all] [--dry-run] [--force]"
    echo
    echo "  <url_base>    **REQUIRED.** The base URL for module downloads (e.g., https://myserver.com/releases)."
    echo
    echo "  [module_name] **OPTIONAL.** A specific module folder name to update (e.g., de_camera)."
    echo "                Defaults to 'all', which updates all known and installed modules."
    echo
    echo "  --dry-run     **OPTIONAL.** Show what would be updated without making any changes."
    echo "  --force       **OPTIONAL.** Force update even if local cached version matches _LATEST."
    echo
    echo "Example 1 (All modules): $0 https://cloud.ardupilot.org/downloads/RPI/Latest"
    echo "Example 2 (Specific module): $0 https://cloud.ardupilot.org/downloads/RPI/Latest de_camera"
    echo "Example 3 (Dry run): $0 https://cloud.ardupilot.org/downloads/RPI/Latest --dry-run"
    echo "Example 4 (Force all modules): $0 https://cloud.ardupilot.org/downloads/RPI/Latest --force"
    echo "Example 5 (Force specific module): $0 https://cloud.ardupilot.org/downloads/RPI/Latest de_camera --force"
    exit 1
}

# Check if URL_BASE (first parameter) was provided
if [[ -z "$URL_BASE" ]]; then
    usage
fi

# --- Configuration ---
BASE="/home/pi/drone_engage"
TMP="/tmp/de_mod_$$"
BACKUP_DIR="/home/pi/drone_engage_backups"
VERSION_DIR="$BASE/.versions"

# --- Logging and Setup ---
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BLUE='\033[34m'; NC='\033[0m'
logc() { echo -e "${2}[$(date +'%H:%M:%S')] $1${NC}"; }

logc "Starting update from URL: **$URL_BASE**" "$BLUE"
logc "Target Module(s): **$TARGET_MODULE**" "$BLUE"
if [[ $DRY_RUN -eq 1 ]]; then
    logc "Mode: DRY-RUN (no changes will be made)" "$YELLOW"
else
    mkdir -p "$TMP" "$BACKUP_DIR" "$VERSION_DIR"
    cd "$TMP"
fi

if [[ $FORCE -eq 1 ]]; then
    logc "Option: FORCE (ignoring local version cache)" "$YELLOW"
fi

# --- Determine Modules to Update ---

# Note: de_track corrected to de_tracking for consistency with your previous examples
default_modules=(de_camera de_comm de_mavlink de_rpi_gpio de_tracking de_sdr)
MODULE_LIST=()
URL_BASE_CLEAN="${URL_BASE%/}"

if [[ "$TARGET_MODULE" == "all" ]]; then
    logc "Preparing list of all installed and default modules..." "$BLUE"
    
    # Merge installed + default modules (unique list)
    mapfile -t installed < <(ls -1 "$BASE" 2>/dev/null || true)
    
    declare -A seen
    for mod in "${installed[@]}" "${default_modules[@]}"; do
        [[ -n ${seen[$mod]:-} ]] || { MODULE_LIST+=("$mod"); seen[$mod]=1; }
    done

else
    # Only update the specified module
    if [[ " ${default_modules[*]} " =~ " ${TARGET_MODULE} " || -d "$BASE/$TARGET_MODULE" ]]; then
        MODULE_LIST+=("$TARGET_MODULE")
    else
        logc "Error: Specified module '$TARGET_MODULE' not found in known list or installation directory." "$RED"
        exit 1
    fi
fi

# Final check before proceeding
if [[ ${#MODULE_LIST[@]} -eq 0 ]]; then
    logc "No modules found to update." "$YELLOW"
    sudo rm -rf "$TMP"
    exit 0
fi

# --- Main Update Loop ---
updated_any=0

for mod in "${MODULE_LIST[@]}"; do
    
    # 1. Fetch LATEST version file
    VERSION_URL="$URL_BASE_CLEAN/${mod}_LATEST"

    VERSION=$(curl -fsS --max-time 10 "$VERSION_URL" 2>/dev/null || echo "")
    [[ -z "$VERSION" ]] && { logc "SKIP $mod: no _LATEST at $VERSION_URL" "$YELLOW"; continue; }

    # Check local cached version; if already at latest, skip update
    if [[ $FORCE -eq 0 && -d "$VERSION_DIR" ]]; then
        LOCAL_VERSION_FILE="$VERSION_DIR/${mod}.version"
        LOCAL_VERSION=""
        if [[ -f "$LOCAL_VERSION_FILE" ]]; then
            LOCAL_VERSION=$(<"$LOCAL_VERSION_FILE")
        fi

        if [[ "$LOCAL_VERSION" == "$VERSION" ]]; then
            logc "SKIP $mod: already at latest version $VERSION" "$GREEN"
            continue
        fi
    fi

    TARBALL="$URL_BASE_CLEAN/${mod}_${VERSION}.tar.gz"
    SUMFILE="$URL_BASE_CLEAN/${mod}_${VERSION}.sha256"

    logc "Updating $mod → $VERSION" "$BLUE"

    if [[ $DRY_RUN -eq 1 ]]; then
        # Read-only checks: ensure artifacts exist without downloading files
        if curl -fsSI "$TARBALL" >/dev/null && curl -fsSI "$SUMFILE" >/dev/null; then
            logc "[DRY-RUN] Would download: $(basename "$TARBALL"), $(basename "$SUMFILE")" "$BLUE"
            logc "[DRY-RUN] Would verify checksum and backup existing module (if present)" "$BLUE"
            logc "[DRY-RUN] Would extract new version and set permissions" "$BLUE"
            updated_any=$((updated_any + 1))
        else
            logc "[DRY-RUN] Missing artifacts for $mod at version $VERSION" "$YELLOW"
        fi
        continue
    fi

    # 2. Download and check files
    curl -fsSLO "$TARBALL" && curl -fsSLO "$SUMFILE"
    
    # Checksum validation
    sha256sum -c "${mod}_${VERSION}.sha256" >/dev/null || {
        logc "CHECKSUM FAIL: $mod" "$RED"; sudo rm -f "${mod}_${VERSION}".*; continue;
    }
    logc "Checksum OK" "$GREEN"

    # 3. Backup
    [[ -d "$BASE/$mod" ]] && {
        logc "Backing up $mod..." "$YELLOW"
        tar -czf "$BACKUP_DIR/${mod}_$(date +%Y%m%d_%H%M%S).tar.gz" -C "/" "${BASE#/}/$mod"
    }

    # 4. Extract new module
    sudo rm -rf "$BASE/$mod"
    logc "Extracting..." "$BLUE"
    tar -xzf "${mod}_${VERSION}.tar.gz" -C "$BASE" --no-same-owner --overwrite || {
        logc "EXTRACT FAILED: $mod" "$RED"; continue;
    }
    logc "Extracted" "$GREEN"

    # 5. Permissions and Cleanup
    chown -R pi:pi "$BASE/$mod"
    find "$BASE/$mod" -type f -name 'de_*' -exec chmod +x {} \;
    find "$BASE/$mod" -type f \( -name '*.json' -o -name '*.crt' \) -exec chmod 644 {} \;

    # Keep only 3 latest backups
    find "$BACKUP_DIR" -name "${mod}_*.tar.gz" -printf '%T@ %p\n' | \
        sort -nr | tail -n +4 | cut -d' ' -f2- | xargs -r sudo rm -f

    logc "$mod updated" "$GREEN"
    # Record installed version locally
    echo "$VERSION" > "$VERSION_DIR/${mod}.version"
    updated_any=$((updated_any + 1))
done

if [[ $DRY_RUN -eq 1 ]]; then
    logc "Dry-run complete. $updated_any module(s) would be updated." "$GREEN"
else
    logc "Done. $updated_any module(s) updated." "$GREEN"
fi
sudo rm -rf "$TMP"
