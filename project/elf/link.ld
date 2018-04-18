ENTRY(main)

SECTIONS {
    . = 0x0;
    .text : { *(.text) }
    /* . = 0x100; */
    .data : { *(.data) }
    .bss  : { *(.bss) }
}