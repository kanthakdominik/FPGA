# Program mikrokontrolera rv_mcu (31.06) — RV32I, asembler z modułu 27 (rvasm.py) przez zloz.py.
# Stałe OKRES_LED (takty między zmianami LED), OKRES_PWM i WYPELN_PWM dopisuje zloz.py osobno dla symulacji
# i dla płytki. Działanie:
#   powitanie przez UART, PWM (WYPELN_PWM / OKRES_PWM), licznik na LED co OKRES_LED taktów (przerwanie
#   licznika zastąpione odpytywaniem flagi porównania), echo UART z zamianą małych liter na wielkie, po CR
#   dodatkowo LF; znak 'q' — pożegnanie i zapis TOHOST (koniec symulacji; na płytce: pętla).
# Mapa (IO = 0x1000_0000): +0 GPIO (LED / wejścia), +4 LICZNIK, +8 PORÓWNANIE, +C FLAGA (W1C),
# +10 UART DANE, +14 UART STATUS (bit 0 nadajnik wolny, bit 1 jest bajt, bit 2 przepełnienie), +18 TOHOST,
# +100 pwm_avl (STER, OKRES, WYPELN, STATUS).

.equ IO,       0x10000000
.equ GPIO,     0x00
.equ LICZNIK,  0x04
.equ POROWN,   0x08
.equ FLAGA,    0x0C
.equ DANE,     0x10
.equ STATUS,   0x14
.equ TOHOST,   0x18
.equ PWM,      0x100

start:
    li    s1, IO
    li    t0, OKRES_PWM
    sw    t0, PWM+4(s1)
    li    t0, WYPELN_PWM
    sw    t0, PWM+8(s1)
    li    t0, 1
    sw    t0, PWM+0(s1)          # PWM włączony, bez przerwania
    lw    t0, LICZNIK(s1)
    li    t1, OKRES_LED
    add   t0, t0, t1
    sw    t0, POROWN(s1)         # pierwsze porównanie
    li    s2, 0                  # stan LED
    la    a0, powitanie
    call  pisz

petla:
    lw    t0, FLAGA(s1)          # minął okres LED?
    beqz  t0, uart
    li    t1, 1
    sw    t1, FLAGA(s1)          # skasuj flagę
    lw    t0, POROWN(s1)
    li    t1, OKRES_LED
    add   t0, t0, t1
    sw    t0, POROWN(s1)         # następne porównanie: równe odstępy niezależnie od opóźnień
    addi  s2, s2, 1
    sw    s2, GPIO(s1)

uart:
    lw    t0, STATUS(s1)
    andi  t0, t0, 2
    beqz  t0, petla
    lw    a0, DANE(s1)           # odczyt zdejmuje bajt
    li    t1, 113                # 'q'
    beq   a0, t1, koniec
    li    t1, 97                 # 'a'
    blt   a0, t1, echo
    li    t1, 122                # 'z'
    bgt   a0, t1, echo
    addi  a0, a0, -32
echo:
    call  wyslij
    li    t1, 13                 # CR -> także LF
    bne   a0, t1, petla
    li    a0, 10
    call  wyslij
    j     petla

koniec:
    la    a0, pozegnanie
    call  pisz
czekaj_tx:
    lw    t0, STATUS(s1)         # ostatni bajt musi wyjść
    andi  t0, t0, 1
    beqz  t0, czekaj_tx
    sw    zero, TOHOST(s1)
stop:
    j     stop

# wyslij: a0 — znak (zachowuje a0)
wyslij:
    lw    t2, STATUS(s1)
    andi  t2, t2, 1
    beqz  t2, wyslij
    sw    a0, DANE(s1)
    ret

# pisz: a0 — adres napisu zakończonego zerem
pisz:
    lbu   t3, 0(a0)
    beqz  t3, pisz_k
pisz_c:
    lw    t2, STATUS(s1)
    andi  t2, t2, 1
    beqz  t2, pisz_c
    sw    t3, DANE(s1)
    addi  a0, a0, 1
    j     pisz
pisz_k:
    ret

powitanie:
    .asciz "RISC-V MCU (31.06)\r\n"
pozegnanie:
    .asciz "\r\nKONIEC\r\n"
