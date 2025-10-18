//***************************************************************************** */
//  Wrapper to run Camera & Related Software with optional modules and camera pipeline
//
//  Auth: Mohammad S. Hefny
//  Date: Aug 2025
//
//***************************************************************************** */

// g++ camera_manager_wrapper.cpp -o camera_manager_wrapper -pthread
#include <iostream>    // For standard input/output operations
#include <string>      // For std::string
#include <vector>      // For std::vector to handle multiple scripts
#include <cstdlib>     // For system(), exit()
#include <thread>      // For std::this_thread::sleep_for
#include <chrono>      // For std::chrono::seconds
#include <sys/types.h> // For pid_t
#include <sys/wait.h>  // For waitpid()
#include <unistd.h>    // For fork(), execlp(), kill(), chdir()
#include <csignal>     // For SIGTERM, SIGINT
#include <getopt.h>    // For parsing command-line options

#define VERSION_APP "3.0.0"

// Global PID variables to track child processes
pid_t camera_pid = -1;
pid_t tracking_camera_pid = -1;
pid_t ai_tracking_camera_pid = -1;
pid_t de_camera_pid = -1;
std::vector<pid_t> script_pids; // To track PIDs of executed scripts

// Base directories for drone_engage modules
const std::string BASE_CAMERA_MODULE_PATH = "/home/pi/drone_engage/de_camera/";
const std::string BASE_TRACKER_MODULE_PATH = "/home/pi/drone_engage/de_tracking/";
const std::string BASE_AI_TRACKER_MODULE_PATH = "/home/pi/drone_engage/de_ai_tracker/";

// Module-specific paths
const std::string DE_CAMERA_MODULE = BASE_CAMERA_MODULE_PATH + "de_camera64.so";
const std::string DE_CAMERA_CONFIG = BASE_CAMERA_MODULE_PATH + "de_camera.config.module.json";
const std::string TRACKING_MODULE = BASE_TRACKER_MODULE_PATH + "de_tracker.so";
const std::string TRACKING_CONFIG = BASE_TRACKER_MODULE_PATH + "de_tracker.config.module.json";
const std::string AI_TRACKING_MODULE = BASE_AI_TRACKER_MODULE_PATH + "de_ai_tracker.so";
const std::string AI_TRACKING_CONFIG = BASE_AI_TRACKER_MODULE_PATH + "de_ai_tracker.config.module.json";

/**
 * @brief Executes a shell command and checks its exit code.
 * @param cmd The command string to execute.
 * @return True if the command executed successfully (exit code 0), false otherwise.
 */
bool executeCommand(const std::string &cmd)
{
    std::cout << "Executing: " << cmd << std::endl;
    int result = std::system(cmd.c_str());
    if (result != 0)
    {
        std::cerr << "Command failed with exit code " << result << ": " << cmd << std::endl;
        return false;
    }
    return true;
}

/**
 * @brief Forks a new process to start a script.
 * @param scriptPath The full path to the script to execute.
 * @return The process ID (PID) of the child process, -1 on failure, or 0 if the script fails to start.
 */
pid_t startScript(const std::string &scriptPath)
{
    pid_t pid = fork();
    if (pid == -1)
    {
        std::cerr << "Failed to fork for script: " << scriptPath << std::endl;
        return -1;
    }
    else if (pid == 0)
    {
        std::cout << "Executing script: " << scriptPath << std::endl;
        execlp("sh", "sh", "-c", scriptPath.c_str(), (char *)NULL);
        perror(("execlp for script " + scriptPath + " failed").c_str());
        return 0; // DONT EXIT IF ERROR
    }

    // Give the script a short time to start
    std::this_thread::sleep_for(std::chrono::milliseconds(500));

    // Check if the child process has exited (non-blocking)
    int status;
    pid_t result = waitpid(pid, &status, WNOHANG);
    if (result == -1)
    {
        std::cerr << "Failed to check script process status for: " << scriptPath << std::endl;
        return -1;
    }
    else if (result == pid)
    {
        // Child process exited
        if (WIFEXITED(status))
        {
            int exit_code = WEXITSTATUS(status);
            if (exit_code != 0)
            {
                std::cerr << "Script " << scriptPath << " failed with exit code " << exit_code << "." << std::endl;
                return 0; // Indicate script failed, but not a critical failure
            }
        }
        else
        {
            std::cerr << "Script " << scriptPath << " terminated abnormally." << std::endl;
            return -1;
        }
    }

    // Child process is still running
    std::cout << "Script " << scriptPath << " started with PID: " << pid << std::endl;
    return pid;
}

