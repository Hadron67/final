ENTRY(_start)
MEMORY {
    UNMAPPED (RWX) : ORIGIN = 0x80000000, LENGTH = 4K
}
SECTIONS {
    .text : {
        . = 0x0;
        *(.text.start)
        . = 0x80;
        *(.text.ihandler)
        *(.text)
    } >UNMAPPED

    .data : {
        *(.data)
        *(.rdata)
        *(.bss)
    } >UNMAPPED

    /DISCARD/ : { *(.reginfo) }
}