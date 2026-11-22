// Pamięć dwuportowa z dwoma zegarami (31.02): zapis w domenie A, odczyt rejestrowany w domenie B.
// Quartus wnioskuje blok M9K w trybie simple dual-port z dwoma zegarami.
`default_nettype none

module ram_2z #(
    parameter integer AW = 10,
    parameter integer DW = 8
) (
    input  logic          clk_a,
    input  logic          we,
    input  logic [AW-1:0] wadr,
    input  logic [DW-1:0] wdane,
    input  logic          clk_b,
    input  logic [AW-1:0] radr,
    output logic  [DW-1:0] rdane
);
    logic [DW-1:0] pam [0:(1<<AW)-1];
    integer i;
    initial for (i = 0; i < (1 << AW); i = i + 1) pam[i] = {DW{1'b0}};
    always_ff @(posedge clk_a) if (we) pam[wadr] <= wdane;
    always_ff @(posedge clk_b) rdane <= pam[radr];
endmodule

`default_nettype wire
