// Moduł nadrzędny DECA — Verilog. Projekt do analizy czasowej (moduł 14):
//   PLL: 50 MHz -> clk_sys 100 MHz (zegar generowany, 14.03),
//   dzielnik_mc: dzielenie co 0,25 s, ścieżka wielotaktowa N = 8 (14.04),
//   spi_master: SPI 25 MHz na złączu P8 — interfejs z zegarem przesyłanym razem z danymi (14.06):
//     GPIO0_D[0] = SCLK, GPIO0_D[1] = MOSI, GPIO0_D[2] = CS_N (wyjścia), GPIO0_D[3] = MISO (wejście);
//     zworka GPIO0_D[1] – GPIO0_D[3] zamyka pętlę: odebrany bajt = wysłany.
//   KEY[0]  — reset; SW[0] = 0: LED = bajt odebrany przez SPI, 1: LED = iloraz (SW[1] = 1: reszta).
// Ograniczenia: sta.sdc. W symulatorach (Icarus, Verilator) zamiast altpll jest zwykłe przepięcie zegara.
`default_nettype none

`ifdef __ICARUS__
`define DECA_BEZ_PLL
`endif
`ifdef VERILATOR
`define DECA_BEZ_PLL
`endif

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,                     // 0 = wciśnięty
    input  wire [1:0] SW,                      // 0 = w dół
    output reg  [7:0] LED = 8'hFF,             // 0 = świeci
    inout  wire [3:0] GPIO0_D
);
    // ---- PLL: 50 MHz -> 100 MHz ----
    wire clk_sys, locked;
`ifdef DECA_BEZ_PLL
    assign clk_sys = MAX10_CLK1_50;
    assign locked  = 1'b1;
`else
    wire [4:0] pll_clk;
    altpll #(
        .intended_device_family ("MAX 10"),
        .lpm_type               ("altpll"),
        .operation_mode         ("NORMAL"),
        .pll_type               ("AUTO"),
        .inclk0_input_frequency (20000),       // ps
        .clk0_multiply_by       (2),
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
    wire       rst_n_async = KEY[0] & locked;
    reg  [1:0] rst_sync = 2'b00;
    always @(posedge clk_sys or negedge rst_n_async)
        if (!rst_n_async) rst_sync <= 2'b00;
        else              rst_sync <= {rst_sync[0], 1'b1};
    wire rst = ~rst_sync[1];

    // ---- przełączniki: dwa przerzutniki synchronizujące ----
    reg [1:0] sw_meta = 2'b00, sw = 2'b00;
    always @(posedge clk_sys) begin
        sw_meta <= SW;
        sw      <= sw_meta;
    end

    // ---- impuls co 0,25 s, licznik bajtów i LFSR jako dzielna ----
    reg [24:0] div = 25'd0;
    reg        tick = 1'b0;
    reg [7:0]  cnt8 = 8'd0;
    reg [15:0] lfsr = 16'hACE1;
    always @(posedge clk_sys) begin
        tick <= (div == 25'd24999999);
        div  <= (div == 25'd24999999) ? 25'd0 : div + 25'd1;
        if (tick) begin
            cnt8 <= cnt8 + 8'd1;
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        end
    end

    // ---- dzielnik ze ścieżką wielotaktową ----
    wire [15:0] q;
    wire [7:0]  r;
    wire        d_busy, d_done;
    dzielnik_mc #(.W(16), .V(8), .N(8)) u_dziel (
        .clk(clk_sys), .rst(rst), .start(tick), .a(lfsr), .b(cnt8),
        .busy(d_busy), .done(d_done), .q(q), .r(r)
    );

    // ---- SPI 25 MHz ----
    wire       s_busy, s_done, sclk, mosi, cs_n;
    wire [7:0] rx;
    spi_master #(.DIV(2)) u_spi (
        .clk(clk_sys), .rst(rst), .start(tick), .tx(cnt8), .busy(s_busy), .done(s_done), .rx(rx),
        .sclk(sclk), .mosi(mosi), .cs_n(cs_n), .miso(GPIO0_D[3])
    );
    assign GPIO0_D[0] = sclk;
    assign GPIO0_D[1] = mosi;
    assign GPIO0_D[2] = cs_n;
    assign GPIO0_D[3] = 1'bz;

    // ---- diody ----
    reg [7:0] rx_last = 8'd0, q_last = 8'd0, r_last = 8'd0;
    always @(posedge clk_sys) begin
        if (s_done) rx_last <= rx;
        if (d_done) begin
            q_last <= q[7:0];
            r_last <= r;
        end
        LED <= ~(sw[0] ? (sw[1] ? r_last : q_last) : rx_last);
    end
endmodule

`default_nettype wire
