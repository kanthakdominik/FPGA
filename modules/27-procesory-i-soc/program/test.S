# Program testowy rdzeni rv_jedno i rv_potok (27.07) — wszystkie instrukcje RV32I (bez ecall/ebreak/CSR),
# przypadki brzegowe ALU, odczyty i zapisy bajtów i półsłów, wszystkie skoki warunkowe w obie strony,
# wywołania funkcji, zależności tuż po sobie (przekazywanie, load-use) i kilka pętli (Fibonacci, sortowanie,
# mnożenie i dzielenie programowe). Każdy wynik trafia do pamięci (sw) — testbench porównuje ślad zapisów
# z symulatorem rvasm.py. Koniec: zapis 1 pod TOHOST.

.equ IO,      0x10000000
.equ LED,     0x00            # przesunięcia względem IO
.equ TOHOST,  0x08
.equ KONSOLA, 0x0C
.equ PWM,     0x100
.equ SYG,     0x1000          # obszar wyników
.equ BUF,     0x1800          # bufor do testów pamięci
.equ STOS,    0x2000

start:
    li    sp, STOS
    li    s0, SYG
    li    s1, IO

# ---------------------------------------------------------------- 1. LUI, AUIPC, ADDI
    lui   t0, 0x12345
    sw    t0, 0(s0)
    auipc t1, 0
    sw    t1, 4(s0)
    addi  t2, t0, 0x678
    sw    t2, 8(s0)
    addi  t2, t2, -1
    sw    t2, 12(s0)
    li    a0, -2048
    sw    a0, 16(s0)
    lui   a1, 0xFFFFF
    sw    a1, 20(s0)
    addi  s0, s0, 24

# ---------------------------------------------------------------- 2. ALU: wartości brzegowe
    li    a0, 0x7FFFFFFF
    li    a1, 1
    add   a2, a0, a1          # przepełnienie: 0x80000000
    sw    a2, 0(s0)
    sub   a3, a1, a0          # 1 - 0x7FFFFFFF
    sw    a3, 4(s0)
    sub   a3, a2, a1          # 0x80000000 - 1
    sw    a3, 8(s0)
    li    a4, -5
    slt   a5, a4, a1          # -5 < 1 ze znakiem: 1
    sw    a5, 12(s0)
    sltu  a5, a4, a1          # 0xFFFFFFFB < 1 bez znaku: 0
    sw    a5, 16(s0)
    slti  a5, a4, -4          # 1
    sw    a5, 20(s0)
    slti  a5, a4, -5          # 0
    sw    a5, 24(s0)
    sltiu a5, a1, -1          # 1 < 0xFFFFFFFF: 1
    sw    a5, 28(s0)
    sltiu a5, a4, 5           # 0
    sw    a5, 32(s0)
    li    t0, 0xF0F0F0F0
    li    t1, 0x0FF00FF0
    xor   t2, t0, t1
    sw    t2, 36(s0)
    or    t2, t0, t1
    sw    t2, 40(s0)
    and   t2, t0, t1
    sw    t2, 44(s0)
    xori  t2, t0, -1          # not
    sw    t2, 48(s0)
    ori   t2, t0, 0x00F
    sw    t2, 52(s0)
    andi  t2, t0, -16         # 0xFFFFFFF0
    sw    t2, 56(s0)
    andi  t2, t0, 0x7FF
    sw    t2, 60(s0)
    addi  s0, s0, 64

# ---------------------------------------------------------------- 3. przesunięcia
    li    t0, 0x80000001
    li    t1, 33              # w rejestrze liczy się 5 młodszych bitów: 1
    sll   t2, t0, t1
    sw    t2, 0(s0)
    srl   t2, t0, t1
    sw    t2, 4(s0)
    sra   t2, t0, t1
    sw    t2, 8(s0)
    slli  t2, t0, 31
    sw    t2, 12(s0)
    srli  t2, t0, 31
    sw    t2, 16(s0)
    srai  t2, t0, 31
    sw    t2, 20(s0)
    srai  t2, t0, 0
    sw    t2, 24(s0)
    li    t1, 4
    sra   t2, t0, t1
    sw    t2, 28(s0)
    addi  s0, s0, 32

