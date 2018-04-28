#include "mipsreg.h"
#include "kernel.h"
typedef struct _PageTableEntry {
    unsigned int entryHi;
    unsigned int entryLo0;
    unsigned int entryLo1;
    unsigned int pageMask;
} PageTableEntry;

typedef struct _Process {
    PageTableEntry *pt;
} Process;

static GlobalTable gt;
GlobalTable *globalTable = &gt;

static void initTlb(){
    register unsigned int i = 0;
    MTC0(i, C0_ENTRYLO0);
    MTC0(i, C0_ENTRYLO1);
    MTC0(i, C0_PAGEMASK);
    for(i = 0; i < TLB_ENTRY_COUNT; i++){
        MTC0(i << 13, C0_ENTRYHI);
        MTC0(i, C0_INDEX);
        TLBWI();
    }
}
static int printString(const char *s){
    while(*s){
        *((int *)0xa0000001) = *s++;
    }
    return 0;
}
void handler_tlbMod(){

}
void handler_tlbLoad(){

}
void handler_tlbStore(){

}

void initKernel(){
    initTlb();
    printString("TLB initialized\n");
}