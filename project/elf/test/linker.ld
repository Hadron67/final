ENTRY(_start)
MEMORY {
    RAM (rwx): ORIGIN = 0x0, LENGTH = 4K
}
SECTIONS {
    .text.start : { *(.text.start) } >RAM
    .text : { *(.text) } >RAM
    /* . = 0x100; */
    .data : { *(.data) } >RAM
    .rdata : { *(.rdata) } >RAM
    .bss  : { *(.bss) } >RAM
}