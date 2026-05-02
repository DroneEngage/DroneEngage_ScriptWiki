# Camera Manager Wrapper

This folder contains a C++ wrapper application for managing DroneEngage camera and tracking modules on Raspberry Pi. The wrapper orchestrates the startup, monitoring, and graceful shutdown of multiple camera-related processes.

## Files

- **camera_manager_wrapper.cpp**
  C++ source code for the camera manager wrapper. Compiles to a single binary that manages the lifecycle of camera pipelines and tracking modules.

- **camera_manager_wrapper**
  Compiled binary (built with `g++ camera_manager_wrapper.cpp -o camera_manager_wrapper -pthread`).

## Features

- **Process Management**: Forks and monitors child processes for camera pipelines (`rpicam-vid | ffmpeg`), gimbal RTSP streams, tracking modules (`de_tracker`, `de_ai_tracker`, `de_yolo_generic`), and the main camera module (`de_camera`).
- **Triple AI Architecture**: Supports IMX500 hardware AI, HAILO software AI, and generic YOLO AI processing.
- **Virtual Camera Setup**: Automatically loads `v4l2loopback` kernel module to create named virtual cameras (`DE-CAM1`, `DE-CAM2`, `DE-TRK`, `DE-RPI`, `DE-THERMAL`, `DE-GIMBAL`).
- **Preemptive Cleanup**: Kills any stale camera processes before starting new instances to prevent conflicts.
- **Signal Handling**: Gracefully handles `SIGINT` and `SIGTERM` signals, stopping all child processes cleanly.
- **Crash Recovery**: Monitors child processes and exits on any crash, allowing systemd to restart the entire stack.
- **Custom Script Execution**: Supports running additional scripts via `--execute` option.
- **Configurable Paths**: Supports custom DroneEngage and scripts paths via command-line arguments.
- **Configurable Delays**: Supports custom startup delays for each module via command-line arguments.
- **Gimbal Camera Support**: Supports RTSP gimbal camera pipelines with configurable startup delay.

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
| `-m`, `--enable-gimbal-capture` | Enable gimbal RTSP camera capture pipeline |
| `-A`, `--ai-tracker-delay <seconds>` | Custom delay for AI tracker module (default: 5s) |
| `-G`, `--generic-ai-delay <seconds>` | Custom delay for generic AI module (default: 5s) |
| `-T`, `--tracker-delay <seconds>` | Custom delay for tracker module (default: 15s) |
| `-C`, `--de-camera-delay <seconds>` | Custom delay for de_camera module (default: 25s) |
| `-M`, `--gimbal-delay <seconds>` | Custom delay for gimbal camera pipeline (default: 0s) |
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

#### **Gimbal Camera Pipeline**
```bash
# RTSP gimbal camera with virtual camera output
./camera_manager_wrapper --enable-gimbal-capture
```
- Uses RTSP stream from gimbal camera
- Creates DE-GIMBAL virtual camera device
- **Used by**: `de_camera_gimbal.service`

