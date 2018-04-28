#ifndef __MIPS_REG_H__
#define __MIPS_REG_H__

#define C0_INDEX     "$0"
#define C0_RANDOM    "$1"
#define C0_ENTRYLO0  "$2"
#define C0_ENTRYLO1  "$3"
#define C0_CONTEXT   "$4"
#define C0_PAGEMASK  "$5"
#define C0_WIRED     "$6"
#define C0_ENTRYHI   "$10"
#define C0_STATUS    "$12"
#define C0_CAUSE     "$13"

#define TLB_ENTRY_COUNT 16

#define IO_PUTCHAR(a) (*((int *)0xa0000001) = (a))

#define MFR(v, reg)  __asm__ volatile ("move %0, " reg: "=r" (v));
#define MTR(reg, v)  __asm__ volatile ("move " reg ", %0":: "r"(v));
#define MFC0(v, reg) __asm__ volatile ("mfc0 %0, " reg: "=r" (v));
#define MTC0(v, reg) __asm__ volatile ("mtc0 %0, " reg:: "r" (v));
#define TLBWI()      __asm__ volatile ("tlbwi");
#define TLBWR()      __asm__ volatile ("tlbwr");
#define SYSCALL()    __asm__ volatile ("syscall");

#endif