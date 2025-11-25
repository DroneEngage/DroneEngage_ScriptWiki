#!/bin/bash
# sh_package_modules.sh — Package EACH module with ALL files & folders
# Run in ~/drone_engage_build/
# Example 1: ./sh_package_modules.sh v3.1.0                  (Builds ALL modules with version v3.1.0)
# Example 2: ./sh_package_modules.sh de_camera               (Builds ONLY de_camera with a date version)
# Example 3: ./sh_package_modules.sh v3.1.0 de_camera        (Builds ONLY de_camera with version v3.1.0)

set -euo pipefail

# --- Configuration ---
SRC_ROOT="/home/pi/drone_engage_binary"
OUT_DIR="/home/pi/drone_engage_output/releases/"

# --- Argument Handling and Usage ---

# Global variables initialized to empty
VERSION=""
TARGET_MODULES=""

# Usage function
usage() {
    echo "Usage: $0 <version> [module_name|all]"
    echo
    echo "  <version>     The version string to use for packages (e.g., v3.1.0)."
    echo "                If omitted, uses today's date (e.g., $(date +%Y%m%d))."
    echo "  [module_name] An optional specific module folder name to package (e.g., de_camera)."
    echo "  <all>         (Default) Packages all modules."
    echo
    echo "Example 1 (All modules, specific version): $0 v3.1.0"
    echo "Example 2 (Specific module, date version): $0 de_camera"
    echo "Example 3 (Specific module, specific version): $0 v3.1.0 de_camera"
    exit 1
}

# 1. Handle Zero Arguments
if [[ $# -eq 0 ]]; then
    usage
fi

# 2. Assign values based on number of arguments
if [[ $# -eq 1 ]]; then
    # Case: ./sh_package_modules.sh de_camera
    # The single argument is treated as the TARGET_MODULES, and VERSION defaults to date.
    TARGET_MODULES="$1"
    VERSION="$(date +%Y%m%d)"
    if [[ "$1" == "all" ]]; then
        TARGET_MODULES="all"
    fi
elif [[ $# -eq 2 ]]; then
    # Case: ./sh_package_modules.sh v3.1.0 de_camera
    # First argument is VERSION, second is TARGET_MODULES.
    VERSION="$1"
    TARGET_MODULES="$2"
else
    echo "Error: Too many arguments."
    usage
fi

# If TARGET_MODULES is empty (e.g., called as ./script v3.1.0 without a second arg) default to 'all'
if [[ -z "$TARGET_MODULES" ]]; then
    TARGET_MODULES="all"
fi

# If VERSION is empty or specifically set to an empty string, use the date
if [[ -z "$VERSION" || "$VERSION" == "" ]]; then
    VERSION="$(date +%Y%m%d)"
fi


# --- Validation and Setup ---

# Validate source root
[[ -d "$SRC_ROOT" ]] || { echo "Error: $SRC_ROOT not found"; exit 1; }

mkdir -p "$OUT_DIR"

echo "Building per-module packages (version: $VERSION)..."
echo "Source: $SRC_ROOT"
echo "Target Module(s): **$TARGET_MODULES**"
echo

# --- Determine Modules to Build ---
MODULE_LIST=()
if [[ "$TARGET_MODULES" == "all" ]]; then
    # Find all directories in SRC_ROOT and strip the path
    while IFS= read -r dir; do
        MODULE_LIST+=("$(basename "$dir")")
    done < <(find "$SRC_ROOT" -mindepth 1 -maxdepth 1 -type d)
else
    # Only build the specified module
    if [[ -d "$SRC_ROOT/$TARGET_MODULES" ]]; then
        MODULE_LIST+=("$TARGET_MODULES")
    else
        echo "Error: Specified module directory '$SRC_ROOT/$TARGET_MODULES' not found."
        exit 1
    fi
fi

# Check if any modules were found
if [[ ${#MODULE_LIST[@]} -eq 0 ]]; then
    echo "No modules found in $SRC_ROOT to package."
    exit 1
fi

# --- PACKAGE MODULES ---
for module in "${MODULE_LIST[@]}"; do
    module_path="$SRC_ROOT/$module"
    tarball="$OUT_DIR/${module}_${VERSION}.tar.gz"
    checksum="$OUT_DIR/${module}_${VERSION}.sha256"

    echo "Packaging: $module → $tarball"

    # 1. Create tarball
    tar -czf "$tarball" \
        --owner=0 --group=0 \
        --mtime='2025-01-01 00:00:00' \
        --preserve-permissions \
        --directory="$SRC_ROOT" \
        "$module"

    # 2. Generate SHA-256
    (cd "$OUT_DIR" && sha256sum "$(basename "$tarball")" > "$(basename "$checksum")")

    # Get stats
    size=$(du -h "$tarball" | cut -f1)
    file_count=$(find "$module_path" -type f | wc -l)
    dir_count=$(find "$module_path" -type d | wc -l)
    
    echo "  OK → $size, $file_count files, $dir_count dirs"
done

# --- UPDATE LATEST FILES ---
echo
echo "Updating LATEST files for packaged modules..."
for module_name in "${MODULE_LIST[@]}"; do
    echo "$VERSION" > "$OUT_DIR/${module_name}_LATEST"
done

echo
echo "Build complete."
echo "Packages in: $OUT_DIR"
echo "Upload to: https://droneengage.com/releases/"
ls -lh "$OUT_DIR"/*.tar.gz

