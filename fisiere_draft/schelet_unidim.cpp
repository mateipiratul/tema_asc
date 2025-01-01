#include <iostream>
#include <fstream>
using namespace std;

ifstream i("input_uni");
ofstream o("output_uni");

int v[1000] = {0};

void afisare(int v[1000])
{
    for (int i=0;i < 1000; i++) {
        if(i%20 == 0) o<<'\n';
        o<<v[i]<<' ';
    }
}

pair<int, int> ADD(int id, int sizeKB) {
    int blocksNeeded = sizeKB / 8 + (sizeKB % 8 != 0 ? 1 : 0);
    for (int start = 0; start < 1001 - blocksNeeded; start++) {
        bool canAllocate = true;
        for (int j = 0; j < blocksNeeded; j++) {
            if (v[start + j] != 0) {
                canAllocate = false;
                break;
            }
        }

        if (canAllocate) {
            for (int j = 0; j < blocksNeeded; j++) {
                v[start + j] = id;
            }
            return {start, start + blocksNeeded - 1};
        }
    }
    return {0, 0};
}

pair<int, int> GET(int id) {
    int start = -1, ending = -1;

    for (int idx = 0; idx < 1000; idx++) {
        if (v[idx] == id) {
            if (start == -1) start = idx;
            ending = idx;
        }
    }

    if (start == -1) return {0, 0};
    return {start, ending};
}

void DELETE(int id) {
    for (int idx = 0; idx < 1000; idx++) {
        if (v[idx] == id) {
            v[idx] = 0;
        }
    }

    for (int idx = 0; idx < 1000; idx++) {
        if (v[idx] != 0) {
            int fileId = v[idx], start = idx;
            while (idx < 1000 && v[idx] == fileId) idx++;
            int ending = --idx;
            o << fileId << ": (" << start << ", " << ending << ")\n";
        }
    }
}

void DEFRAGMENTATION() {
    int currentIndex = 0;
    for (int i = 0; i < 1000; i++)
        if (v[i]) {
            v[currentIndex] = v[i];
            if (currentIndex != i) v[i] = 0;
            currentIndex++;
        }

    for (int i = 1; i < currentIndex; i++) {
        int start = i-1, fileId = v[i];
        while (i < currentIndex && v[i] == fileId) i++;
        int ending = i - 1;
        o << fileId << ": (" << start << ", " << ending << ")\n";
    }
}

int main() {
    int O;
    i >> O;

    for (int op = 0; op < O; op++) {
        int operation;
        i >> operation;

        if (operation == 1) {
            int N;
            i >> N;

            for (int file = 0; file < N; file++) {
                int id, sizeKB;
                i >> id >> sizeKB;
                pair<int, int> result = ADD(id, sizeKB);
                o << id << ": (" << result.first << ", " << result.second << ")\n";
            }
            o << '\n';
        } else if (operation == 2) {
            int id;
            i >> id;
            pair<int, int> result = GET(id);
            o << "(" << result.first << ", " << result.second << ")\n";
            o << '\n';
        } else if (operation == 3) {
            int id;
            i >> id;
            DELETE(id);
            o << '\n';
        } else if (operation == 4) {
            DEFRAGMENTATION();
            o << '\n';
        }
    }
    i.close();
    o.close();
    return 0;
}
