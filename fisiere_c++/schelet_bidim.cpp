#include <iostream>
#include <fstream>
using namespace std;
ifstream i("input_bi");

int a[8][8] = {0};

void matrice() {
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++)
            cout << a[i][j] << ' ';
        cout << '\n';
    }
}

void AFIS() { /// complet
    int indX, startY, endY, fileID;
    for (int i = 0; i < 8; i++) {
        int j = 0;
        while (j < 8)
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
    if (blocksNeeded > 8)
    {
        startX = 0, endX = 0, startY = 0, endY = 0;
        return;
    }
    else
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 9 - blocksNeeded; j++) {
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
                return;
            }
        }
    }
    startX = 0, endX = 0, startY = 0, endY = 0;
}

void GET(int id) { /// complet
    int startX = 0, startY = 0, endX = 0, endY = 0, ok = 0;
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
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
    for (int i = 0; i < 8; i++) {
            int j = 0;
        while (a[i][j] != id && j < 8)
            j++;
        if (a[i][j] == id) {
            while (a[i][j] == id)
                a[i][j++] = 0;
        }
    }
}

void DEFRAG() { /// de verificat
    for (int i = 0; i < 8; i++) {
        int currentIndex = 0;
        for (int j = 0; j < 8; j++) {
            if (a[i][j] != 0) {
                if (j != currentIndex) {
                    a[i][currentIndex] = a[i][j];
                    a[i][j] = 0;
                }
                currentIndex++;
            }
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
                printf("%d: ((%d, %d), (%d, %d))\n", id, startX, startY, endX, endY);
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
        }
    }
    matrice();
    i.close();
    return 0;
}
