#include <iostream>
#include <filesystem>
#include <fcntl.h>  // For open()
#include <unistd.h> // For lseek(), close()

using namespace std;
namespace fs = std::filesystem;

void listFiles(char folderPath[256]) {
    for (const auto& entry : fs::directory_iterator(folderPath)) {
        if (entry.is_regular_file()) {
            string filePath = entry.path();
            
            // Open the file to get its descriptor
            int fileDescriptor = open(filePath.c_str(), O_RDONLY);
            // Use lseek to find the size of the file
            off_t fileSize = lseek(fileDescriptor, 0, SEEK_END);

            cout << "File Descriptor: " << fileDescriptor << endl;
            cout << "File Size: " << ((fileSize + 1023) >> 10) << " kilobytes" << endl << endl;
        }
    }
}

int main() {
    char path[256];
    cin >> path;
    listFiles(path);
    return 0;
}