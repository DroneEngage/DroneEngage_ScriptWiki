`main` is a C++ function serving as the entry point for the `camera_manager_wrapper` program.  
It initializes and manages camera-related processes on a Raspberry Pi, based on command-line arguments.

---

### Definition

The `main` function in `camera_manager_wrapper.cpp` orchestrates the startup of various camera and tracking modules used in a Raspberry Pi-based imaging system. It parses command-line flags to determine which components to enable, sets up signal handling for graceful shutdowns, and launches child processes accordingly.

```cpp
270:370:/home/mhefny/TDisk/public_versions/scripts_wiki/rpi_image_scripts/bookworm/wrapper/camera_manager_wrapper.cpp
int main(int argc, char *argv[])
{
    // Flags to control module activation
    bool enable_local_cam_capture = false;
    bool enable_tracker = false;
    bool enable_ai_tracker = false;
    bool enable_de_camera = true; // Default enabled

    std::string postProcessFilePath;
    std::vector<std::string> scripts_to_execute;

    std::cout << "Camera Wrapper ver: " << VERSION_APP << std::endl;

    // Parse command-line options using getopt_long
    while ((opt = getopt_long(argc, argv, "ctade:v", long_options, nullptr)) != -1)
    {
        switch (opt)
        {
        case 'c': enable_local_cam_capture = true; break;
        case 't': enable_tracker = true; break;
        case 'a': enable_ai_tracker = true; break;
        case 'd': enable_de_camera = false; break;
        case 'e': scripts_to_execute.push_back(optarg); break;
        case 'v': std::cout << "Version: " << VERSION_APP << std::endl; return 0;
        default: print_usage_and_exit(); // Show examples and exit
        }
    }

    // Optional post-process config file
    if (optind < argc) postProcessFilePath = argv[optind];

    // Setup signal handlers for SIGINT/SIGTERM
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    // Kill any stale camera processes before starting
    preemptiveKill();

    // Load v4l2loopback kernel module for virtual camera
    if (!executeCommand("/home/pi/scripts/sh_camera_create_named_vc.sh")) {
        return 1;
    }

    // Start camera pipeline if requested
    if (enable_local_cam_capture)
    {
        camera_pid = startCameraPipeline(postProcessFilePath);
        if (camera_pid == -1) { /* critical failure */ }
        else if (camera_pid == 0) { /* no camera detected */ }
    }
    else
    {
        std::cout << "Skipping camera pipeline (not enabled)." << std::endl;
    }

    // Remaining modules (tracker, ai_tracker, de_camera) would be started here
    // ...
}
```

- **Params**:  
  `argc`, `argv[]` – Standard command-line arguments. Supports long options like `--enable-rpi-cam-capture`, `--execute`, etc.
- **Side effects**:  
  - Forks child processes (e.g., `rpicam-vid`, `de_camera64.so`).  
  - Modifies system state by loading kernel modules (`v4l2loopback`).  
  - Executes external scripts provided via `--execute`.  
  - Registers signal handlers for `SIGINT` and `SIGTERM`.
- **Returns**:  
  `int` – 0 on success, non-zero on error or early exit (e.g., invalid args, failed process launch).

---

### Example Usages

This program is typically invoked from shell scripts or deployment tools to start camera pipelines with specific configurations. Real-world examples are printed directly in the usage output within the code.

```cpp
322:325:/home/mhefny/TDisk/public_versions/scripts_wiki/rpi_image_scripts/bookworm/wrapper/camera_manager_wrapper.cpp
std::cerr << "Usage: " << argv[0] << " [--enable-rpi-cam-capture] [--enable-tracker] [--enable-ai-tracker] [--disable-de-camera] [--execute script_path] [postprocess_file_path]" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-rpi-cam-capture --enable-tracker" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-ai-tracker \"/usr/share/rpi-camera-assets/imx500_mobilenet_ssd.json\"" << std::endl;
std::cerr << "Example: " << argv[0] << " --enable-rpi-cam-capture --execute /path/to/script.sh" << std::endl;
```

These show how the binary can be used:
- To enable local camera capture and tracking:  
  `./camera_manager_wrapper --enable-rpi-cam-capture --enable-tracker`
- To run AI-based tracking with a model config:  
  `./camera_manager_wrapper --enable-ai-tracker "/usr/share/rpi-camera-assets/imx500_mobilenet_ssd.json"`
- To run with a custom post-processing script:  
  `./camera_manager_wrapper --enable-rpi-cam-capture --execute /home/pi/myscript.sh /path/to/config.json`

The `main` function is central to the camera management system on the Raspberry Pi and appears to be invoked during system startup or via service managers to initialize imaging pipelines.

---

### Notes

- Despite being a C++ program, `main` uses `fork()` and `execlp()` instead of higher-level process libraries, indicating a preference for direct Unix process control.
- The function performs a **preemptive kill** of old camera processes at startup, suggesting that orphaned processes are a known issue in this environment.
- The `--version` (`-v`) flag causes immediate exit after printing the version defined by `VERSION_APP`, which is likely set at compile time.

---

### See Also

- `startCameraPipeline`: Launches the `rpicam-vid | ffmpeg` pipeline; called conditionally from `main` when local capture is enabled.
- `startModule`: Generic helper to fork and exec other modules like tracking binaries.
- `preemptiveKill`: Ensures no stale camera processes interfere with new instances; critical for reliable operation.
- `signal_handler`: Handles `SIGINT`/`SIGTERM` by calling `preemptiveKill()` and exiting cleanly.
- `VERSION_APP`: Macro or defined constant holding the application version, printed at startup.