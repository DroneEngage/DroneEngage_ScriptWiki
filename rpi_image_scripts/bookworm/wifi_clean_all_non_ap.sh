#!/bin/bash

# Define the connection name to keep (your Access Point)
AP_NAME="hotspot"

echo "Starting removal of all connections except: ${AP_NAME}"
echo "--------------------------------------------------------"

# Use nmcli to list connections, print only the NAME field, and skip the header (tail -n +2)
# The output format is: NAME
nmcli connection show | awk 'NR>1 {print $1}' | while read CONN_NAME; do
    # Strip leading/trailing whitespace, though nmcli usually handles this well
    CONN_NAME=$(echo "$CONN_NAME" | xargs)

    # Check if the connection name is NOT the one we want to keep
    if [ "$CONN_NAME" != "$AP_NAME" ]; then
        echo "Deleting connection: **${CONN_NAME}**"
        # Execute the nmcli delete command using the connection name
        nmcli connection delete "$CONN_NAME"
    else
        echo "Keeping Access Point: **${CONN_NAME}**"
    fi
done

echo "--------------------------------------------------------"
echo "Cleanup complete. Current connections:"
nmcli connection show