# ---------------------------------------------------------------- 4. pamięć: bajty, półsłowa, rozszerzenie znaku
    li    t0, BUF
    li    t1, 0x8899AABB
    sw    t1, 0(t0)
    sb    t1, 4(t0)
    sb    t1, 5(t0)
    srli  t2, t1, 8
    sb    t2, 6(t0)
    sb    t2, 7(t0)
    sh    t1, 8(t0)
    sh    t2, 10(t0)
    lb    a0, 0(t0)           # 0xFFFFFFBB
    sw    a0, 0(s0)
    lbu   a0, 0(t0)           # 0x000000BB
    sw    a0, 4(s0)
    lb    a0, 3(t0)           # 0xFFFFFF88
    sw    a0, 8(s0)
    lb    a0, 1(t0)           # 0xFFFFFFAA
    sw    a0, 12(s0)
    lh    a0, 2(t0)           # 0xFFFF8899
    sw    a0, 16(s0)
    lhu   a0, 2(t0)           # 0x00008899
    sw    a0, 20(s0)
    lh    a0, 0(t0)           # 0xFFFFAABB
    sw    a0, 24(s0)
    lw    a0, 4(t0)
    sw    a0, 28(s0)
    lw    a0, 8(t0)
    sw    a0, 32(s0)
    li    t3, 0x7F
    sb    t3, 12(t0)
    lb    a0, 12(t0)          # 0x0000007F
    sw    a0, 36(s0)
    addi  s0, s0, 40

# ---------------------------------------------------------------- 5. skoki warunkowe (wykonane i niewykonane)
    li    a6, 0
    li    t0, -1
    li    t1, 1
    beq   t0, t0, b1
    addi  a6, a6, 1           # pominięte
b1: bne   t0, t0, b2
    addi  a6, a6, 2
b2: blt   t0, t1, b3
    addi  a6, a6, 4           # pominięte
b3: bltu  t0, t1, b4
    addi  a6, a6, 8
b4: bge   t1, t0, b5
    addi  a6, a6, 16          # pominięte
b5: bgeu  t1, t0, b6
    addi  a6, a6, 32
b6: bne   t0, t1, b7
    addi  a6, a6, 64          # pominięte
b7: beq   t0, t1, b8
    addi  a6, a6, 128
b8: bge   t0, t0, b9          # równe: wykonany
    addi  a6, a6, 256         # pominięte
b9: bltu  t1, t0, b10
    addi  a6, a6, 512         # pominięte
b10:
    sw    a6, 0(s0)           # 2 + 8 + 32 + 128 = 170
    addi  s0, s0, 4

# ---------------------------------------------------------------- 6. wywołania funkcji, JAL i JALR
    li    a0, 21
    call  podwoj
    sw    a0, 0(s0)           # 42
    sw    ra, 4(s0)           # adres powrotu
    la    t0, podwoj
    li    a0, 100
    jalr  ra, 1(t0)           # cel (t0 + 1) & ~1 = podwoj
    sw    a0, 8(s0)           # 200
    la    t0, za_skokiem
    jalr  t1, t0, 0
    addi  a0, a0, 1           # pominięte
za_skokiem:
    sw    t1, 12(s0)          # adres instrukcji po jalr
    jal   t2, za_jal
    addi  a0, a0, 1           # pominięte
za_jal:
    sw    t2, 16(s0)
    sw    a0, 20(s0)          # nadal 200
    addi  s0, s0, 24
    j     hazardy

podwoj:
    add   a0, a0, a0
    ret

# ---------------------------------------------------------------- 7. zależności tuż po sobie
hazardy:
    li    t0, 1
    add   t0, t0, t0
    add   t0, t0, t0
    add   t0, t0, t0
    add   t0, t0, t0
    add   t0, t0, t0          # 32
    sw    t0, 0(s0)
    li    t1, BUF
    lw    t2, 0(t1)           # load-use: od razu użyty
    addi  t2, t2, 1
    sw    t2, 4(s0)
    lw    t3, 4(t1)           # odczyt, potem zapis tej wartości
    sw    t3, 8(s0)
    lw    t4, 8(t1)           # odczyt, potem skok warunkowy od niej
    beq   t4, zero, zle
    li    t5, 0x1234
    sw    t5, 16(t1)          # zapis i od razu odczyt tego samego adresu
    lw    t6, 16(t1)
    sw    t6, 12(s0)
    addi  x0, x0, 5           # zapis do x0 nie zmienia nic
    add   a0, x0, x0
    sw    a0, 16(s0)
    li    a1, 7
    add   a2, a1, a1          # wynik z poprzedniej instrukcji (EX -> EX)
    add   a3, a1, a2          # z dwóch wcześniejszych (MEM -> EX i WB -> EX)
    add   a4, a3, a1
    sw    a4, 20(s0)          # 7 + 14 + 7 = 28
    lw    a5, 0(t1)
    lw    a6, 4(t1)
    add   a7, a5, a6          # dwa odczyty pod rząd, drugi od razu użyty
    sw    a7, 24(s0)
    addi  s0, s0, 28
    j     petle
