#include <iostream>
#include <fstream>
#include <filesystem>
#include <fcntl.h>  // For open()
#include <unistd.h> // For lseek(), close()
using namespace std;
namespace fs = std::filesystem;
ifstream i("input_concrete");

int a[1000][1000] = {0};

void AFIS() { /// complet
    int indX, startY, endY, fileID;
    for (int i = 0; i < 1000; i++) {
        int j = 0;
        while (j < 1000)
            if (a[i][j]) {
                indX = i, startY = j, fileID = a[i][j];
                while (a[i][j] == fileID) j++;
                endY = j - 1;
                printf("%d: ((%d, %d), (%d, %d))\n", fileID, indX, startY, indX, endY);
            }
            else j++;
    }
}

void ADD(int id, int sizeKB, int &startX, int &startY, int &endX, int &endY) {
    /// implementare dummy -> eficienta scazuta, fara memorarea lui i/j/k,
    /// omiterea liniilor pline
    int blocksNeeded = (sizeKB + 7) >> 3;
    if (blocksNeeded > 1000)
    {
        startX = 0, endX = 0, startY = 0, endY = 0;
        printf("%d: ((%d, %d), (%d, %d))\n", id, startX, startY, endX, endY);
        return;
    }
    else
    for (int i = 0; i < 1000; i++) {
        for (int j = 0; j < 1001 - blocksNeeded; j++) {
                bool canAlloc = true;
            for (int k = 0; k < blocksNeeded; k++)
                if (a[i][j+k]) {
                    canAlloc = false;
                    break;
                }
            if (canAlloc) {
                for (int k = 0; k < blocksNeeded; k++)
                    a[i][j+k] = id;
                startX = i, endX = i;
                startY = j, endY = j + blocksNeeded - 1;
                printf("%d: ((%d, %d), (%d, %d))\n", id, startX, startY, endX, endY);
                return;
            }
        }
    }
    startX = 0, endX = 0, startY = 0, endY = 0;
}

void GET(int id) { /// complet
    int startX = 0, startY = 0, endX = 0, endY = 0, ok = 0;
    for (int i = 0; i < 1000; i++) {
        for (int j = 0; j < 1000; j++) {
            if (a[i][j] == id) {
                if (!ok) {
                    startX = i;
                    startY = j;
                    ok = 1;
                }
                endX = i;
                endY = j;
            }
        }
        if (ok) break;
    }
    if (ok) {
        printf("((%d, %d), (%d, %d))\n", startX, startY, endX, endY);
    }
}

void DEL(int id) {
    for (int i = 0; i < 1000; i++) {
            int j = 0;
        while (a[i][j] != id && j < 1000)
            j++;
        if (a[i][j] == id) {
            while (a[i][j] == id)
                a[i][j++] = 0;
        }
    }
}
void ADD_DEFRAG(int id, int sizeBlocks, int &row, int &col) {
    while (row < 1000) {
        if (col + sizeBlocks <= 1000) {
            bool canAlloc = true;
            for (int k = 0; k < sizeBlocks; k++) {
                if (a[row][col + k]) {
                    canAlloc = false;
                    break;
                }
            }
            if (canAlloc) {
                for (int k = 0; k < sizeBlocks; k++)
                    a[row][col + k] = id;
                col += sizeBlocks;
                return;
            }
        }
        row++;
        col = 0;
    }
}

void DEFRAG() {
    int row = 0, col = 0;
    for (int i = 0; i < 1000; i++)
        for (int j = 0; j < 1000; j++)
            if (a[i][j]) {
                int fileID = a[i][j], fileSize = 0;
                while (j < 1000 && a[i][j] == fileID)
                    fileSize++, j++;
                j--;
                DEL(fileID);
                ADD_DEFRAG(fileID, fileSize, row, col);
            }
}

void CONCRETE (char folderPath[256]) {
    for (const auto& entry : fs::directory_iterator(folderPath)) {
        if (entry.is_regular_file()) {
            string filePath = entry.path();
            int fileDescriptor = open(filePath.c_str(), O_RDONLY);
            off_t fileSize = lseek(fileDescriptor, 0, SEEK_END);
            int startX, startY, endX, endY;
            fileSize += 1023, fileSize >>= 10;
            int fd = fileDescriptor % 255 + 1;
            ADD(fd, fileSize, startX, startY, endX, endY);
        }
    }
}

int main()
{
    int O;
    i >> O;

    for (int op = 0; op < O; op++) {
        int operation;
        i >> operation;

        if (operation == 1) {
            int N;
            i >> N;

            for (int file = 0; file < N; file++) {
                int id, sizeKB, startX, startY, endX, endY;
                i >> id >> sizeKB;
                ADD(id, sizeKB, startX, startY, endX, endY);
            }
            printf("\n");
        } else if (operation == 2) {
            int id;
            i >> id;
            GET(id);
            printf("\n");
        } else if (operation == 3) {
            int id;
            i >> id;
            DEL(id);
            AFIS();
            printf("\n");
        } else if (operation == 4) {
            DEFRAG();
            AFIS();
            printf("\n");
        } else if (operation == 5) {
            char path[256];
            i >> path;
            CONCRETE(path);
        }
    }
    i.close();
    return 0;
}