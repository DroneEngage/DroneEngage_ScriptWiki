//g++ -o updateConfig updateConfig.cpp -std=c++17 -lstdc++fs

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <regex>
#include <sys/file.h> // For file locking (flock)
#include <unistd.h>   // For close
#include <filesystem> // For backup and disk space checks
#include <ctime>

// Function to create a backup of the file
bool createBackup(const std::string& file_path) {
    std::string backup_path = file_path + ".bak." + std::to_string(std::time(nullptr));
    try {
        std::filesystem::copy_file(file_path, backup_path, std::filesystem::copy_options::overwrite_existing);
        std::cout << "Backup created: " << backup_path << std::endl;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Warning: Failed to create backup for " << file_path << ": " << e.what() << std::endl;
        return false;
    }
}

// Function to check available disk space
bool checkDiskSpace(const std::string& file_path) {
    try {
        auto space = std::filesystem::space(std::filesystem::path(file_path).parent_path());
        if (space.available < 1024 * 1024) { // Require at least 1MB free
            std::cerr << "Error: Insufficient disk space for " << file_path << std::endl;
            return false;
        }
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Warning: Failed to check disk space for " << file_path << ": " << e.what() << std::endl;
        return true; // Proceed cautiously
    }
}

// Function to update a single config file using text replacement
bool updateConfigFile(const std::string& file_path, const std::string& username, const std::string& access_code, const std::string& server) {
    // Check disk space
    if (!checkDiskSpace(file_path)) {
        return false;
    }

    // Open file with locking
    int fd = open(file_path.c_str(), O_RDWR);
    if (fd == -1) {
        std::cerr << "Error: Failed to open config file: " << file_path << std::endl;
        return false;
    }

    // Acquire file lock
    if (flock(fd, LOCK_EX) == -1) {
        std::cerr << "Error: Failed to lock file: " << file_path << std::endl;
        close(fd);
        return false;
    }

    // Read the config file
    std::ifstream ifs(file_path);
    if (!ifs.is_open()) {
        std::cerr << "Error: Failed to open config file for reading: " << file_path << std::endl;
        flock(fd, LOCK_UN);
        close(fd);
        return false;
    }

    std::stringstream ss;
    ss << ifs.rdbuf();
    std::string content = ss.str();
    ifs.close();

    // Create a backup
    if (!createBackup(file_path)) {
        std::cerr << "Warning: Proceeding without backup for " << file_path << std::endl;
    }

    // Declare updated flag
    bool updated = false;

    // Prepare regex patterns for userName, accessCode, and auth_ip
    // Matches: "userName": "value" or "userName" : "value" (with optional whitespace)
    std::regex username_pattern("\"userName\"\\s*:\\s*\"([^\"]*)\"");
    std::regex accesscode_pattern("\"accessCode\"\\s*:\\s*\"([^\"]*)\"");
    std::regex authip_pattern("\"auth_ip\"\\s*:\\s*\"([^\"]*)\"");

    std::string current_content = content;

    // Replace userName only if username is not empty
    if (!username.empty()) {
        if (std::regex_search(current_content, username_pattern)) {
            std::string new_content = std::regex_replace(
                current_content,
                username_pattern,
                "\"userName\": \"" + username + "\""
            );
            if (new_content != current_content) {
                std::cout << "Updated 'userName' to '" << username << "' in " << file_path << std::endl;
            } else {
                std::cout << "'userName' already set to '" << username << "' in " << file_path << std::endl;
            }
            updated = true;
            current_content = new_content;
        } else {
            std::cerr << "Warning: 'userName' field not found in " << file_path << std::endl;
        }
    }

    // Replace accessCode only if access_code is not empty
    if (!access_code.empty()) {
        if (std::regex_search(current_content, accesscode_pattern)) {
            std::string new_content = std::regex_replace(
                current_content,
                accesscode_pattern,
                "\"accessCode\": \"" + access_code + "\""
            );
            if (new_content != current_content) {
                std::cout << "Updated 'accessCode' in " << file_path << std::endl;
            } else {
                std::cout << "'accessCode' already set in " << file_path << std::endl;
            }
            updated = true;
            current_content = new_content;
        } else {
            std::cerr << "Warning: 'accessCode' field not found in " << file_path << std::endl;
        }
    }

    // Replace auth_ip only if server is not empty
    if (!server.empty()) {
        if (std::regex_search(current_content, authip_pattern)) {
            std::string new_content = std::regex_replace(
                current_content,
                authip_pattern,
                "\"auth_ip\": \"" + server + "\""
            );
            if (new_content != current_content) {
                std::cout << "Updated 'auth_ip' to '" << server << "' in " << file_path << std::endl;
            } else {
                std::cout << "'auth_ip' already set to '" << server << "' in " << file_path << std::endl;
            }
            updated = true;
            current_content = new_content;
        } else {
            std::cerr << "Warning: 'auth_ip' field not found in " << file_path << std::endl;
        }
    }

    std::string final_content = current_content;

    if (!updated) {
        std::cerr << "Warning: No fields were updated in " << file_path << " (no parameters provided)" << std::endl;
    }

    // Write to a temporary file
    std::string temp_path = file_path + ".tmp";
    std::ofstream ofs(temp_path);
    if (!ofs.is_open()) {
        std::cerr << "Error: Failed to open temporary file for writing: " << temp_path << std::endl;
        flock(fd, LOCK_UN);
        close(fd);
        return false;
    }

    ofs << final_content;
    ofs.close();

    // Atomically rename temporary file to original
    try {
        std::filesystem::rename(temp_path, file_path);
    } catch (const std::exception& e) {
        std::cerr << "Error: Failed to rename temporary file to " << file_path << ": " << e.what() << std::endl;
        flock(fd, LOCK_UN);
        close(fd);
        return false;
    }

    // Release file lock
    flock(fd, LOCK_UN);
    close(fd);

    std::cout << "Config file updated successfully: " << file_path << std::endl;
    return true;
}

int main(int argc, char** argv) {
    // Check for at least username, access_code, server, and one file path
    if (argc < 5) {
        std::cerr << "Usage: " << argv[0] << " <username> <access_code> <server> <config_file_path> [<config_file_path> ...]" << std::endl;
        return 1;
    }

    std::string username = argv[1];
    std::string access_code = argv[2];
    std::string server = argv[3];

    // Process each file path starting from argv[4]
    bool all_success = true;
    for (int i = 4; i < argc; ++i) {
        std::string file_path = argv[i];
        if (!updateConfigFile(file_path, username, access_code, server)) {
            all_success = false;
        }
    }

    if (all_success) {
        std::cout << "All config files processed successfully." << std::endl;
        return 0;
    } else {
        std::cerr << "Some config files failed to process." << std::endl;
        return 1;
    }
}

