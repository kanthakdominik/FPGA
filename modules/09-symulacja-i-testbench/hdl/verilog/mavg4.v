// Średnia krocząca z 4 ostatnich próbek ze znakiem: y = floor((x + x1 + x2 + x3) / 4).
// Wyjście rejestrowane: po zboczu z in_valid = 1 — y z nową próbką i out_valid = 1; bez in_valid y się nie zmienia.
// Układ testowy dla całego modułu 09 (testbench podstawowy, z modelem, z wektorów z pliku, po syntezie).
`default_nettype none

module mavg4 (
    input  wire              clk,
    input  wire              rst,
    input  wire              in_valid,
    input  wire signed [7:0] x,
    output reg               out_valid,
    output reg  signed [7:0] y
);
    reg  signed [7:0] x1, x2, x3;              // trzy poprzednie próbki
    // suma na 10 bitach (bez przepełnienia); floor(sum / 4) w kodzie U2 = odrzucenie dwóch najmłodszych bitów
    /* verilator lint_off UNUSEDSIGNAL */      // sum[1:0] odrzucane celowo
    wire signed [9:0] sum = {{2{x[7]}}, x} + {{2{x1[7]}}, x1} + {{2{x2[7]}}, x2} + {{2{x3[7]}}, x3};
    /* verilator lint_on UNUSEDSIGNAL */

    always @(posedge clk)
        if (rst) begin
            x1 <= 8'sd0; x2 <= 8'sd0; x3 <= 8'sd0;
            out_valid <= 1'b0;
            y <= 8'sd0;
        end else begin
            out_valid <= in_valid;
            if (in_valid) begin
                y  <= sum[9:2];                // średnia mieści się w 8 bitach (-128..127)
                x3 <= x2;
                x2 <= x1;
                x1 <= x;
            end
        end
endmodule

`default_nettype wire