#### **Custom Delays**
```bash
# Generic AI with custom startup delays
./camera_manager_wrapper --enable-generic-ai-tracker --generic-ai-delay 10
```
```bash
# Tracker and camera with custom delays
./camera_manager_wrapper --enable-tracker --tracker-delay 20 --de-camera-delay 30
```
```bash
# Gimbal camera with startup delay
./camera_manager_wrapper --enable-gimbal-capture --gimbal-delay 5
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

### **Gimbal Camera RTSP Pipeline**
- **Enabled with**: `-m` (gimbal capture)
- **Video Source**: RTSP stream from gimbal camera
- **Output**: Virtual camera device `DE-GIMBAL`
- **Module**: `sh_camera_run_gimbal_camera.sh` script
- **Performance**: Low CPU load (RTSP forwarding)
- **Service**: `de_camera_gimbal.service`

### **Key Differences**
| Feature | IMX500 Hardware AI | HAILO Software AI | Generic AI (YOLO) | Gimbal Camera |
|---------|-------------------|------------------|------------------|---------------|
| **Video Source** | RPi camera | Existing stream | Existing stream | RTSP stream |
| **AI Location** | Camera hardware | Host software | Host software | N/A |
| **JSON Config** | IMX500 model config | Not used | Not used | Not used |
| **Tracker Module** | `de_tracker` | `de_ai_tracker.so` | `de_yolo_generic` | N/A |
| **Virtual Camera** | `DE-RPI` | Uses existing | Uses existing | `DE-GIMBAL` |
| **CPU Load** | Low | Moderate | Variable | Low |
| **Flexibility** | Fixed models | Custom models | Custom models | N/A |
| **Startup Delay** | 15s (tracker) | 5s (AI tracker) | 5s (generic AI) | 0s (configurable) |
| **GPU Support** | N/A | N/A | Yes (via ONNX) | N/A |

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

## Technical Details

### `main` Function Overview

The `main` function in `camera_manager_wrapper.cpp` serves as the entry point for the camera manager wrapper program. It initializes and manages camera-related processes on a Raspberry Pi based on command-line arguments.

#### Function Definition

```cpp
int main(int argc, char *argv[])
{
    // Flags to control module activation
    bool enable_rpi_cam_capture = false;
    bool enable_gimbal_capture = false;  // NEW: Gimbal RTSP camera support
    bool enable_tracker = false;
    bool enable_ai_tracker = false;
    bool enable_generic_ai_tracker = false;
    bool enable_de_camera = true; // Default enabled

    std::string postProcessFilePath;
    std::vector<std::string> scripts_to_execute;
    
    // Module startup delays in seconds (with defaults) - NEW
    int ai_tracker_delay_sec = AI_TRACKER_MODULE_DELAY_SEC;
    int generic_ai_delay_sec = GENERIC_AI_MODULE_DELAY_SEC;
    int tracker_delay_sec = TRACKER_MODULE_DELAY_SEC;
    int de_camera_delay_sec = DE_CAMERA_MODULE_DELAY_SEC;
    int gimbal_delay_sec = 0; // Default: no delay for gimbal

    // Configurable paths
    std::string BASE_DRONE_ENGAGE_PATH = "/home/pi/drone_engage/";
    std::string SCRIPTS_PATH = "/home/pi/scripts/";

    std::cout << "Camera Wrapper ver: " << VERSION_APP << std::endl;

    // Parse command-line options using getopt_long
    static struct option long_options[] = {
        {"enable-rpi-cam-capture", no_argument, 0, 'c'},
        {"enable-gimbal-capture", no_argument, 0, 'm'},      // NEW
        {"enable-tracker", no_argument, 0, 't'},
        {"enable-ai-tracker", no_argument, 0, 'a'},
        {"enable-generic-ai-tracker", no_argument, 0, 'g'},
        {"disable-de-camera", no_argument, 0, 'd'},
        {"execute", required_argument, 0, 'e'},
        {"drone-engage-path", required_argument, 0, 'D'},
        {"scripts-path", required_argument, 0, 'S'},
        {"ai-tracker-delay", required_argument, 0, 'A'},    // NEW
        {"generic-ai-delay", required_argument, 0, 'G'},    // NEW
        {"tracker-delay", required_argument, 0, 'T'},        // NEW
        {"de-camera-delay", required_argument, 0, 'C'},      // NEW
        {"gimbal-delay", required_argument, 0, 'M'},         // NEW
        {"version", no_argument, 0, 'v'},
        {0, 0, 0, 0}};

    int opt;
    while ((opt = getopt_long(argc, argv, "cmtade:D:S:gvA:G:T:C:M:", long_options, nullptr)) != -1)
    {
        switch (opt)
        {
        case 'c': enable_rpi_cam_capture = true; break;
        case 'm': enable_gimbal_capture = true; break;        // NEW
        case 't': enable_tracker = true; break;
        case 'a': enable_ai_tracker = true; break;
        case 'g': enable_generic_ai_tracker = true; break;
        case 'd': enable_de_camera = false; break;
        case 'e': scripts_to_execute.push_back(optarg); break;
        case 'D': BASE_DRONE_ENGAGE_PATH = optarg; break;
        case 'S': SCRIPTS_PATH = optarg; break;
        case 'A': ai_tracker_delay_sec = std::atoi(optarg); break;   // NEW
        case 'G': generic_ai_delay_sec = std::atoi(optarg); break;   // NEW
        case 'T': tracker_delay_sec = std::atoi(optarg); break;       // NEW
        case 'C': de_camera_delay_sec = std::atoi(optarg); break;     // NEW
        case 'M': gimbal_delay_sec = std::atoi(optarg); break;        // NEW
        case 'v': std::cout << "Version: " << VERSION_APP << std::endl; return 0;
        default: print_usage_and_exit(); // Show examples and exit
        }
    }

    // Optional post-process config file
    if (optind < argc) postProcessFilePath = argv[optind];

    // Update derived module paths based on arguments
    BASE_CAMERA_MODULE_PATH = BASE_DRONE_ENGAGE_PATH + "de_camera/";
    BASE_TRACKER_MODULE_PATH = BASE_DRONE_ENGAGE_PATH + "de_tracking/";
    BASE_AI_TRACKER_MODULE_PATH = BASE_DRONE_ENGAGE_PATH + "de_ai_tracker/";
    std::string BASE_GENERIC_AI_MODULE_PATH = BASE_DRONE_ENGAGE_PATH + "de_yolo_generic/";

    // Display current paths and delays for debugging - NEW
    std::cout << "Using paths:" << std::endl;
    std::cout << "  DroneEngage: " << BASE_DRONE_ENGAGE_PATH << std::endl;
    std::cout << "  Scripts: " << SCRIPTS_PATH << std::endl;
    std::cout << "Module delays:" << std::endl;
    std::cout << "  AI Tracker: " << ai_tracker_delay_sec << "s" << std::endl;
    std::cout << "  Generic AI: " << generic_ai_delay_sec << "s" << std::endl;
    std::cout << "  Tracker: " << tracker_delay_sec << "s" << std::endl;
    std::cout << "  DE Camera: " << de_camera_delay_sec << "s" << std::endl;
    std::cout << "  Gimbal: " << gimbal_delay_sec << "s" << std::endl;

    // Setup signal handlers for SIGINT/SIGTERM
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    // Kill any stale camera processes before starting
    preemptiveKill();

    // Load v4l2loopback kernel module for virtual camera
    if (!executeCommand(create_vc_script + "/sh_camera_create_named_vc.sh")) {
        return 1;
    }

    // Start camera pipeline if requested
    if (enable_rpi_cam_capture)
    {
        camera_pid = startCameraPipeline(postProcessFilePath);
        if (camera_pid == -1) { /* critical failure */ }
        else if (camera_pid == 0) { /* no camera detected */ }
    }

    // Start gimbal RTSP pipeline if requested - NEW
    if (enable_gimbal_capture)
    {
        if (gimbal_delay_sec > 0)
        {
            std::this_thread::sleep_for(std::chrono::seconds(gimbal_delay_sec));
        }
        gimbal_camera_pid = startGimbalCameraPipeline();
        if (gimbal_camera_pid == -1) { /* critical failure */ }
    }

    // Start scripts, tracker, ai_tracker, generic_ai_tracker, de_camera with delays
    // ...
}
```

#### Parameters
- **`argc`, `argv[]`** – Standard command-line arguments. Supports long options including gimbal capture, configurable delays, and custom paths.

#### Side Effects
- Forks child processes (e.g., `rpicam-vid`, `de_camera`, `de_yolo_generic`)
- Modifies system state by loading kernel modules (`v4l2loopback`)
- Executes external scripts provided via `--execute`
- Registers signal handlers for `SIGINT` and `SIGTERM`
- Dynamically computes module paths based on command-line arguments
- Configures module startup delays for precise timing control

#### Returns
- **`int`** – 0 on success, non-zero on error or early exit (e.g., invalid args, failed process launch)

#### Example Usage Patterns

The program is typically invoked from shell scripts or deployment tools to start camera pipelines with specific configurations. Real-world examples are printed directly in the usage output within the code:

```cpp
std::cerr << "Usage: " << argv[0] << " [--enable-rpi-cam-capture] [--enable-gimbal-capture] [--enable-tracker] [--enable-ai-tracker] [--enable-generic-ai-tracker] [--disable-de-camera] [--execute script_path] [--drone-engage-path path] [--scripts-path path] [--ai-tracker-delay seconds] [--generic-ai-delay seconds] [--tracker-delay seconds] [--de-camera-delay seconds] [--gimbal-delay seconds] [postprocess_file_path]" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-rpi-cam-capture --enable-tracker" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-gimbal-capture" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-ai-tracker \"/usr/share/rpi-camera-assets/imx500_mobilenet_ssd.json\"" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-generic-ai-tracker" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-rpi-cam-capture --execute /path/to/script.sh" << std::endl;
std::cerr << "Example: " << argv[0] << " --drone-engage-path /custom/path/drone_engage --enable-rpi-cam-capture" << std::endl;
std::cerr << "Example: " << argv[0] << " --scripts-path /custom/scripts --enable-rpi-cam-capture" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-generic-ai-tracker --generic-ai-delay 10" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-tracker --tracker-delay 20 --de-camera-delay 30" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-gimbal-capture --gimbal-delay 5" << std::endl;
```

#### Implementation Notes

- Despite being a C++ program, `main` uses `fork()` and `execlp()` instead of higher-level process libraries, indicating a preference for direct Unix process control
- The function performs a **preemptive kill** of old camera processes at startup, suggesting that orphaned processes are a known issue in this environment
- The `--version` (`-v`) flag causes immediate exit after printing the version defined by `VERSION_APP` (currently "4.2.0")
- **NEW**: Module startup delays are configurable for precise timing control
- **NEW**: Supports gimbal RTSP camera pipelines with DE-GIMBAL virtual camera
- **NEW**: All delays are absolute (seconds since start), not incremental

#### Key Functions

- `startCameraPipeline`: Launches the `rpicam-vid | ffmpeg` pipeline; called conditionally from `main` when local capture is enabled
- `startGimbalCameraPipeline`: Launches the RTSP | ffmpeg pipeline for gimbal cameras; called conditionally from `main` when gimbal capture is enabled
- `startModule`: Generic helper to fork and exec other modules like tracking binaries
- `preemptiveKill`: Ensures no stale camera processes interfere with new instances; critical for reliable operation
- `signal_handler`: Handles `SIGINT`/`SIGTERM` by calling `preemptiveKill()` and exiting cleanly
- `VERSION_APP`: Macro or defined constant holding the application version ("4.2.0")

---

## Version

Current version: **4.2.0**

---

## Notes

- Requires `sudo` for killing processes and loading kernel modules.
- Expects helper scripts in `/home/pi/scripts/` (configurable via `--scripts-path`):
  - `sh_camera_create_named_vc.sh`
  - `sh_kill_all_camera_apps.sh`
  - `sh_camera_run_rpi_camera.sh`
  - `sh_camera_run_gimbal_camera.sh`
- Designed to run as a systemd service for automatic restart on failure.
- Uses Unix `fork()`/`execlp()` for direct process control.
- **NEW**: Module startup delays are configurable for precise timing control.
- **NEW**: Supports gimbal RTSP camera pipelines with DE-GIMBAL virtual camera.
- **NEW**: All delays are absolute (seconds since start), not incremental.
