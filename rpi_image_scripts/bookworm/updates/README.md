# DroneEngage Module Backup and OTA Update Scripts

This folder contains scripts for backing up DroneEngage configuration files and performing over-the-air (OTA) updates for DroneEngage modules on Raspberry Pi.

## Backup

- **sh_backup_configurations.sh**
  Backs up all `.json` configuration files from `/home/pi/drone_engage` to a timestamped folder under `/home/pi/drone_engage_config_backups`. Preserves the original directory structure (module subfolders). Automatically prunes old backups, keeping only the 3 most recent. Color-coded output for info, warnings, and errors.

## OTA Updates

- **sh_update_de_modules.sh**
  Performs over-the-air updates for DroneEngage modules (`de_camera`, `de_comm`, `de_mavlink`, `de_rpi_gpio`, `de_tracking`, `de_sdr`). For each module, fetches the latest version from a release server, downloads the tarball and checksum, verifies integrity via SHA256, backs up the current module (if present), extracts and installs the new version, fixes file permissions, and prunes old backups (keeps 3 most recent). Supports updating all modules or a specific module by name. Includes `--dry-run` mode to preview changes without applying them, and `--force` to ignore local version cache. Logs all actions with color-coded, timestamped output.

  **Usage:**
  ```bash
  sudo ./sh_update_de_modules.sh <url_base> [module_name|all] [--dry-run] [--force]
  ```

  **Examples:**
  - Update all modules: `sudo ./sh_update_de_modules.sh https://cloud.ardupilot.org/downloads/RPI/Latest`
  - Update specific module: `sudo ./sh_update_de_modules.sh https://cloud.ardupilot.org/downloads/RPI/Latest de_camera`
  - Dry run: `sudo ./sh_update_de_modules.sh https://cloud.ardupilot.org/downloads/RPI/Latest --dry-run`
  - Force update: `sudo ./sh_update_de_modules.sh https://cloud.ardupilot.org/downloads/RPI/Latest --force`

---

## Notes

- Both scripts require `sudo` for file operations.
- Default paths assume `/home/pi/drone_engage` for modules and `/home/pi/drone_engage_config_backups` or `/home/pi/drone_engage_backups` for backups.
- The update script requires network access to the release server and `curl` for downloads.
- Backups are automatically pruned to keep only the 3 most recent versions.
