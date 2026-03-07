`main` is a C++ function serving as the entry point for the `camera_manager_wrapper` program.  
It initializes and manages camera-related processes on a Raspberry Pi, based on command-line arguments.

---

### Definition

The `main` function in `camera_manager_wrapper.cpp` orchestrates the startup of various camera and tracking modules used in a Raspberry Pi-based imaging system. It parses command-line flags to determine which components to enable, sets up signal handling for graceful shutdowns, and launches child processes accordingly.

```cpp
304:591:/home/mhefny/TDisk/public_versions/scripts_wiki/rpi_image_scripts/bookworm/wrapper/camera_manager_wrapper.cpp
int main(int argc, char *argv[])
{
    // Flags to control module activation
    bool enable_rpi_cam_capture = false;
    bool enable_tracker = false;
    bool enable_ai_tracker = false;
    bool enable_generic_ai_tracker = false;  // NEW: Generic AI tracker support
    bool enable_de_camera = true; // Default enabled

    std::string postProcessFilePath;
    std::vector<std::string> scripts_to_execute;

    // Configurable paths (NEW)
    std::string BASE_DRONE_ENGAGE_PATH = "/home/pi/drone_engage/";
    std::string SCRIPTS_PATH = "/home/pi/scripts/";

    std::cout << "Camera Wrapper ver: " << VERSION_APP << std::endl;

    // Parse command-line options using getopt_long
    static struct option long_options[] = {
        {"enable-rpi-cam-capture", no_argument, 0, 'c'},
        {"enable-tracker", no_argument, 0, 't'},
        {"enable-ai-tracker", no_argument, 0, 'a'},
        {"enable-generic-ai-tracker", no_argument, 0, 'g'},  // NEW
        {"disable-de-camera", no_argument, 0, 'd'},
        {"execute", required_argument, 0, 'e'},
        {"drone-engage-path", required_argument, 0, 'D'},  // NEW
        {"scripts-path", required_argument, 0, 'S'},        // NEW
        {"version", no_argument, 0, 'v'},
        {0, 0, 0, 0}};

    int opt;
    while ((opt = getopt_long(argc, argv, "ctagde:D:S:gv", long_options, nullptr)) != -1)
    {
        switch (opt)
        {
        case 'c': enable_rpi_cam_capture = true; break;
        case 't': enable_tracker = true; break;
        case 'a': enable_ai_tracker = true; break;
        case 'g': enable_generic_ai_tracker = true; break;  // NEW
        case 'd': enable_de_camera = false; break;
        case 'e': scripts_to_execute.push_back(optarg); break;
        case 'D': BASE_DRONE_ENGAGE_PATH = optarg; break;   // NEW
        case 'S': SCRIPTS_PATH = optarg; break;             // NEW
        case 'v': std::cout << "Version: " << VERSION_APP << std::endl; return 0;
        default: print_usage_and_exit(); // Show examples and exit
        }
    }

    // Optional post-process config file
    if (optind < argc) postProcessFilePath = argv[optind];

    // Update derived module paths based on arguments (NEW)
    BASE_CAMERA_MODULE_PATH = BASE_DRONE_ENGAGE_PATH + "de_camera/";
    BASE_TRACKER_MODULE_PATH = BASE_DRONE_ENGAGE_PATH + "de_tracking/";
    BASE_AI_TRACKER_MODULE_PATH = BASE_DRONE_ENGAGE_PATH + "de_ai_tracker/";
    std::string BASE_GENERIC_AI_MODULE_PATH = BASE_DRONE_ENGAGE_PATH + "de_yolo_generic/";

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

    // Start scripts, tracker, ai_tracker, generic_ai_tracker, de_camera with delays
    // ...
}
```

- **Params**:  
  `argc`, `argv[]` – Standard command-line arguments. Supports long options including new `--enable-generic-ai-tracker`, `--drone-engage-path`, and `--scripts-path`.
- **Side effects**:  
  - Forks child processes (e.g., `rpicam-vid`, `de_camera`, `de_yolo_generic`).  
  - Modifies system state by loading kernel modules (`v4l2loopback`).  
  - Executes external scripts provided via `--execute`.  
  - Registers signal handlers for `SIGINT` and `SIGTERM`.
  - Dynamically computes module paths based on command-line arguments.
- **Returns**:  
  `int` – 0 on success, non-zero on error or early exit (e.g., invalid args, failed process launch).

---

### Example Usages

This program is typically invoked from shell scripts or deployment tools to start camera pipelines with specific configurations. Real-world examples are printed directly in the usage output within the code.

