// Dekoder SECDED (39,32) (29.04): syndrom s (6 bitów) = XOR pozycji z ustawionym bitem k, parzystość całości.
//   s = 0, parzystość 0 — bez błędu;  parzystość 1 — błąd pojedynczy na pozycji s (s = 0: w bicie parzystości),
//   poprawiony;  s ≠ 0, parzystość 0 — błąd podwójny: wykryty, niepoprawialny (dane bez zmian).
`default_nettype none

module secded_dekoder (
    input  logic [38:0] c,
    output logic [31:0] d,
    output logic        poprawiony,
    output logic        podwojny
);
    function [5:0] syndrom(input [38:0] w);
        integer i, k;
        logic [5:0] s;
        begin
            s = 6'd0;
            for (k = 0; k < 6; k = k + 1)
                for (i = 1; i < 39; i = i + 1)
                    if (((i >> k) & 1) == 1) s[k] = s[k] ^ w[i];
            syndrom = s;
        end
    endfunction

    function [31:0] dane(input [38:0] w);
        integer i, j;
        logic [31:0] r;
        begin
            r = 32'd0;
            j = 0;
            for (i = 1; i < 39; i = i + 1)
                if ((i & (i - 1)) != 0) begin
                    r[j] = w[i];
                    j = j + 1;
                end
            dane = r;
        end
    endfunction

    logic [5:0]  s;
    assign s = syndrom(c);
    logic        par;
    assign par = ^c;
    /* verilator lint_off WIDTHEXPAND */
    logic [38:0] popr;
    assign popr = par ? c ^ ({38'd0, 1'b1} << s) : c;
    /* verilator lint_on WIDTHEXPAND */
    assign d          = dane(popr);
    assign poprawiony = par;
    assign podwojny   = !par && s != 6'd0;
endmodule

`default_nettype wire
