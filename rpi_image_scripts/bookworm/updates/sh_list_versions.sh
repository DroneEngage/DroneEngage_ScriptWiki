#!/bin/bash

# Script to list versions of all DroneEngage executable binaries
# Executes each binary with -v parameter and displays output

BASE_DIR="/home/pi/drone_engage"

echo "========================================"
echo "  DroneEngage Component Versions"
echo "========================================"
echo ""

if [ ! -d "$BASE_DIR" ]; then
    echo "Error: Directory $BASE_DIR does not exist"
    exit 1
fi

# Find all executable files in subdirectories
find "$BASE_DIR" -mindepth 2 -type f -executable | sort | while read -r binary; do
    # Skip common non-binary executables
    if [[ "$binary" == *.sh || "$binary" == *.py || "$binary" == *.pl ]]; then
        continue
    fi
    
    # Get relative path for cleaner display
    rel_path="${binary#$BASE_DIR/}"
    component_name=$(dirname "$rel_path")
    binary_name=$(basename "$binary")
    
    # Execute with -v and capture output
    version_output=$("$binary" -v 2>&1)
    exit_code=$?
    
    # Only display if command succeeded
    if [ $exit_code -eq 0 ]; then
        echo "----------------------------------------"
        echo "Component: $component_name"
        echo "Binary:    $binary_name"
        echo "----------------------------------------"
        echo "$version_output"
        echo ""
    fi
done

echo "========================================"
echo "  Version check complete"
echo "========================================"
