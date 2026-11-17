// Moduł nadrzędny DECA — SystemVerilog. Projekt do zamykania timingu i analizy mocy (moduł 16):
//   PLL: 50 MHz -> clk_sys 150 MHz,
//   sumator_drzewo (PIPE stopni potoku): osiem 16-bitowych próbek z LFSR w każdym takcie (16.01, 16.04),
//   izolacja_operandow (ISO): mnożenie 16 x 16, dane ważne co czwarty takt (16.06).
//   Wyniki składane w sumy kontrolne XOR, żeby synteza nie usunęła logiki.
//   KEY[0] — reset; SW[0] = 0: LED = suma kontrolna drzewa, 1: LED = suma kontrolna iloczynów.
// Ograniczenia: wydajnosc.sdc. W symulatorach (Verilator) zamiast altpll jest przepięcie zegara.
`ifdef VERILATOR
`define DECA_BEZ_PLL
`endif

module deca_top #(
    parameter int PIPE = 2,
    parameter bit ISO  = 1'b1
) (
    input  logic       MAX10_CLK1_50,
    input  logic [1:0] KEY,                     // 0 = wciśnięty
    input  logic [1:0] SW,                      // 0 = w dół
    output logic [7:0] LED = 8'hFF              // 0 = świeci
);
    // ---- PLL: 50 MHz -> 150 MHz ----
    logic clk_sys, locked;
`ifdef DECA_BEZ_PLL
    assign clk_sys = MAX10_CLK1_50;
    assign locked  = 1'b1;
`else
    logic [4:0] pll_clk;
    altpll #(
        .intended_device_family ("MAX 10"),
        .lpm_type               ("altpll"),
        .operation_mode         ("NORMAL"),
        .pll_type               ("AUTO"),
        .inclk0_input_frequency (20000),       // ps
        .clk0_multiply_by       (3),
        .clk0_divide_by         (1),
        .clk0_duty_cycle        (50),
        .clk0_phase_shift       ("0"),
        .compensate_clock       ("CLK0"),
        .width_clock            (5)
    ) u_pll (
        .inclk  ({1'b0, MAX10_CLK1_50}),
        .areset (1'b0),
        .clk    (pll_clk),
        .locked (locked)
    );
    assign clk_sys = pll_clk[0];
`endif

    // ---- reset: KEY[0] albo brak synchronizacji PLL; zdjęcie synchroniczne z clk_sys ----
    logic       rst_n_async, rst;
    logic [1:0] rst_sync = 2'b00;
    assign rst_n_async = KEY[0] & locked;
    always_ff @(posedge clk_sys or negedge rst_n_async)
        if (!rst_n_async) rst_sync <= 2'b00;
        else              rst_sync <= {rst_sync[0], 1'b1};
    assign rst = ~rst_sync[1];

    // ---- przełącznik: dwa przerzutniki synchronizujące ----
    logic [1:0] sw_sync = 2'b00;
    always_ff @(posedge clk_sys) sw_sync <= {sw_sync[0], SW[0]};

    // ---- źródło danych: LFSR 16 bitów i linia ośmiu ostatnich wartości ----
    logic [15:0]  lfsr = 16'hACE1;
    logic [127:0] okno = '0;
    logic [1:0]   faza = '0;
    always_ff @(posedge clk_sys) begin
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        okno <= {okno[111:0], lfsr};
        faza <= faza + 2'd1;
    end

    // ---- drzewo sumatorów ----
    logic        s_valid;
    logic [18:0] s_y;
    sumator_drzewo #(.W(16), .PIPE(PIPE)) u_sum (
        .clk(clk_sys), .rst, .in_valid(1'b1), .x(okno), .out_valid(s_valid), .y(s_y)
    );

    // ---- mnożarka z izolacją argumentów (dane ważne co czwarty takt) ----
    logic        m_valid;
    logic [31:0] m_p;
    izolacja_operandow #(.W(16), .ISO(ISO)) u_mnoz (
        .clk(clk_sys), .rst, .in_valid(faza == 2'd0), .a(lfsr), .b(okno[31:16]),
        .out_valid(m_valid), .p(m_p)
    );

    // ---- sumy kontrolne i diody ----
    logic [7:0] csum_s = '0, csum_m = '0;
    always_ff @(posedge clk_sys) begin
        if (rst) begin
            csum_s <= '0;
            csum_m <= '0;
        end else begin
            if (s_valid) csum_s <= {csum_s[6:0], csum_s[7]} ^ s_y[7:0] ^ s_y[15:8] ^ {5'd0, s_y[18:16]};
            if (m_valid) csum_m <= {csum_m[6:0], csum_m[7]} ^ m_p[7:0] ^ m_p[15:8] ^ m_p[23:16] ^ m_p[31:24];
        end
        LED <= ~(sw_sync[1] ? csum_m : csum_s);
    end
endmodule
