#!/bin/bash

echo "--- Starting comprehensive RPi image cleanup ---"
date

# 1. Clear system journal logs
echo "1. Clearing system journal logs (all of them)..."
sudo journalctl --vacuum-time=0days
sudo journalctl --rotate # Rotate logs immediately to apply vacuum
echo "System journal logs cleared."

# 2. Clear common application logs (including rotated ones)
echo "2. Clearing all application logs..."

# Truncate active log files to keep the files in place but empty their contents.
echo "  - Truncating active log files..."
sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

# Delete all compressed, rotated log files.
echo "  - Deleting rotated and compressed log files..."
sudo find /var/log/ -type f -name "*.gz" -delete
sudo find /var/log/ -type f -name "*.bz2" -delete
sudo find /var/log/ -type f -name "*.xz" -delete
sudo find /var/log/ -type f -name "*.zip" -delete

# The above commands are enough to get most logs. However, if you want to
# be more aggressive, you can also delete the historical, uncompressed logs.
echo "  - Deleting historical, uncompressed logs (e.g., .log.1, .log.2)..."
sudo find /var/log/ -type f -regex ".*\.log\.[0-9]+" -delete

echo "All logs cleared."

# 3. Clear command history for all users (if multiple exist)
echo "3. Clearing command history for existing users..."
for user_home in /home/*; do
    if [ -d "$user_home" ]; then # Ensure it's a directory
        username=$(basename "$user_home")
        echo "  - Clearing history for user: $username"
        sudo rm -f "$user_home/.bash_history" "$user_home/.zsh_history" "$user_home/.fish_history"
        # Prevent future history saving for current shell session (won't persist for next boot)
        if [ "$username" == "$(whoami)" ]; then
            history -c
            history -w
        fi
    fi
done
# Also clear root's history
echo "  - Clearing history for root..."
sudo rm -f /root/.bash_history /root/.zsh_history /root/.fish_history
echo "Command history cleared."

# 4. Remove temporary files
echo "4. Removing temporary files..."
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
echo "Temporary files removed."

# 5. Clear APT package cache and remove orphaned packages
echo "5. Clearing APT package cache and removing orphaned packages..."
sudo apt clean
sudo apt autoremove -y
echo "APT package cache and orphaned packages cleared."

# 6. Remove old kernels (use with caution!)
echo "6. Removing old kernels (keeping the current and one previous)..."
CURRENT_KERNEL=$(uname -r)
# Get a list of all installed kernel images, exclude current, sort, and get all but the latest
KERNELS_TO_REMOVE=$(dpkg --list --columns=2 'linux-image-*' | grep -v "$CURRENT_KERNEL" | awk '{print $1}' | sort -V | head -n $(($(dpkg --list --columns=2 'linux-image-*' | wc -l) - 2)))

if [ -n "$KERNELS_TO_REMOVE" ]; then
    echo "  - Removing old kernel(s): $KERNELS_TO_REMOVE"
    # Use -y for non-interactive removal
    sudo apt remove --purge $KERNELS_TO_REMOVE -y
    sudo apt autoremove -y
else
    echo "  - No old kernels to remove (keeping current and one previous, or only current if applicable)."
fi
echo "Old kernels handled."

# 7. Clean user cache and configuration files (especially for 'pi' user)
echo "7. Cleaning user cache and configuration files..."
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")
        echo "  - Cleaning cache for user: $username"
        # Delete cache
        rm -rf "$user_home/.cache/"*
        # Delete browser caches/profiles (common paths, customize if needed)
        rm -rf "$user_home/.config/chromium/"*
        rm -rf "$user_home/.mozilla/firefox/"*
        # Delete common config files that might contain personal info
        echo "  - Deleting sensitive config files for user: $username"
        sudo rm -rf "$user_home/.ssh/"* # SSH keys and known_hosts - CRITICAL
        sudo rm -f "$user_home/.gitconfig"      # Git configuration
        sudo rm -f "$user_home/.netrc"          # Network credentials
        sudo rm -f "$user_home/.gnupg/"* # GPG keys
        sudo rm -f "$user_home/.aws/"* # AWS credentials
        sudo rm -f "$user_home/.kube/"* # Kubernetes credentials
        # Consider specific app configs if you have them, e.g., for databases, web servers, etc.
    fi
done
echo "User cache and configuration files cleaned."

# 8. Check and clean /var/lib (for databases, web servers, etc.)
echo "8. Checking and cleaning /var/lib for database/web server data..."
# This is highly dependent on what you have installed. Examples:
# For MySQL:
# sudo rm -rf /var/lib/mysql/*
# For PostgreSQL:
# sudo rm -rf /var/lib/postgresql/*
# For Redis:
# sudo rm -rf /var/lib/redis/*
# For Apache/Nginx (web server logs/data - if not in /var/log/):
# sudo rm -rf /var/www/html/* # ONLY if you want to clear your web content!
echo "Review /var/lib and related service data manually if necessary!"
echo "Database and web server data (if any) should be reviewed separately."

# 9. Regenerate SSH Host Keys (Requires a reboot to take full effect)
echo "9. Regenerating SSH Host Keys..."
# Remove existing host keys
sudo rm -f /etc/ssh/ssh_host_*
# Reconfigure openssh-server to generate new keys on next boot
sudo dpkg-reconfigure openssh-server
echo "SSH host keys will be regenerated on the next reboot."

# 10. Clear Crontabs
echo "10. Clearing user and root crontabs..."
# Clear current user's crontab
crontab -r >/dev/null 2>&1 || echo "No user crontab found for $(whoami)."
# Clear root's crontab
sudo crontab -r >/dev/null 2>&1 || echo "No root crontab found."
# Remove any system-wide cron.d jobs added manually (be careful!)
# sudo rm -f /etc/cron.d/your_custom_cron_job
echo "Crontabs cleared. Review /etc/cron.* for persistent system cron jobs."

# 11. Remove specific application installations or configuration files
# This section is highly dependent on your specific setup.
# Example: If you installed custom applications outside of APT
# echo "Removing specific application traces..."
# sudo rm -rf /opt/your_custom_app
# sudo rm -f /etc/your_custom_app.conf
# 11.a delete bak files of config.
sudo find /home/pi -type f -name "*.bak.*" -delete
sudo find /home/pi -type d -name "terrain" -exec rm -rf {} +
sudo find /home/pi -type d -name "logs" -exec rm -rf {} +
sudo find /home/pi -type f -name "eeprom.bin" -delete
sudo find /home/pi -type f -name "*.local" -delete

if [ -d /home/pi/drone_engage_backups ]; then
    sudo rm -f /home/pi/drone_engage_backups/*.*
fi

# 12. Final check of disk space
echo "--- Disk space after cleanup ---"
df -h

echo "--- Comprehensive Cleanup finished ---"
date


