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

typedef void (*runnable)();

GlobalTable globalTable;

static const int segDecode[] = {
    0b00111111,//0
    0b00000110,//1
    0b01011011,//2
    0b01001111,//3
    0b01100110,//4
    0b01101101,//5
    0b01111101,//6
    0b00000111,//7
    0b01111111,//8
    0b01101111,//9
};

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

static void switchMode(uint32_t mode){
    uint32_t status;
    MFC0(status, C0_STATUS);
    status &= ~0b11000;
    status |= mode << 3;
    MTC0(status, C0_STATUS);
}

static void PageTable_writeEntry(PageTable *table, uint32_t vpn2, uint8_t asid, uint32_t mask, uint32_t fpn, int even){
    PageTableEntry *entry = table->entries + vpn2;
    entry->entryHi = (vpn2 << 13) | (asid & 0xff);
    entry->pageMask = mask << 13;
    uint32_t entryLo = (fpn << 6) | 2 | (asid == 0) | 3 << 3;
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
    uint32_t entryLo = (fpn << 6) | 2 | (asid == 0) | 3 << 3;
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

        MTC0(2, C0_INDEX);
        TLBWI();
    }
    else {
        printString("invalid entry, do page fault\n");
        do_pageFault();
    }
}

void handler_tlbMod(){
    printString("modified\n");
}
void handler_tlbLoad(){
    printString("load\n");
    do_tlbRefill(0);
}
void handler_tlbStore(){
    printString("store\n");
    do_tlbRefill(1);
}

static PageTable testTable AT_FRAME("1");
static const char testString[] AT_FRAME("2");
static const char testString[512] = "hkm, soor\n";
extern uint32_t __frame1_start;
extern uint32_t __frame2_start;
extern uint32_t __test_start, __test_end;

static void segTest() __attribute__ ((section(".text.tester")));
static void runTest();
static void copyWords(uint32_t *dest, const uint32_t *src, uint32_t size);

#define PTABLE_ADDR (0x800 << 13)

static void runTest(){
    char *testAddr = (const char *)(0x2 << 13);
    PageTable *table = (PageTable *)(0x0);
    // map VPN2 PTABLE_ADDR to frame1, and 0x2 to frame2
    writeTlb(0, 0x0, 1, 0, (uint32_t)&__frame1_start >> 12, 1);

    PageTable_init(table);
    PageTable_writeEntry(table, 0x0, 1, 0, (uint32_t)&__frame1_start >> 12, 1);
    PageTable_writeEntry(table, 0x2, 1, 0, (uint32_t)&__frame2_start >> 12, 1);
    MTC0(0x0, C0_CONTEXT);
    printString(testAddr);
    IO_WRITE_SEG0(segDecode[3]);
    copyWords((uint32_t *)testAddr, (uint32_t *)&__test_start, (uint32_t)&__test_end - (uint32_t)&__test_start);
    switchMode(2);// user mode
    ((runnable)testAddr)();
}

static void copyWords(uint32_t *dest, const uint32_t *src, uint32_t size){
    size >>= 2;
    while(size --> 0){
        *dest++ = *src++;
    }
    printString("copy done\n");
}

static void segTest(){
    int a = 0, b = 0, c = 0, j;
    while(1){
        IO_WRITE_SEG5(segDecode[a]);
        IO_WRITE_SEG4(segDecode[b]);
        IO_WRITE_SEG3(segDecode[c] | 0x80);
        a++;
        if(a == 10){
            a = 0;
            b++;
            if(b == 6){
                b = 0;
                c++;
                if(c == 10)
                    c = 0;
            }
        }
        for(j = 0; j < 1000000; j++);
    }
}

void initKernel(){
    IO_WRITE_SEG0(segDecode[1]);
    printString("hkm\n");
    initTlb();
    printString("TLB initialized\n");
    IO_WRITE_SEG0(segDecode[2]);
    runTest();
    IO_WRITE_SEG0(segDecode[4]);
}