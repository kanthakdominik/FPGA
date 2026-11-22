# Kod startowy dla rv_soc (27.03, 27.07): stos na końcu RAM, zerowanie .bss, wywołanie main, zapis wyniku
# pod TOHOST ((kod << 1) | 1 — 1 oznacza main() == 0) i pętla. .data nie trzeba kopiować: cały obraz programu
# (kod i dane) jest wczytany do RAM, z której program się wykonuje.
    .section .text.start
    .globl _start
_start:
    .option push
    .option norelax
    la    sp, _stos
    .option pop
    la    t0, _bss_start
    la    t1, _bss_end
1:  bgeu  t0, t1, 2f
    sw    zero, 0(t0)
    addi  t0, t0, 4
    j     1b
2:  call  main
    slli  a0, a0, 1
    ori   a0, a0, 1
    li    t0, 0x10000008
    sw    a0, 0(t0)
3:  j     3b