/**
 * @brief Forks a new process to start the rpicam-vid | ffmpeg pipeline.
 * @param postProcessFile Optional path to a post-processing file.
 * @return The process ID (PID) of the child process, -1 on failure, or 0 if no RPI camera is detected.
 */
pid_t startCameraPipeline(const std::string &postProcessFile)
{
    std::string cameraCmd = "/home/pi/scripts/sh_camera_run_rpi_camera.sh " ;
    if (!postProcessFile.empty())
    {
        cameraCmd += " \"" + postProcessFile + "\"";
    }

    pid_t pid = fork();
    if (pid == -1)
    {
        std::cerr << "Failed to fork for camera pipeline." << std::endl;
        return -1;
    }
    else if (pid == 0)
    {
        std::cout << "Calling sh_run_virtual_camera.sh with command: " << cameraCmd << std::endl;
        execlp("sh", "sh", "-c", cameraCmd.c_str(), (char *)NULL);
        perror("execlp for camera pipeline failed");
        _exit(127);
    }

    // Give the script a short time to perform camera detection
    std::this_thread::sleep_for(std::chrono::milliseconds(500));

    // Check if the child process has exited (non-blocking)
    int status;
    pid_t result = waitpid(pid, &status, WNOHANG);
    if (result == -1)
    {
        std::cerr << "Failed to check camera pipeline process status." << std::endl;
        return -1;
    }
    else if (result == pid)
    {
        // Child process exited
        if (WIFEXITED(status))
        {
            int exit_code = WEXITSTATUS(status);
            if (exit_code == 2)
            {
                std::cout << "No Raspberry Pi camera detected. Skipping camera pipeline." << std::endl;
                return 0; // Indicate no RPI camera, but not a failure
            }
            else if (exit_code != 0)
            {
                std::cerr << "Camera pipeline failed with exit code " << exit_code << "." << std::endl;
                return -1;
            }
        }
        else
        {
            std::cerr << "Camera pipeline terminated abnormally." << std::endl;
            return -1;
        }
    }

    // Child process is still running (successful pipeline start)
    std::cout << "Camera pipeline started with PID: " << pid << std::endl;
    return pid;
}

/**
 * @brief Forks a new process to start a module executable.
 * @param modulePath Path to the module executable.
 * @param moduleConfig Path to the module's configuration file.
 * @param moduleName Name of the module for logging.
 * @param workingDir Directory to change to before executing.
 * @return The process ID (PID) of the child process, or -1 on failure.
 */
pid_t startModule(const std::string &modulePath, const std::string &moduleConfig, const std::string &moduleName, const std::string &workingDir)
{
    pid_t pid = fork();
    if (pid == -1)
    {
        std::cerr << "Failed to fork for " << moduleName << "." << std::endl;
        return -1;
    }
    else if (pid == 0)
    {
        if (chdir(workingDir.c_str()) == -1)
        {
            perror(("chdir for " + moduleName + " failed").c_str());
            _exit(1);
        }
        execlp(modulePath.c_str(), moduleName.c_str(), "-c", moduleConfig.c_str(), (char *)NULL);
        perror(("execlp for " + moduleName + " failed").c_str());
        _exit(127);
    }
    std::cout << moduleName << " started with PID: " << pid << std::endl;
    return pid;
}

/**
 * @brief Gracefully stops all child processes, including scripts.
 */
