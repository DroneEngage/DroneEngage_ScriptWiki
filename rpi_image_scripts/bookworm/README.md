# Raspberry Pi Bookworm Scripts (High-Level Summary)

This folder contains helper and management scripts for Raspberry Pi OS (Bookworm/Bullseye) to operate DroneEngage services, networking (AP/Client), cameras, simulators, and maintenance tasks.

## Service Management
- **enable_and_restart_services.sh**
  Enables and starts DroneEngage core services: `de_communicator.service`, `de_mavlink.service`.

- **disable_droneengage_service.sh**
  Disables and stops DroneEngage services: `de_communicator.service`, `de_mavlink.service`, `de_camera.service`.

- **restart_droneengage_services.sh**
  Restarts DroneEngage services: `de_communicator.service`, `de_mavlink.service`, `de_camera.service`.

- **stop_droneengage_services.sh**
  Stops `de_communicator.service` and `de_mavlink.service`.

- **enable_and_restart_rpi_cam.sh**
  Unmasks, enables, and starts `de_camera_rpi_cam.service`.

- **stop_rpi_cam.sh**
  Stops `de_camera_rpi_cam.service`.

## Networking (Wi‑Fi)
- **create_ap.sh**
  Sets up a classic AP using `hostapd` and `dnsmasq` with a static IP, DHCP range, domain redirection to AP IP, IPv4 forwarding, and persistent NAT via systemd. Prompts for SSID/password and reboots.

- **wifi_start_ap.sh**
  Creates a NetworkManager hotspot AP (SSID `DE_ADMIN`, WPA2) on `wlan0`, with shared IPv4 (192.169.9.1/24). Stops/disables `hostapd`/`dnsmasq` to avoid conflicts.

- **wifi_use_wlan.sh**
  Connects to a Wi‑Fi network as a client using NetworkManager (`nmcli`). Cleans up any existing hotspot profile, creates or reuses a connection for given SSID/password, brings it up, and prints status.

## Camera and Video
- **sh_camera_create_named_vc.sh**
  Loads `v4l2loopback` to create multiple named virtual cameras with labels: `DE-CAM1`, `DE-CAM2`, `DE-TRK`, `DE-RPI`, `DE-THERMAL`.

- **sh_camera_run_rpi_camera.sh**
  Streams from Raspberry Pi camera using `rpicam-vid` and forwards via `ffmpeg` to the virtual camera labeled `DE-RPI`. Optionally accepts a rpicam post-process JSON.

- **sh_camera_senxor_thermal_run_on_vc.sh**
  Runs a thermal pipeline (`thermal_toolbox.py`) and pipes frames via `ffmpeg` to the virtual camera labeled `DE-THERMAL`.

- **sh_stream_from_camera.sh**
  Simple GStreamer pipeline from `libcamerasrc` to a v4l2 sink device (e.g., `/dev/video3`).

- **sh_kill_all_camera_apps.sh**
  Force-kills camera-related processes (`rpicam-vid`, `de_*tracker.so`, `de_camera64.so`) and restores terminal settings.

## Simulators
- **sh_start_simulators.sh**
  Stops previous simulators, cleans logs/terrain, then starts two `de_comm` + two `de_mavlink` instances and two ArduPilot SITL `arducopter` instances. Detaches processes and prints a summary.

- **sh_stop_simulators.sh**
  Gracefully terminates any running `arducopter`, `de_comm`, and `de_ardupilot` processes with retries and verification.

## Configuration and Utilities
- **sh_update_de_comm_config_in_sim.sh**
  Reads `userName`, `accessCode`, and `auth_ip` from an input JSON (comments removed on-the-fly) and updates those fields in a target simulation config JSON (creates a `.bak` backup).

- **sh_reset_config_local_files.sh**
  Deletes all `*.local` files under `/home/pi/drone_engage/` (or a specified directory).

- **hlp_delete_file_instances.sh**
  Searches for all instances of a given filename across the filesystem and deletes them after user confirmation.

- **hlp_check_open_ports.sh**
  Displays open TCP/UDP ports by PID or by application name using `ss` and `lsof`.

- **hlp_reset_oem.sh**
  Runs config update tool with placeholder credentials for multiple module configs, starts AP (`wifi_start_ap.sh`), and performs log cleanup (`sh_clean_logs.sh`).

- **isBullseye.sh**
  Detects whether the OS is Raspberry Pi OS Bullseye or Bookworm by checking `/etc/os-release`.

## Maintenance
- **sh_clean_logs.sh**
  Aggressive cleanup for image sanitization: clears journals, app logs (including rotated), temp files, APT caches, old kernels (keeps current + one), user caches and sensitive configs (e.g., SSH keys), regenerates SSH host keys, clears crontabs, and removes select backup/local files under `/home/pi`. Prints disk usage after.

---

Notes
- Many scripts require sudo and assume specific paths under `/home/pi`.
- Camera scripts expect `v4l2loopback`, `ffmpeg`, and `rpicam-apps` to be installed.
- Networking scripts may disrupt connectivity; run from console or be ready to reconnect.
