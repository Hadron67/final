ENTRY(_start)

SECTIONS {
    . = 0x80000000;
    .text.start : { *(.text.start) }
    .text : { *(.text) }
    /* . = 0x100; */
    .data : { *(.data) }
    .rdata : { *(.rdata) }
    .bss  : { *(.bss) }
}