// Echo (25.02): pętla ze sprzężeniem zwrotnym przez linię opóźniającą D próbek w pamięci blokowej:
//   y[n] = nasyc(x[n] + g·y[n-D] / 256)
// W pamięci zapisywane jest 16 starszych bitów y (oszczędność pamięci: D · 16 bitów). g = 0..255 (0 — brak echa,
// 192 — wygasanie o 25% na powtórzenie). Dwa takty na próbkę: odczyt pamięci, potem suma i zapis.
`default_nettype none

module echo #(
    parameter integer D = 1024                  // opóźnienie w próbkach (12000 przy 48 kHz = 250 ms)
) (
    input  wire               clk,
    input  wire               rst,
    input  wire               we,
    input  wire signed [23:0] x,
    input  wire        [7:0]  g,
    output reg  signed [23:0] y,
    output reg                y_wazne
);
    localparam integer AW = $clog2(D);
    /* verilator lint_off WIDTHTRUNC */
    localparam [AW-1:0] OST = D - 1;
    /* verilator lint_on WIDTHTRUNC */

    reg  [15:0]   ram [0:D-1];
    integer i;
    initial for (i = 0; i < D; i = i + 1) ram[i] = 16'd0;

    reg  [AW-1:0]      ptr;
    reg  [15:0]        q;
    reg  signed [23:0] xr;
    reg                faza;
    wire signed [16:0] gz   = {9'd0, g};                          // g bez znaku -> dodatnia liczba ze znakiem
    /* verilator lint_off WIDTHEXPAND */
    /* verilator lint_off UNUSEDSIGNAL */      // il[7:0] — część ułamkowa
    wire signed [40:0] il   = $signed({q, 8'd0}) * gz;            // y[n-D] · g (Q8)
    /* verilator lint_on UNUSEDSIGNAL */
    /* verilator lint_on WIDTHEXPAND */
    wire signed [32:0] suma = {{9{xr[23]}}, xr} + il[40:8];
    wire signed [23:0] nasyc = (suma > 33'sd8388607)  ? 24'sh7FFFFF :
                               (suma < -33'sd8388608) ? 24'sh800000 : suma[23:0];

    always @(posedge clk) begin
        y_wazne <= 1'b0;
        q <= ram[ptr];
        if (rst) begin
            ptr <= {AW{1'b0}}; faza <= 1'b0; xr <= 24'sd0; y <= 24'sd0;
        end else if (!faza) begin
            if (we) begin xr <= x; faza <= 1'b1; end
        end else begin
            y        <= nasyc;
            y_wazne  <= 1'b1;
            ram[ptr] <= nasyc[23:8];
            ptr      <= (ptr == OST) ? {AW{1'b0}} : ptr + 1'b1;
            faza     <= 1'b0;
        end
    end
endmodule

`default_nettype wire