void stopAllChildren()
{
    if (camera_pid > 0)
    {
        std::cout << "Stopping camera pipeline (PID " << camera_pid << ")..." << std::endl;
        kill(camera_pid, SIGTERM);
    }
    if (tracking_camera_pid > 0)
    {
        std::cout << "Stopping tracking module (PID " << tracking_camera_pid << ")..." << std::endl;
        kill(tracking_camera_pid, SIGTERM);
    }
    if (ai_tracking_camera_pid > 0)
    {
        std::cout << "Stopping ai tracking module (PID " << ai_tracking_camera_pid << ")..." << std::endl;
        kill(ai_tracking_camera_pid, SIGTERM);
    }
    if (de_camera_pid > 0)
    {
        std::cout << "Stopping de_camera module (PID " << de_camera_pid << ")..." << std::endl;
        kill(de_camera_pid, SIGTERM);
    }
    for (pid_t script_pid : script_pids)
    {
        if (script_pid > 0)
        {
            std::cout << "Stopping script (PID " << script_pid << ")..." << std::endl;
            kill(script_pid, SIGTERM);
        }
    }
}

/**
 * @brief Pre-emptively kills any running instances of child processes.
 */
void preemptiveKill()
{
    std::cout << "Pre-emptively killing any old 'rpicam-vid', 'de_tracker.so', and 'de_camera64.so' processes..." << std::endl;
    executeCommand("sudo /home/pi/scripts/sh_kill_all_camera_apps.sh");
    std::this_thread::sleep_for(std::chrono::seconds(2));
}

/**
 * @brief Signal handler for termination signals (SIGINT, SIGTERM).
 */
void signal_handler(int signal_num)
{
    std::cout << "Received signal " << signal_num << ". Shutting down." << std::endl;
    preemptiveKill();
    exit(0);
}

