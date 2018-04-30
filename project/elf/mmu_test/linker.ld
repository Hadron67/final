ENTRY(_start)
MEMORY {
    UNMAPPED (RWX) : ORIGIN = 0x80000000, LENGTH = 8M
}
__SEG_BASE = 0x80000000;
__frame1_start = 2 << 12;
__frame2_start = __frame1_start + (1 << 12);

SECTIONS {
    .text.fixed __SEG_BASE : AT(0) ALIGN(4) {
        *(.text.start)
        . = 0x80;
        *(.text.ihandler)
    } > UNMAPPED
    .text : ALIGN(4) {
        *(.text)
    } > UNMAPPED
    .data : ALIGN(4) {
        *(.data)
        *(.rodata)
        *(.rdata)
        *(.bss)
    } > UNMAPPED
    
    .data.experiment __SEG_BASE | __frame1_start : AT(__frame1_start) ALIGN(4) {
        *(.data.frame1)
        . = __frame2_start - __frame1_start;
        *(.data.frame2)
    } > UNMAPPED

    /DISCARD/ : { *(.reginfo) *(.MIPS.abiflags) *(.rel.dyn) }
}