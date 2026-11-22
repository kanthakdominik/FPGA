// Plik rejestrów RV32I (27.07): 31 rejestrów (x0 = 0), dwa odczyty kombinacyjne, jeden zapis na zboczu.
// PRZEZ = 1 — zapis widoczny w odczycie w tym samym takcie (przekazanie WB -> ID w rdzeniu potokowym);
// w rdzeniu jednocyklowym PRZEZ = 0 (inaczej pętla kombinacyjna: odczyt -> ALU -> zapis -> odczyt).
`default_nettype none

module rv_rejestry #(
    parameter PRZEZ = 0
) (
    input  logic        clk,
    input  logic        we,
    input  logic [4:0]  wa,
    input  logic [31:0] wd,
    input  logic [4:0]  ra1,
    input  logic [4:0]  ra2,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);
    logic [31:0] r [0:31];
    integer i;
    initial for (i = 0; i < 32; i = i + 1) r[i] = 32'd0;

    always_ff @(posedge clk)
        if (we && wa != 5'd0) r[wa] <= wd;

    assign rd1 = (ra1 == 5'd0) ? 32'd0 : (PRZEZ != 0 && we && wa == ra1) ? wd : r[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'd0 : (PRZEZ != 0 && we && wa == ra2) ? wd : r[ra2];
endmodule

`default_nettype wire