```cpp
391:398:/home/mhefny/TDisk/public_versions/scripts_wiki/rpi_image_scripts/bookworm/wrapper/camera_manager_wrapper.cpp
std::cerr << "Usage: " << argv[0] << " [--enable-rpi-cam-capture] [--enable-tracker] [--enable-ai-tracker] [--enable-generic-ai-tracker] [--disable-de-camera] [--execute script_path] [--drone-engage-path path] [--scripts-path path] [postprocess_file_path]" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-rpi-cam-capture --enable-tracker" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-ai-tracker \"/usr/share/rpi-camera-assets/imx500_mobilenet_ssd.json\"" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-generic-ai-tracker" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-rpi-cam-capture --execute /path/to/script.sh" << std::endl;
std::cerr << "Example: " << argv[0] << " --drone-engage-path /custom/path/drone_engage --enable-rpi-cam-capture" << std::endl;
std::cerr << "Example: " << argv[0] << " --scripts-path /custom/scripts --enable-rpi-cam-capture" << std::endl;
```

These show how the binary can be used:
- **IMX500 Hardware AI + Software Tracking**:  
  `./camera_manager_wrapper --enable-rpi-cam-capture --enable-tracker "/usr/share/rpi-camera-assets/imx500_mobilenet_ssd.json"`
  - Uses Sony IMX500 camera with built-in hardware AI acceleration
  - JSON configures the IMX500 AI model (e.g., MobileNet-SSD)
  - Software tracker (`de_tracker`) handles object tracking/detection
- **HAILO Software AI Tracking**:  
  `./camera_manager_wrapper --enable-ai-tracker`
  - Uses HAILO AI accelerator for software-based AI processing
  - Runs `de_ai_tracker.so` module with AI inference
  - No camera pipeline needed (uses existing video streams)
- **Generic AI Tracking**:  
  `./camera_manager_wrapper --enable-generic-ai-tracker`
  - Uses `de_yolo_generic` module for flexible AI processing
  - Supports custom YOLO models via ONNX runtime
- **Regular Camera + Tracking**:  
  `./camera_manager_wrapper --enable-rpi-cam-capture --enable-tracker`
  - Standard RPi camera without hardware AI
  - Software-based tracking and detection
- **Custom Script Integration**:  
  `./camera_manager_wrapper --enable-rpi-cam-capture --execute /home/pi/myscript.sh /path/to/config.json`
- **Custom Paths**:  
  `./camera_manager_wrapper --drone-engage-path /custom/de/path --scripts-path /custom/scripts --enable-rpi-cam-capture`

The `main` function is central to the camera management system on the Raspberry Pi and appears to be invoked during system startup or via service managers to initialize imaging pipelines.

---

### AI Processing Architecture

The wrapper supports three distinct AI processing approaches:

#### **IMX500 Hardware AI (Sony RPi AI Camera)**
- **Enabled with**: `-c` (camera) + `-t` (tracker) + JSON config file
- **AI Processing**: Done on-camera hardware (Sony IMX500 sensor)
- **JSON Purpose**: Configures IMX500 AI model and parameters
- **Tracker**: Software-based (`de_tracker`) for object tracking
- **Use Case**: High-performance AI with minimal CPU load

#### **HAILO Software AI**
- **Enabled with**: `-a` (AI tracker)
- **AI Processing**: Software inference using HAILO accelerator
- **Module**: `de_ai_tracker.so` shared library
- **Use Case**: Flexible AI model deployment with HAILO hardware

#### **Generic AI (YOLO)**
- **Enabled with**: `-g` (generic AI tracker) - NEW
- **AI Processing**: Software inference using ONNX runtime
- **Module**: `de_yolo_generic` executable
- **Use Case**: Custom YOLO models with GPU/CPU acceleration

#### **Key Differences**
| Feature | IMX500 Hardware AI | HAILO Software AI | Generic AI (YOLO) |
|---------|-------------------|------------------|------------------|
| **AI Location** | Camera hardware | Host software | Host software |
| **JSON Config** | IMX500 model config | Not used | Not used |
| **Tracker Module** | `de_tracker` | `de_ai_tracker.so` | `de_yolo_generic` |
| **CPU Load** | Low | Moderate | Variable |
| **Flexibility** | Fixed models | Custom models | Custom models |
| **Startup Delay** | 15s (tracker) | 5s (AI tracker) | 5s (generic AI) |

---

### Notes

- Despite being a C++ program, `main` uses `fork()` and `execlp()` instead of higher-level process libraries, indicating a preference for direct Unix process control.
- The function performs a **preemptive kill** of old camera processes at startup, suggesting that orphaned processes are a known issue in this environment.
- The `--version` (`-v`) flag causes immediate exit after printing the version defined by `VERSION_APP` (currently "4.0.0").
- **NEW**: Module paths are now configurable via command-line arguments, allowing for flexible deployment scenarios.
- **NEW**: Support for generic AI tracker enables custom YOLO model deployment.

---

### See Also

- `startCameraPipeline`: Launches the `rpicam-vid | ffmpeg` pipeline; called conditionally from `main` when local capture is enabled.
- `startModule`: Generic helper to fork and exec other modules like tracking binaries.
- `preemptiveKill`: Ensures no stale camera processes interfere with new instances; critical for reliable operation.
- `signal_handler`: Handles `SIGINT`/`SIGTERM` by calling `preemptiveKill()` and exiting cleanly.
- `VERSION_APP`: Macro or defined constant holding the application version ("4.0.0").