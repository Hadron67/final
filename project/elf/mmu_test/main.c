#include "io.h"
static int printString(const char *s){
    while(*s){
        *((int *)0xa0000001) = *s++;
    }
    return 0;
}
int main(){
    int i, j;
    for(i = 0; i < 10; i++){
        for(j = 0; j < 5; j++)
            printString("hkm, soor |");
        printString("\n");
    }
    return 0;
}