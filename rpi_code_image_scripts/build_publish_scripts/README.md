# DroneEngage RPi Build & Publish Scripts

This folder contains scripts used to build, package, upload, and update DroneEngage modules for Raspberry Pi devices.

- de_camera
- de_comm
- de_mavlink
- de_rpi_gpio
- de_tracking
- de_sdr


## Where to run each script

- **sh_update_de_modules.sh**: Run on the target DroneEngageUnit (the RPi device). Performs OTA updates from the release server.
- **All other scripts in this folder** (build, package, upload): Run on the DroneEngage Code Builder Image.

Note: The camera module is compiled as part of the WebRTC code on an Ubuntu machine and is not built by the build scripts here. It is still packaged and updated via the packaging and OTA update scripts.


## Prerequisites

- **General (builder image)**
  - git with a configured `upstream` remote pointing to the authoritative repo
  - cmake, make, g++, build-essential
  - tar, sha256sum, ssh/scp
- **On DroneEngageUnit (device)**
  - curl, tar, sha256sum
  - Sufficient space under `/home/pi`
  - User and group `pi:pi` present


## Directory conventions used by scripts

- Build outputs (binaries and support files) are deployed to: `/home/pi/drone_engage_binary/<module>`
- Packaged artifacts are written to: `/home/pi/drone_engage_output/releases/`
- OTA backups are stored under: `/home/pi/drone_engage_backups`


## Build scripts (run on Code Builder Image)

Each build script follows the same pattern:
- Checks out a branch, runs a clean CMake build, and deploys results to `/home/pi/drone_engage_binary/<module>`
- Removes prior `build`, `logs`, and target deploy dir to ensure a clean build

Modules:
- **sh_build_de_communicator.sh**
  - Repo path: `~/de_code/droneengage_communication`
  - Branch: `release`
  - Deploys to: `~/drone_engage_binary/de_comm`
  - Verifies with: `de_comm -v`
- **sh_build_de_mavlink.sh**
  - Repo path: `~/de_code/droneengage_mavlink`
  - Branch: `release`
  - Deploys to: `~/drone_engage_binary/de_mavlink`
  - Verifies with: `de_ardupilot -v`
- **sh_build_de_rpi_gpio.sh**
  - Repo path: `~/de_code/droneengage_rpi_gpio`
  - Branch: `release`
  - Deploys to: `~/drone_engage_binary/de_rpi_gpio`
  - Verifies with: `de_rpi_gpio -v`
- **sh_build_de_tracking.sh**
  - Repo path: `~/de_code/droneengage_visual_tracker`
  - Branch: `release`
  - Deploys to: `~/drone_engage_binary/de_tracking`
  - Post-run shown: `de_ardupilot` (tracking depends on ArduPilot adapter)
- **sh_build_de_sdr.sh**
  - Repo path: `~/de_code/droneengage_sdr`
  - Branch: `master`
  - Deploys to: `~/drone_engage_binary/de_sdr`
  - Verifies with: `de_sdr -v`

Common commands inside each build script:
```bash
# clean and configure
rm -rf ./logs ./build "$DEPLOYMENT_TARGET_DIR"
mkdir build && cd build
cmake -D CMAKE_BUILD_TYPE=RELEASE ../
make

# deploy
mkdir -p "$DEPLOYMENT_TARGET_DIR"
cp "$PROJECT_ROOT_DIR"/bin/* "$DEPLOYMENT_TARGET_DIR/"
```


## Packaging (run on Code Builder Image)

- **sh_package_modules.sh** — Package each module directory under `/home/pi/drone_engage_binary` into versioned archives and checksums, and write `_LATEST` marker files.

Inputs and behavior:
- Arguments:
  - `./sh_package_modules.sh <version>` → package all modules with explicit version (e.g., `v3.1.0`)
  - `./sh_package_modules.sh <module>` → package only `<module>` with date-based version (`YYYYMMDD`)
  - `./sh_package_modules.sh <version> <module>` → package only `<module>` with explicit version
- Source root: `/home/pi/drone_engage_binary`
- Output dir: `/home/pi/drone_engage_output/releases/`
- Produces, per module:
  - `<module>_<version>.tar.gz`
  - `<module>_<version>.sha256`
  - Updates `<module>_LATEST` to contain the version string
- Packaging normalizes ownership and timestamps for reproducibility

Examples:
```bash
./sh_package_modules.sh v3.1.0
./sh_package_modules.sh de_camera
./sh_package_modules.sh v3.1.0 de_mavlink
```


## Uploading artifacts (run on Code Builder Image)

- **sh_upload_de_modules.sh** — Uploads packaged artifacts to the release server via scp.

Defaults (edit inside the script as needed):
- Source: `/home/pi/drone_engage_output/releases`
- Destination host: `cloud.ardupilot.org`
- Destination path: `/home/ap_cloud/binaries_download/RPI/Latest/`
- User: `root`
- SSH key: `/home/pi/.ssh/id_rsa`

Usage:
```bash
./sh_upload_de_modules.sh --help
./sh_upload_de_modules.sh
```

Behavior:
- Ensures destination path exists over SSH
- Uploads all `*.tar.gz`, `*.sha256`, and `*_LATEST`


## OTA update on device (run on DroneEngageUnit)

- **sh_update_de_modules.sh** — Pulls and installs latest modules on the device, with backup and checksum verification. Can target a specific module or all.

Arguments and examples:
```bash
# Update all modules from server (required: base URL)
sudo ./sh_update_de_modules.sh https://cloud.ardupilot.org/downloads/RPI/Latest

# Update only de_mavlink
sudo ./sh_update_de_modules.sh https://cloud.ardupilot.org/downloads/RPI/Latest de_mavlink

# Dry run (no changes)
sudo ./sh_update_de_modules.sh https://cloud.ardupilot.org/downloads/RPI/Latest --dry-run
```

Behavior:
- Known modules: `de_camera de_comm de_mavlink de_rpi_gpio de_tracking de_sdr`
- Reads `<module>_LATEST`, downloads `<module>_<version>.tar.gz` and `<module>_<version>.sha256`
- Verifies checksum, backs up existing module, extracts new contents into `/home/pi/drone_engage/<module>`
- Sets permissions and retains only the latest 3 backups per module

Requirements on device:
- `curl`, `tar`, `sha256sum`
- Writable `/home/pi/drone_engage` and `/home/pi/drone_engage_backups`


## Typical workflow

1. **Build** modules you need on the Code Builder Image
   - e.g., `./sh_build_de_mavlink.sh`
2. **Package** the resulting module directories
   - e.g., `./sh_package_modules.sh v3.1.0 de_mavlink`
3. **Upload** artifacts to the release server
   - e.g., `./sh_upload_de_modules.sh`
4. On each DroneEngageUnit, **Update** modules OTA
   - e.g., `sudo ./sh_update_de_modules.sh https://cloud.ardupilot.org/downloads/RPI/Latest`

Notes:
- The `de_camera` binary is built as part of the WebRTC codebase on Ubuntu; include its output under `/home/pi/drone_engage_binary/de_camera` before packaging.
- Ensure the `upstream` git remote is configured for each repo before running build scripts.
