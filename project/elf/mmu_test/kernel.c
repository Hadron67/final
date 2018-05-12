// Lie group is a group which is also a manifold.
#include "mipsreg.h"
#include "kernel.h"

#define PAGE_TABLE_SIZE 64
#define IS_VALID(entry) ((entry)->entryLo0 & 2)
#define GET_PN(addr) ((addr) & 0xffffe000)

typedef struct _PageTableEntry {
    uint32_t entryHi;
    uint32_t entryLo0;
    uint32_t entryLo1;
    uint32_t pageMask;
} PageTableEntry;

typedef struct _PageTable {
    PageTableEntry entries[PAGE_TABLE_SIZE];
} PageTable;

typedef struct _Process {
    PageTable *pt;
    uint8_t asid;
} Process;

GlobalTable globalTable;

static void PageTable_init(PageTable *t){
    int i;
    for(i = 0; i < PAGE_TABLE_SIZE; i++){
        PageTableEntry *e = t->entries + i;
        e->entryHi = 0;
        e->entryLo0 = 0;
        e->entryLo1 = 0;
        e->pageMask = 0;
    }
}

static void PageTable_writeEntry(PageTable *table, uint32_t vpn2, uint8_t asid, uint32_t mask, uint32_t fpn, int even){
    PageTableEntry *entry = table->entries + vpn2;
    entry->entryHi = (vpn2 << 13) | (asid & 0xff);
    entry->pageMask = mask << 13;
    uint32_t entryLo = (fpn << 6) | 2 | (asid == 0);
    if(even){
        entry->entryLo0 = entryLo;
    }
    else {
        entry->entryLo1 = entryLo;
    }
}
static void writeTlb(uint32_t i, uint32_t vpn2, uint8_t asid, uint32_t mask, uint32_t fpn, int even){
    MTC0(i, C0_INDEX);
    MTC0((vpn2 << 13) | (asid & 0xff), C0_ENTRYHI);
    MTC0(mask << 13, C0_PAGEMASK);
    uint32_t entryLo = (fpn << 6) | 2 | (asid == 0);
    if(even){
        MTC0(entryLo, C0_ENTRYLO0);
        MTC0(0, C0_ENTRYLO1);
    }
    else {
        MTC0(0, C0_ENTRYLO0);
        MTC0(entryLo, C0_ENTRYLO1);
    }
    TLBWI();
}

static int printString(const char *s){
    while(*s){
        *((int *)0xa0000001) = *s++;
    }
    return 0;
}

static void err(const char *s){
    printString(s);
    *((int *)0xa0000000) = 0;
}
static void initTlb(){
    register uint32_t i = 0;
    MTC0(i, C0_ENTRYLO0);
    MTC0(i, C0_ENTRYLO1);
    MTC0(i, C0_PAGEMASK);
    for(i = 0; i < TLB_ENTRY_COUNT; i++){
        MTC0(i << 13, C0_ENTRYHI);
        MTC0(i, C0_INDEX);
        TLBWI();
    }
}

static void do_pageFault(){
    *((int *)0xa0000000) = 0;
}
static int ensureTlbEntry(){
    
}
static void do_tlbRefill(int isStore){
    uint32_t ctx;
    MFC0(ctx, C0_CONTEXT);
    uint32_t badvpn2 = (ctx >> 4) & 0x7ffff;
    PageTableEntry *entry = (PageTableEntry *)ctx;
    if(badvpn2 >= PAGE_TABLE_SIZE){
        err("illegal address: out of range\n");
    }
    else if(IS_VALID(entry)){
        printString("entry is valid, fetching table entry from memory\n");
        MTC0(entry->entryHi, C0_ENTRYHI);
        MTC0(entry->entryLo0, C0_ENTRYLO0);
        MTC0(entry->entryLo1, C0_ENTRYLO1);
        MTC0(entry->pageMask, C0_PAGEMASK);
        TLBWR();
    }
    else {
        printString("invalid entry, do page fault\n");
        do_pageFault();
    }
}

void handler_tlbMod(){

}
void handler_tlbLoad(){
    do_tlbRefill(0);
}
void handler_tlbStore(){
    do_tlbRefill(1);
}

static PageTable testTable AT_FRAME("1");
static const char testString[] AT_FRAME("2");
static const char testString[] = "hkm, soor\n";
extern uint32_t __frame1_start;
extern uint32_t __frame2_start;

#define PTABLE_ADDR (0x800 << 13)

static void runTest(){
    const char *testAddr = (const char *)(0x2 << 13);
    PageTable *table = (PageTable *)(0x0);
    // map VPN2 PTABLE_ADDR to frame1, and 0x2 to frame2
    writeTlb(0, 0x0, 1, 0, (uint32_t)&__frame1_start >> 12, 1);

    PageTable_init(table);
    PageTable_writeEntry(table, 0x0, 1, 0, (uint32_t)&__frame1_start >> 12, 1);
    PageTable_writeEntry(table, 0x2, 1, 0, (uint32_t)&__frame2_start >> 12, 1);
    MTC0(0x0, C0_CONTEXT);
    printString(testAddr);
}

void initKernel(){
    printString("hkm\n");
    initTlb();
    printString("TLB initialized\n");
    runTest();
}