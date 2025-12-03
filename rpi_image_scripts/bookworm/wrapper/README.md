# Camera Manager Wrapper

This folder contains a C++ wrapper application for managing DroneEngage camera and tracking modules on Raspberry Pi. The wrapper orchestrates the startup, monitoring, and graceful shutdown of multiple camera-related processes.

## Files

- **camera_manager_wrapper.cpp**
  C++ source code for the camera manager wrapper. Compiles to a single binary that manages the lifecycle of camera pipelines and tracking modules.

- **camera_manager_wrapper**
  Compiled binary (built with `g++ camera_manager_wrapper.cpp -o camera_manager_wrapper -pthread`).

- **camera_manager_wrapper.md**
  Detailed documentation of the `main` function and internal logic.

## Features

- **Process Management**: Forks and monitors child processes for camera pipelines (`rpicam-vid | ffmpeg`), tracking modules (`de_tracker`, `de_ai_tracker`), and the main camera module (`de_camera`).
- **Virtual Camera Setup**: Automatically loads `v4l2loopback` kernel module to create named virtual cameras (`DE-CAM1`, `DE-CAM2`, `DE-TRK`, `DE-RPI`, `DE-THERMAL`).
- **Preemptive Cleanup**: Kills any stale camera processes before starting new instances to prevent conflicts.
- **Signal Handling**: Gracefully handles `SIGINT` and `SIGTERM` signals, stopping all child processes cleanly.
- **Crash Recovery**: Monitors child processes and exits on any crash, allowing systemd to restart the entire stack.
- **Custom Script Execution**: Supports running additional scripts via `--execute` option.

## Usage

```bash
./camera_manager_wrapper [OPTIONS] [postprocess_file_path]
```

### Options

| Option | Description |
|--------|-------------|
| `-c`, `--enable-rpi-cam-capture` | Enable Raspberry Pi camera capture pipeline |
| `-t`, `--enable-tracker` | Enable `de_tracker` tracking module |
| `-a`, `--enable-ai-tracker` | Enable `de_ai_tracker` AI tracking module |
| `-d`, `--disable-de-camera` | Disable `de_camera` module (enabled by default) |
| `-e`, `--execute <script>` | Execute a custom script (can be specified multiple times) |
| `-v`, `--version` | Print version and exit |

### Examples

```bash
# Enable camera capture and tracking
./camera_manager_wrapper --enable-rpi-cam-capture --enable-tracker

# Enable AI tracking with a model config
./camera_manager_wrapper --enable-ai-tracker "/usr/share/rpi-camera-assets/imx500_mobilenet_ssd.json"

# Enable camera capture with a custom script
./camera_manager_wrapper --enable-rpi-cam-capture --execute /path/to/script.sh

# Disable de_camera module
./camera_manager_wrapper --disable-de-camera --enable-tracker
```

## Module Paths

The wrapper expects DroneEngage modules at the following locations:

| Module | Path |
|--------|------|
| `de_camera` | `/home/pi/drone_engage/de_camera/` |
| `de_tracker` | `/home/pi/drone_engage/de_tracking/` |
| `de_ai_tracker` | `/home/pi/drone_engage/de_ai_tracker/` |

## Build

```bash
g++ camera_manager_wrapper.cpp -o camera_manager_wrapper -pthread
```

---

## Notes

- Requires `sudo` for killing processes and loading kernel modules.
- Expects helper scripts in `/home/pi/scripts/` (e.g., `sh_camera_create_named_vc.sh`, `sh_kill_all_camera_apps.sh`, `sh_camera_run_rpi_camera.sh`).
- Designed to run as a systemd service for automatic restart on failure.
- Uses Unix `fork()`/`execlp()` for direct process control.