zle:
    li    t0, 0xBAD
    sw    t0, 0(s0)
    j     koniec

# ---------------------------------------------------------------- 8. pętle
petle:
    li    t0, 0               # Fibonacci: F(30) = 832040
    li    t1, 1
    li    t2, 30
fib:
    add   t3, t0, t1
    mv    t0, t1
    mv    t1, t3
    addi  t2, t2, -1
    bnez  t2, fib
    sw    t0, 0(s0)
    addi  s0, s0, 4

    la    a0, tablica         # sortowanie bąbelkowe 16 słów ze znakiem
    li    a1, 16
sort_zew:
    addi  a1, a1, -1
    beqz  a1, sort_koniec
    mv    t0, a0
    mv    t1, a1
sort_wew:
    lw    t2, 0(t0)
    lw    t3, 4(t0)
    ble   t2, t3, bez_zamiany
    sw    t3, 0(t0)
    sw    t2, 4(t0)
bez_zamiany:
    addi  t0, t0, 4
    addi  t1, t1, -1
    bnez  t1, sort_wew
    j     sort_zew
sort_koniec:
    la    t0, tablica         # kopia posortowanej tablicy do obszaru wyników
    li    t1, 16
kopia:
    lw    t2, 0(t0)
    sw    t2, 0(s0)
    addi  t0, t0, 4
    addi  s0, s0, 4
    addi  t1, t1, -1
    bnez  t1, kopia

    li    a0, 123456789       # mnożenie programowe (przesunięcia i dodawania), młodsze 32 bity
    li    a1, 987654321
    li    a2, 0
mnoz:
    andi  t0, a1, 1
    beqz  t0, mnoz_dalej
    add   a2, a2, a0
mnoz_dalej:
    slli  a0, a0, 1
    srli  a1, a1, 1
    bnez  a1, mnoz
    sw    a2, 0(s0)

    li    a0, 1000000007      # dzielenie z odtwarzaniem reszty: iloraz i reszta
    li    a1, 12345
    li    a2, 0               # iloraz
    li    a3, 0               # reszta
    li    t0, 32
dziel:
    slli  a3, a3, 1
    srli  t1, a0, 31
    or    a3, a3, t1
    slli  a0, a0, 1
    slli  a2, a2, 1
    bltu  a3, a1, dziel_dalej
    sub   a3, a3, a1
    ori   a2, a2, 1
dziel_dalej:
    addi  t0, t0, -1
    bnez  t0, dziel
    sw    a2, 4(s0)           # 81004
    sw    a3, 8(s0)           # 1000000007 - 81004·12345
    addi  s0, s0, 12

# ---------------------------------------------------------------- 9. peryferia: LED, rejestry PWM
    li    t0, 0x55
    sw    t0, LED(s1)
    li    t0, 1000
    sw    t0, PWM+4(s1)       # OKRES
    li    t0, 250
    sw    t0, PWM+8(s1)       # WYPELN
    sw    zero, PWM+0(s1)     # STER: wyłączony
    lw    t1, PWM+4(s1)
    lw    t2, PWM+8(s1)
    add   t3, t1, t2          # odczyt z peryferium od razu użyty
    sw    t3, 0(s0)           # 1250
    addi  s0, s0, 4

# ---------------------------------------------------------------- 10. konsola i koniec
    la    t0, napis
pisz:
    lbu   t1, 0(t0)
    beqz  t1, koniec
    sw    t1, KONSOLA(s1)
    addi  t0, t0, 1
    j     pisz
koniec:
    li    t0, 1
    sw    t0, TOHOST(s1)
stoj:
    j     stoj

# ---------------------------------------------------------------- dane
.org 0x1C00
tablica:
    .word 17, -3, 2047, 0, -2048, 99, 5, 0x7FFFFFFF, -1, 42, 8, 0x80000000, 3, 1000, -77, 6
napis:
    .asciz "RV32I OK\n"
