/* Skrypt konsolidatora dla rv_soc (27.03, 27.07): jedna pamięć RAM 8 KB od adresu 0, kod startowy na początku,
   stos od końca RAM w dół. */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 8K
}

SECTIONS
{
    .text : {
        KEEP(*(.text.start))
        *(.text .text.*)
    } > RAM
    .rodata : ALIGN(4) {
        *(.rodata .rodata.* .srodata .srodata.*)
    } > RAM
    .data : ALIGN(4) {
        *(.data .data.* .sdata .sdata.*)
    } > RAM
    .bss (NOLOAD) : ALIGN(4) {
        _bss_start = .;
        *(.bss .bss.* .sbss .sbss.* COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > RAM
    _stos = ORIGIN(RAM) + LENGTH(RAM);
}
