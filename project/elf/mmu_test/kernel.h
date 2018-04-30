#ifndef __KERNEL_H__
#define __KERNEL_H__
typedef unsigned char uint8_t;
typedef unsigned int uint32_t;

#define AT_FRAME(f) __attribute__((section(".data.frame" f)));

typedef struct _GlobalTable {
    uint32_t regs[32];
} GlobalTable;

extern GlobalTable globalTable;

#endif