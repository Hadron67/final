ENTRY(_start)

SECTIONS {
    . = 0x80000000;
    .text.start : { *(.text.start) }
    .text : { *(.text) }
    .data : { *(.data) }
    .rdata : { *(.rdata) }
    .bss  : { *(.bss) }
}