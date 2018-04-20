static int printString(const char *s){
    while(*s){
        *((int *)0xa0000001) = *s++;
    }
}
static int printInt(int i){
    
}

int main(){
    int i;
    printString("****************************\n");
    for(i = 0; i < 10; i++){
        printString("hkm, soor\n");
    }
    return 0;
}