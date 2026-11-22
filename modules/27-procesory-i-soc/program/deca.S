# Program dla płytki DECA (27.07, projekt deca/rv): własny rdzeń rv_potok w rv_soc, zegar 50 MHz.
#   LED[6:0] — licznik binarny co 0,5 s (SW[0] = 0) albo biegnące światło (SW[0] = 1); SW[1] = 1 zatrzymuje,
#   KEY[1] zeruje licznik; LED[7] — „oddychanie” z peryferium pwm_avl (wypełnienie zmieniane co 20 ms).
# Wejścia (odczyt IO+0): bit 0 KEY[0], bit 1 KEY[1] (0 = wciśnięty), bity 3:2 SW[1:0].

.equ IO,      0x10000000
.equ LED,     0x00
.equ TAKTY,   0x04
.equ PWM,     0x100
.equ OKRES,   50000            # 1 kHz przy 50 MHz
.equ KROK,    1000             # zmiana wypełnienia co 20 ms: pełny cykl jasności ok. 2 s
.equ T20MS,   1000000

start:
    li    s1, IO
    li    t0, OKRES
    sw    t0, PWM+4(s1)
    sw    zero, PWM+8(s1)
    li    t0, 1
    sw    t0, PWM+0(s1)        # włącz PWM (bez przerwania)
    li    s2, 0                # licznik
    li    s3, 0                # wypełnienie
    li    s4, KROK             # kierunek zmiany wypełnienia
    li    s6, 0                # liczba okresów 20 ms
    li    s7, 1                # biegnące światło
    lw    s5, TAKTY(s1)

petla:
    lw    t0, TAKTY(s1)        # czekaj 20 ms (licznik taktów, różnica bez znaku — odporna na przepełnienie)
    sub   t1, t0, s5
    li    t2, T20MS
    bltu  t1, t2, petla
    add   s5, s5, t2

    add   s3, s3, s4           # oddychanie: wypełnienie 0 ... OKRES i z powrotem
    li    t2, OKRES
    blt   s3, t2, nie_max
    mv    s3, t2
    neg   s4, s4
nie_max:
    bge   s3, zero, nie_min
    li    s3, 0
    neg   s4, s4
nie_min:
    sw    s3, PWM+8(s1)

    lw    t3, LED(s1)          # wejścia
    andi  t4, t3, 2            # KEY[1] wciśnięty (0) -> zeruj licznik
    bnez  t4, bez_zerowania
    li    s2, 0
    li    s7, 1
bez_zerowania:
    addi  s6, s6, 1            # co 25 okresów (0,5 s) krok licznika
    li    t2, 25
    bltu  s6, t2, pokaz
    li    s6, 0
    andi  t4, t3, 8            # SW[1] = 1 — stop
    bnez  t4, pokaz
    addi  s2, s2, 1
    slli  s7, s7, 1            # biegnące światło po 7 diodach
    li    t2, 0x80
    bltu  s7, t2, pokaz
    li    s7, 1
pokaz:
    andi  t4, t3, 4            # SW[0]: 0 — licznik, 1 — biegnące światło
    mv    t5, s2
    beqz  t4, wybrane
    mv    t5, s7
wybrane:
    andi  t5, t5, 0x7F
    sw    t5, LED(s1)
    j     petla
