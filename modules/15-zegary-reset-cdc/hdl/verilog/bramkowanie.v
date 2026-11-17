// Trzy liczniki tego samego zegara z tym samym sygnałem zezwolenia en (15.01):
//   cnt_ce  — zezwolenie zegara (clock enable): zegar zawsze ten sam, en wybiera, czy rejestr się zmienia,
//   cnt_and — zegar bramkowany bramką AND: gclk = clk & en. en zmienia się tuż po zboczu (gdy clk = 1),
//             więc gclk dostaje dodatkowe zbocze — licznik liczy o jeden za dużo w każdym oknie en = 1,
//   cnt_icg — bramkowanie z zatrzaskiem (ICG): en przechodzi przez zatrzask przezroczysty przy clk = 0,
//             gclk = clk & en_lat nie ma dodatkowych zboczy; wynik = cnt_ce.
// W FPGA ani AND, ani zatrzask — zezwolenie zegara albo blok sterowania zegarem (ALTCLKCTRL, BUFGCE).
`default_nettype none

/* verilator lint_off SYNCASYNCNET */          // rst: synchroniczny w cnt_ce, asynchroniczny w licznikach
module bramkowanie (                         // z zegarem bramkowanym — przykład, nie wzorzec
    input  wire       clk,
    input  wire       rst,
    input  wire       en,                      // z przerzutnika taktowanego clk
    output reg  [7:0] cnt_ce,
    output reg  [7:0] cnt_and,
    output reg  [7:0] cnt_icg
);
    always @(posedge clk)
        if (rst)     cnt_ce <= 8'd0;
        else if (en) cnt_ce <= cnt_ce + 8'd1;

    // ŹLE: zegar z logiki
    wire gclk_and = clk & en;
    always @(posedge gclk_and or posedge rst)
        if (rst) cnt_and <= 8'd0;
        else     cnt_and <= cnt_and + 8'd1;

    // komórka bramkująca z zatrzaskiem (ICG), jak w układach ASIC
    reg en_lat = 1'b0;
    /* verilator lint_off LATCH */
    always @(*)
        if (!clk) en_lat = en;                 // zatrzask przezroczysty przy clk = 0
    /* verilator lint_on LATCH */
    wire gclk_icg = clk & en_lat;
    always @(posedge gclk_icg or posedge rst)
        if (rst) cnt_icg <= 8'd0;
        else     cnt_icg <= cnt_icg + 8'd1;
endmodule
/* verilator lint_on SYNCASYNCNET */

`default_nettype wire