int main(int argc, char *argv[])
{
    // Command-line options
    bool enable_local_cam_capture = false;
    bool enable_tracker = false;
    bool enable_ai_tracker = false;
    bool enable_de_camera = true; // Enabled by default
    std::string postProcessFilePath;
    std::vector<std::string> scripts_to_execute; // To store script paths

    std::cout << "Camera Wrapper ver: " << VERSION_APP << std::endl;

    // Parse command-line options
    static struct option long_options[] = {
        {"enable-local-cam-capture", no_argument, 0, 'c'},
        {"enable-tracker", no_argument, 0, 't'},
        {"enable-ai-tracker", no_argument, 0, 'a'},
        {"disable-de-camera", no_argument, 0, 'd'},
        {"execute", required_argument, 0, 'e'},
        {"version", no_argument, 0, 'v'},
        {0, 0, 0, 0}};

    int opt;
    while ((opt = getopt_long(argc, argv, "ctade:v", long_options, nullptr)) != -1)
    {
        switch (opt)
        {
        case 'c':
            enable_local_cam_capture = true;
            break;
        case 't':
            enable_tracker = true;
            break;
        case 'a':
            enable_ai_tracker = true;
            break;
        case 'd':
            enable_de_camera = false;
            break;
        case 'e':
            if (optarg && optarg[0] != '\0') // Check for non-null and non-empty
                scripts_to_execute.push_back(optarg);
            else
            {
                std::cerr << "Error: No valid script path provided for --execute option." << std::endl;
                return 1;
            }
            break;
        case 'v':
            std::cout << "Version: " << VERSION_APP << std::endl;
            return 0;
        default:
            std::cerr << "Usage: " << argv[0] << " [--enable-local-cam-capture] [--enable-tracker] [--enable-ai-tracker] [--disable-de-camera] [--execute script_path] [postprocess_file_path]" << std::endl;
            std::cerr << "Example: " << argv[0] << " --enable-local-cam-capture --enable-tracker" << std::endl;
            std::cerr << "Example: " << argv[0] << " --enable-ai-tracker \"/usr/share/rpi-camera-assets/imx500_mobilenet_ssd.json\"" << std::endl;
            std::cerr << "Example: " << argv[0] << " --enable-local-cam-capture --execute /path/to/script.sh" << std::endl;
            return 1;
        }
    }

    // Parse optional postprocess_file_path
    if (optind < argc && argv[optind] != nullptr && argv[optind][0] != '\0')
    {
        postProcessFilePath = argv[optind];
    }

    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    // Step 1: Pre-emptive kill of old processes
    preemptiveKill();

    // Step 2: Always load v4l2loopback module
    if (!executeCommand("/home/pi/scripts/sh_camera_create_named_vc.sh"))
    {
        std::cerr << "Failed to load v4l2loopback module. Exiting." << std::endl;
        return 1;
    }
    executeCommand("ls /sys/devices/virtual/video4linux/");

    // Step 3: Start rpicam-vid | ffmpeg if enabled
    if (enable_local_cam_capture)
    {
        std::cout << "Starting camera pipeline..." << std::endl;
        camera_pid = startCameraPipeline(postProcessFilePath);
        if (camera_pid == -1)
        {
            std::cerr << "CRITICAL: Failed to start camera pipeline. Exiting." << std::endl;
            stopAllChildren();
            return 1;
        }
        else if (camera_pid == 0)
        {
            std::cout << "No Raspberry Pi camera detected, but continuing with other modules if enabled." << std::endl;
            camera_pid = -1; // Reset camera_pid to avoid stopping a non-existent process
        }
    }
    else
    {
        std::cout << "Skipping camera pipeline (not enabled)." << std::endl;
    }

    // Step 4: Start any specified scripts
    for (const auto &script : scripts_to_execute)
    {
        std::cout << "Starting script: " << script << "..." << std::endl;
        pid_t script_pid = startScript(script);
        if (script_pid == -1)
        {
            std::cerr << "CRITICAL: Failed to start script: " << script << ". Exiting." << std::endl;
            stopAllChildren();
            return 1;
        }
        else if (script_pid == 0)
        {
            std::cout << "Script " << script << " failed to start, but continuing with other modules if enabled." << std::endl;
        }
        else
        {
            script_pids.push_back(script_pid);
        }
    }

    // Step 5: Start tracking module (if enabled) after 15 seconds
    if (enable_tracker)
    {
        std::this_thread::sleep_for(std::chrono::seconds(15));
        std::cout << "Starting de_tracker.so..." << std::endl;
        tracking_camera_pid = startModule(TRACKING_MODULE, TRACKING_CONFIG, "de_tracker.so", BASE_TRACKER_MODULE_PATH);
        if (tracking_camera_pid == -1)
        {
            std::cerr << "CRITICAL: Failed to start de_tracker.so. Exiting." << std::endl;
            stopAllChildren();
            return 1;
        }
    }

    // Step 6: Start AI tracking module (if enabled) after 5 seconds
    if (enable_ai_tracker)
    {
        std::this_thread::sleep_for(std::chrono::seconds(5));
        std::cout << "Starting de_ai_tracker.so..." << std::endl;
        ai_tracking_camera_pid = startModule(AI_TRACKING_MODULE, AI_TRACKING_CONFIG, "de_ai_tracker.so", BASE_AI_TRACKER_MODULE_PATH);
        if (ai_tracking_camera_pid == -1)
        {
            std::cerr << "CRITICAL: Failed to start de_ai_tracker.so. Exiting." << std::endl;
            stopAllChildren();
            return 1;
        }
    }

    // Step 7: Start de_camera module (if enabled) after 15 seconds
    if (enable_de_camera)
    {
        std::this_thread::sleep_for(std::chrono::seconds(15));
        std::cout << "Starting de_camera64.so..." << std::endl;
        de_camera_pid = startModule(DE_CAMERA_MODULE, DE_CAMERA_CONFIG, "de_camera64.so", BASE_CAMERA_MODULE_PATH);
        if (de_camera_pid == -1)
        {
            std::cerr << "CRITICAL: Failed to start de_camera64.so. Exiting." << std::endl;
            stopAllChildren();
            return 1;
        }
    }
    else
    {
        std::cout << "SKIPPING de_camera64.so..." << std::endl;
    }

    // Main monitoring loop: Wait for any child process to crash
    while (true)
    {
        int status;
        pid_t exited_pid = waitpid(-1, &status, 0);
        if (exited_pid > 0)
        {
            std::string exit_reason;
            if (WIFEXITED(status))
            {
                exit_reason = "exited with status " + std::to_string(WEXITSTATUS(status));
            }
            else if (WIFSIGNALED(status))
            {
                exit_reason = "terminated by signal " + std::to_string(WTERMSIG(status));
            }
            else
            {
                exit_reason = "exited for unknown reason";
            }
            std::cerr << "Child process (PID " << exited_pid << ") " << exit_reason << ". Crashing wrapper to force a full systemctl restart." << std::endl;
            preemptiveKill();
            return 1;
        }
    }

    return 0;
}