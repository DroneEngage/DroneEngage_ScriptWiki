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

    // Replace userName
    std::string new_content = std::regex_replace(
        content,
        username_pattern,
        "\"userName\": \"" + username + "\""
    );
    if (new_content != content) {
        updated = true;
        std::cout << "Updated 'userName' to '" << username << "' in " << file_path << std::endl;
    }

    // Replace accessCode
    std::string accesscode_content = std::regex_replace(
        new_content,
        accesscode_pattern,
        "\"accessCode\": \"" + access_code + "\""
    );
    if (accesscode_content != new_content) {
        updated = true;
        std::cout << "Updated 'accessCode' to '" << access_code << "' in " << file_path << std::endl;
    }

    // Optionally replace auth_ip if server parameter is not empty
    std::string final_content = accesscode_content;
    if (!server.empty()) {
        std::string authip_content = std::regex_replace(
            accesscode_content,
            authip_pattern,
            "\"auth_ip\": \"" + server + "\""
        );
        if (authip_content != accesscode_content) {
            updated = true;
            std::cout << "Updated 'auth_ip' to '" << server << "' in " << file_path << std::endl;
        }
        final_content = authip_content;
    }

    if (!updated) {
        std::cerr << "Warning: No 'userName' or 'accessCode' fields found in " << file_path << std::endl;
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

