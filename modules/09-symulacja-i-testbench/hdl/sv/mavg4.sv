// Średnia krocząca z 4 ostatnich próbek ze znakiem: y = floor((x + x1 + x2 + x3) / 4).
// Wyjście rejestrowane: po zboczu z in_valid = 1 — y z nową próbką i out_valid = 1; bez in_valid y się nie zmienia.
// Układ testowy dla całego modułu 09 (testbench podstawowy, z modelem, z wektorów z pliku, po syntezie).
module mavg4 (
    input  logic              clk,
    input  logic              rst,
    input  logic              in_valid,
    input  logic signed [7:0] x,
    output logic              out_valid,
    output logic signed [7:0] y
);
    logic signed [7:0] x1, x2, x3;             // trzy poprzednie próbki
    // suma na 10 bitach (bez przepełnienia); floor(sum / 4) w kodzie U2 = odrzucenie dwóch najmłodszych bitów
    /* verilator lint_off UNUSEDSIGNAL */      // sum[1:0] odrzucane celowo
    logic signed [9:0] sum;
    /* verilator lint_on UNUSEDSIGNAL */

    assign sum = 10'(x) + 10'(x1) + 10'(x2) + 10'(x3);   // rzutowanie rozmiaru zachowuje znak

    always_ff @(posedge clk)
        if (rst) begin
            {x1, x2, x3} <= '0;
            out_valid    <= 1'b0;
            y            <= '0;
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
