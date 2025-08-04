//***************************************************************************** */
//  Wrapper to run Camera & Related Software
//
//  Auth: Mohammad S. Hefny
//  Date: Aug 2025
//
//***************************************************************************** */

//g++ camera_manager_wrapper.cpp -o camera_manager_wrapper -pthread
#include <iostream>     // For standard input/output operations (cout, cerr)
#include <string>       // For using the std::string class
#include <cstdlib>      // For system() to execute shell commands, and exit() to terminate the program
#include <thread>       // For std::this_thread::sleep_for to pause execution
#include <chrono>       // For std::chrono::seconds to specify sleep duration
#include <vector>       // For using dynamic arrays (not used in this final version, but often useful)
#include <sys/types.h>  // For pid_t data type
#include <sys/wait.h>   // For waitpid() to monitor child processes
#include <unistd.h>     // For fork(), execlp(), kill()
#include <csignal>      // For SIGTERM and SIGINT signal handling

// Global PID variables to track the process IDs of our child processes.
// Initialized to -1 to indicate that no process is currently running.
pid_t camera_pid = -1;
pid_t de_camera_pid = -1;

/**
 * @brief Executes a shell command and checks its exit code.
 * @param cmd The command string to execute.
 * @return True if the command executed successfully (exit code 0), false otherwise.
 */
bool executeCommand(const std::string& cmd) {
    std::cout << "Executing: " << cmd << std::endl;
    // std::system() returns the exit status of the command.
    int result = std::system(cmd.c_str());
    if (result != 0) {
        std::cerr << "Command failed with exit code " << result << ": " << cmd << std::endl;
        return false;
    }
    return true;
}

/**
 * @brief Forks a new process to start the rpicam-vid | ffmpeg pipeline.
 *
 * This function uses `fork()` to create a child process. The child process then
 * uses `execlp()` to execute the shell command `sh -c "..."`, which is
 * necessary to correctly handle the pipe (`|`) between the two programs.
 * The parent process returns the child's PID.
 *
 * @return The process ID (PID) of the child process, or -1 on failure.
 */
pid_t startCameraPipeline() {
    // The command string for the camera pipeline.
    const std::string cameraCmd = "/home/pi/scripts/sh_camera_run_on_vc.sh 1";

    pid_t pid = fork();
    if (pid == -1) {
        // Forking failed, so we can't start the process.
        std::cerr << "Failed to fork for camera pipeline." << std::endl;
        return -1;
    } else if (pid == 0) {
        // This is the child process. It replaces itself with the new program.
        // execlp(path, arg0, arg1, ..., NULL)
        // Here, we run "sh" with the "-c" flag to execute our complex command string.
        execlp("sh", "sh", "-c", cameraCmd.c_str(), (char *)NULL);
        
        // If execlp returns, an error has occurred.
        perror("execlp for camera pipeline failed");
        _exit(127); // Exit the child process with a non-zero status.
    }
    // This is the parent process. It returns the PID of the child.
    std::cout << "Camera pipeline started with PID: " << pid << std::endl;
    return pid;
}


/**
 * @brief Forks a new process to start the de_camera64.so executable.
 * @return The process ID (PID) of the child process, or -1 on failure.
 */
pid_t startDeCamera() {
    // Path to the de_camera executable and its configuration file.
    const std::string deCameraPath = "/home/pi/drone_engage/de_camera/de_camera64.so";
    const std::string deCameraConfig = "/home/pi/drone_engage/de_camera/de_camera.config.module.json";
    
    pid_t pid = fork();
    if (pid == -1) {
        // Forking failed.
        std::cerr << "Failed to fork for de_camera64.so." << std::endl;
        return -1;
    } else if (pid == 0) {

        // Change the current working directory for the child process
        if (chdir("/home/pi/drone_engage/de_camera/") == -1) {
            perror("chdir for de_camera64.so failed");
            _exit(1); // Exit if we can't change directory
        }

        // This is the child process.
        // execlp(path, arg0, arg1, arg2, ..., NULL)
        // arg0 is conventionally the program's name.
        execlp(deCameraPath.c_str(), "de_camera64.so", "-c", deCameraConfig.c_str(), (char *)NULL);
        
        // If execlp returns, an error has occurred.
        perror("execlp for de_camera64.so failed");
        _exit(127); // Exit the child process with a non-zero status.
    }
    // This is the parent process.
    std::cout << "de_camera64.so started with PID: " << pid << std::endl;
    return pid;
}

/**
 * @brief Gracefully stops all child processes (camera and de_camera).
 *
 * This function sends a SIGTERM signal to any running child process. It does
 * not wait for them to terminate, allowing the parent process to exit
 * without blocking. This is crucial for a responsive shutdown.
 */
