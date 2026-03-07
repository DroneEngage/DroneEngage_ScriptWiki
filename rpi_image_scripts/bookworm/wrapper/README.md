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

- **Process Management**: Forks and monitors child processes for camera pipelines (`rpicam-vid | ffmpeg`), tracking modules (`de_tracker`, `de_ai_tracker`, `de_yolo_generic`), and the main camera module (`de_camera`).
- **Triple AI Architecture**: Supports IMX500 hardware AI, HAILO software AI, and generic YOLO AI processing.
- **Virtual Camera Setup**: Automatically loads `v4l2loopback` kernel module to create named virtual cameras (`DE-CAM1`, `DE-CAM2`, `DE-TRK`, `DE-RPI`, `DE-THERMAL`).
- **Preemptive Cleanup**: Kills any stale camera processes before starting new instances to prevent conflicts.
- **Signal Handling**: Gracefully handles `SIGINT` and `SIGTERM` signals, stopping all child processes cleanly.
- **Crash Recovery**: Monitors child processes and exits on any crash, allowing systemd to restart the entire stack.
- **Custom Script Execution**: Supports running additional scripts via `--execute` option.
- **Configurable Paths**: Supports custom DroneEngage and scripts paths via command-line arguments.

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
| `-g`, `--enable-generic-ai-tracker` | Enable `de_yolo_generic` AI tracking module |
| `-d`, `--disable-de-camera` | Disable `de_camera` module (enabled by default) |
| `-e`, `--execute <script>` | Execute a custom script (can be specified multiple times) |
| `-D`, `--drone-engage-path <path>` | Custom DroneEngage modules path (default: `/home/pi/drone_engage/`) |
| `-S`, `--scripts-path <path>` | Custom scripts path (default: `/home/pi/scripts/`) |
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

#### **Generic AI (YOLO) Tracking**
```bash
# Generic YOLO AI processing
./camera_manager_wrapper --enable-generic-ai-tracker
```
- Uses `de_yolo_generic` module for flexible AI processing
- Supports custom YOLO models via ONNX runtime
- Can work with GPU acceleration if available

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

#### **Custom Paths**
```bash
# Using custom DroneEngage and scripts paths
./camera_manager_wrapper --drone-engage-path /custom/de/path --scripts-path /custom/scripts --enable-rpi-cam-capture
```

## AI Processing Architecture

The wrapper supports three distinct AI processing approaches:

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

### **Generic AI (YOLO)**
- **Enabled with**: `-g` (generic AI tracker)
- **AI Processing**: Software inference using ONNX runtime
- **Module**: `de_yolo_generic` executable
- **Performance**: Flexible YOLO model deployment with GPU/CPU support
- **CPU Load**: Variable (depends on model and hardware acceleration)

### **Key Differences**
| Feature | IMX500 Hardware AI | HAILO Software AI | Generic AI (YOLO) |
|---------|-------------------|------------------|------------------|
| **AI Location** | Camera hardware | Host software | Host software |
| **JSON Config** | IMX500 model config | Not used | Not used |
| **Tracker Module** | `de_tracker` | `de_ai_tracker.so` | `de_yolo_generic` |
| **CPU Load** | Low | Moderate | Variable |
| **Flexibility** | Fixed models | Custom models | Custom models |
| **Startup Delay** | 15s (tracker) | 5s (AI tracker) | 5s (generic AI) |
| **GPU Support** | N/A | N/A | Yes (via ONNX) |

---

## Module Paths

The wrapper expects DroneEngage modules at the following locations (default paths, configurable via arguments):

| Module | Default Path |
|--------|--------------|
| `de_camera` | `/home/pi/drone_engage/de_camera/` |
| `de_tracker` | `/home/pi/drone_engage/de_tracking/` |
| `de_ai_tracker` | `/home/pi/drone_engage/de_ai_tracker/` |
| `de_yolo_generic` | `/home/pi/drone_engage/de_yolo_generic/` |

## Build

```bash
g++ camera_manager_wrapper.cpp -o camera_manager_wrapper -pthread
```

---

## Version

Current version: **4.0.0**

---

## Notes

- Requires `sudo` for killing processes and loading kernel modules.
- Expects helper scripts in `/home/pi/scripts/` (configurable via `--scripts-path`):
  - `sh_camera_create_named_vc.sh`
  - `sh_kill_all_camera_apps.sh`
  - `sh_camera_run_rpi_camera.sh`
- Designed to run as a systemd service for automatic restart on failure.
- Uses Unix `fork()`/`execlp()` for direct process control.
- **NEW**: Module paths are configurable for flexible deployment scenarios.
- **NEW**: Supports generic YOLO AI processing via `de_yolo_generic` module.
