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
- **Dual AI Architecture**: Supports both IMX500 hardware AI and HAILO software AI processing.
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
| `-t`, `--enable-tracker` | Enable `de_tracker` software tracking module |
| `-a`, `--enable-ai-tracker` | Enable `de_ai_tracker.so` HAILO AI tracking module |
| `-d`, `--disable-de-camera` | Disable `de_camera` module (enabled by default) |
| `-e`, `--execute <script>` | Execute a custom script (can be specified multiple times) |
| `-v`, `--version` | Print version and exit |

### Examples

#### **IMX500 Hardware AI + Software Tracking**
```bash
# Sony IMX500 camera with hardware AI + software tracking
./camera_manager_wrapper --enable-rpi-cam-capture --enable-tracker "/usr/share/rpi-camera-assets/imx500_mobilenet_ssd.json"
```
- Uses Sony IMX500 camera with built-in hardware AI acceleration
- JSON configures IMX500 AI model (MobileNet-SSD)
- Software tracker (`de_tracker`) handles object tracking/detection
- **Used by**: `de_camera_imx_ai.service`

#### **HAILO Software AI Tracking**
```bash
# HAILO AI accelerator with software AI processing
./camera_manager_wrapper --enable-ai-tracker
```
- Uses HAILO AI accelerator for software-based AI processing
- Runs `de_ai_tracker.so` module with AI inference
- No camera pipeline needed (uses existing video streams)

#### **Regular Camera + Software Tracking**
```bash
# Standard RPi camera with software tracking
./camera_manager_wrapper --enable-rpi-cam-capture --enable-tracker
```
- Standard RPi camera without hardware AI
- Software-based tracking and detection
- **Used by**: `de_camera_tracker.service`

#### **Camera Only**
```bash
# Camera pipeline without tracking
./camera_manager_wrapper --enable-rpi-cam-capture
```
- **Used by**: `de_camera_rpi_cam.service`

#### **Custom Script Integration**
```bash
# Camera with custom post-processing script
./camera_manager_wrapper --enable-rpi-cam-capture --execute /path/to/script.sh /path/to/config.json
```

## AI Processing Architecture

The wrapper supports two distinct AI processing approaches:

### **IMX500 Hardware AI (Sony RPi AI Camera)**
- **Enabled with**: `-c` (camera) + `-t` (tracker) + JSON config file
- **AI Processing**: Done on-camera hardware (Sony IMX500 sensor)
- **JSON Purpose**: Configures IMX500 AI model and parameters
- **Tracker**: Software-based (`de_tracker`) for object tracking
- **Performance**: High-performance AI with minimal CPU load
- **Service**: `de_camera_imx_ai.service`

### **HAILO Software AI**
- **Enabled with**: `-a` (AI tracker)
- **AI Processing**: Software inference using HAILO accelerator
- **Module**: `de_ai_tracker.so` shared library
- **Performance**: Flexible AI model deployment with HAILO hardware
- **CPU Load**: Moderate (software inference)

### **Key Differences**
| Feature | IMX500 Hardware AI | HAILO Software AI |
|---------|-------------------|------------------|
| **AI Location** | Camera hardware | Host software |
| **JSON Config** | IMX500 model config | Not used |
| **Tracker Module** | `de_tracker` | `de_ai_tracker.so` |
| **CPU Load** | Low | Moderate |
| **Flexibility** | Fixed models | Custom models |
| **Startup Delay** | 15s (tracker) | 5s (AI tracker) |

---

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
