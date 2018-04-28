#ifndef __KERNEL_H__
#define __KERNEL_H__

typedef struct _GlobalTable {
    unsigned int regs[32];
} GlobalTable;

extern GlobalTable *globalTable;

#endif