void stopAllChildren() {
    if (camera_pid > 0) {
        std::cout << "Stopping camera pipeline (PID " << camera_pid << ")..." << std::endl;
        kill(camera_pid, SIGTERM);
        // We do not call waitpid here to avoid blocking on the child's cleanup.
    }
    if (de_camera_pid > 0) {
        std::cout << "Stopping de_camera64.so (PID " << de_camera_pid << ")..." << std::endl;
        kill(de_camera_pid, SIGTERM);
        // We do not call waitpid here to avoid blocking on the child's cleanup.
    }
}

/**
 * @brief Pre-emptively kills any running instances of the child processes.
 *
 * This function uses the `pkill` command to forcefully terminate any processes
 * named 'rpicam-vid' or 'de_camera64.so'. This is a safety measure to ensure
 * a clean startup even if the previous run left orphaned processes.
 */
void preemptiveKill() {
    std::cout << "Pre-emptively killing any old 'rpicam-vid' and 'de_camera64.so' processes..." << std::endl;
    // The -9 flag sends SIGKILL, which cannot be ignored by the process.
    executeCommand("sudo pkill -9 rpicam-vid");
    executeCommand("sudo pkill -9 de_camera64.so");
    // Wait a moment for the system to clean up the terminated processes.
    std::this_thread::sleep_for(std::chrono::seconds(2));
}

/**
 * @brief Signal handler function for termination signals (SIGINT, SIGTERM).
 *
 * This function ensures that if the wrapper is killed (e.g., by systemctl),
 * it first gracefully shuts down its child processes before exiting itself.
 */
void signal_handler(int signal_num) {
    std::cout << "Received signal " << signal_num << ". Shutting down." << std::endl;
    // stopAllChildren();
    preemptiveKill(); // more reliable.
    // After sending the termination signals, we exit immediately. The OS will
    // handle the final cleanup of the child processes.
    exit(0);
}

int main() {
    // Register signal handlers. This ensures our `stopAllChildren()` function
    // is called when the program receives a SIGINT (e.g., Ctrl+C) or SIGTERM
    // (e.g., from `systemctl stop`).
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    // --- Step 1: Pre-emptive kill of old processes ---
    // This ensures a clean slate before starting the new processes.
    preemptiveKill();

    // --- Step 2: Load v4l2loopback module (runs once) ---
    // This command creates the virtual video devices needed by the pipeline.
    if (!executeCommand("/home/pi/scripts/sh_camera_create_named_vc.sh")) {
        std::cerr << "Failed to load v4l2loopback module. Exiting." << std::endl;
        return 1;
    }
    executeCommand("ls /sys/devices/virtual/video4linux/"); // For verification

    
    // --- Step 3: Start rpicam-vid | ffmpeg ---
    std::cout << "Starting camera pipeline..." << std::endl;
    camera_pid = startCameraPipeline();
    if (camera_pid == -1) {
        std::cerr << "CRITICAL: Failed to start camera pipeline. Exiting." << std::endl;
        stopAllChildren(); // Clean up any children if necessary
        return 1;
    }

    // --- Step 4: Wait 10 seconds and then start de_camera64.so ---
    std::this_thread::sleep_for(std::chrono::seconds(20));
    std::cout << "Starting de_camera64.so..." << std::endl;
    de_camera_pid = startDeCamera();
    if (de_camera_pid == -1) {
        std::cerr << "CRITICAL: Failed to start de_camera64.so. Exiting." << std::endl;
        stopAllChildren(); // Clean up the camera pipeline before exiting
        return 1;
    }

    // --- Main monitoring loop: Wait for any child process to crash ---
    // This loop blocks until one of the child processes exits.
    while (true) {
        int status;
        pid_t exited_pid = waitpid(-1, &status, 0); // Blocking wait for any child

        // If a child process exited for any reason, print the reason and exit
        if (exited_pid > 0) {
            std::string exit_reason;
            if (WIFEXITED(status)) {
                // The child exited normally.
                exit_reason = "exited with status " + std::to_string(WEXITSTATUS(status));
            } else if (WIFSIGNALED(status)) {
                // The child was terminated by a signal (e.g., a crash).
                exit_reason = "terminated by signal " + std::to_string(WTERMSIG(status));
            } else {
                exit_reason = "exited for unknown reason";
            }
            std::cerr << "Child process (PID " << exited_pid << ") " << exit_reason << ". Crashing wrapper to force a full systemctl restart." << std::endl;
            
            // This is the critical part of the logic:
            // Since one child crashed, we explicitly kill the other one to ensure
            // both are down before the wrapper exits. This provides a clean slate
            // for the systemctl service to restart everything.
            stopAllChildren();
            
            // We return with a non-zero status code, which signals to systemctl
            // that the service failed and needs to be restarted.
            return 1;
        }
    }

    return 0; // This line should not be reached in normal operation.
}
