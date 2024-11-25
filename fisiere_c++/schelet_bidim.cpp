#include <iostream>
#include <fstream>
using namespace std;

ifstream i("input_bi");
ofstream o("output_bi");

pair<int, int> ADD(int id, int sizeKB) {
    int blocksNeeded = sizeKB / 8 + (sizeKB % 8 != 0 ? 1 : 0);

    for (int row = 0; row < 8; row++) {
        int consecutiveFree = 0;
        int startCol = -1;

        for (int col = 0; col < 8; col++) {
            if (a[row][col] == 0) {
                if (startCol == -1) startCol = col;
                consecutiveFree++;

                if (consecutiveFree == blocksNeeded) {
                    for (int k = 0; k < blocksNeeded; k++) {
                        a[row][startCol + k] = id;
                    }
                    return {row * 8 + startCol, row * 8 + startCol + blocksNeeded - 1};
                }
            } else {
                consecutiveFree = 0;
                startCol = -1;
            }
        }
    }
    return {0, 0};
}

int main() {
    
    return 0;
}