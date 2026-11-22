// WYGENEROWANE przez narzedzia/rejestry.py z rejestry/pwm_avl.json — nie edytuj ręcznie
// Peryferium PWM ze slave'em Avalon-MM (moduł 27, 27.03), wersja opisu 1.0.0.
// Plik dołączany wewnątrz modułu: `include "pwm_avl_regs.vh" (stałe localparam).
// Moduł zwykle używa części stałych — ostrzeżenie UNUSEDPARAM wyłączone tylko dla tego pliku.
/* verilator lint_off UNUSEDPARAM */

// STER — Sterowanie
localparam [1:0] PWM_AVL_STER_OFF = 2'd0;
localparam [31:0] PWM_AVL_STER_RESET = 32'h00000000;
localparam integer PWM_AVL_STER_WL_POZ = 0;
localparam integer PWM_AVL_STER_WL_SZER = 1;
localparam integer PWM_AVL_STER_PRZ_POZ = 1;
localparam integer PWM_AVL_STER_PRZ_SZER = 1;
// OKRES — Długość okresu w taktach (≥ 2), obowiązuje od następnego okresu
localparam [1:0] PWM_AVL_OKRES_OFF = 2'd1;
localparam [31:0] PWM_AVL_OKRES_RESET = 32'h00000000;
// WYPELN — Takty stanu wysokiego (0 — stale 0, ≥ OKRES — stale 1), od następnego okresu
localparam [1:0] PWM_AVL_WYPELN_OFF = 2'd2;
localparam [31:0] PWM_AVL_WYPELN_RESET = 32'h00000000;
// STATUS — Stan; przerwanie = KONIEC & PRZ
localparam [1:0] PWM_AVL_STATUS_OFF = 2'd3;
localparam [31:0] PWM_AVL_STATUS_RESET = 32'h00000000;
localparam integer PWM_AVL_STATUS_KONIEC_POZ = 0;
localparam integer PWM_AVL_STATUS_KONIEC_SZER = 1;
localparam integer PWM_AVL_STATUS_WYJSCIE_POZ = 1;
localparam integer PWM_AVL_STATUS_WYJSCIE_SZER = 1;
/* verilator lint_on UNUSEDPARAM */
