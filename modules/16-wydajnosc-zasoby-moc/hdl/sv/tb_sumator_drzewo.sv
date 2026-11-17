// Testbench sumator_drzewo: cztery warianty (PIPE/RET = 0/0, 1/0, 2/0, 0/2) na tych samych danych.
// Sprawdzane: wynik = suma ośmiu wejść, opóźnienie dokładnie 2 + PIPE + RET taktów, wynik w każdym
// takcie, out_valid tylko dla danych z in_valid = 1.
`timescale 1ns / 1ps

module tb_sumator_drzewo;
    localparam int W = 16, NCYK = 2000, NW = 4;
    localparam int LAT [NW] = '{2, 3, 4, 4};
    logic clk = 1'b0, rst = 1'b1, in_valid = 1'b0;
    logic [8*W-1:0] x = '0;
    always #5 clk = ~clk;

    logic         v [NW];
    logic [W+2:0] y [NW];
    sumator_drzewo #(.W(W), .PIPE(0), .RET(0)) u0 (.clk, .rst, .in_valid, .x, .out_valid(v[0]), .y(y[0]));
    sumator_drzewo #(.W(W), .PIPE(1), .RET(0)) u1 (.clk, .rst, .in_valid, .x, .out_valid(v[1]), .y(y[1]));
    sumator_drzewo #(.W(W), .PIPE(2), .RET(0)) u2 (.clk, .rst, .in_valid, .x, .out_valid(v[2]), .y(y[2]));
    sumator_drzewo #(.W(W), .PIPE(0), .RET(2)) u3 (.clk, .rst, .in_valid, .x, .out_valid(v[3]), .y(y[3]));

    logic [W+2:0] exp_s [NCYK + 16];
    logic         exp_v [NCYK + 16];
    int cyk = 0, errors = 0, nwe = 0;
    int nv [NW] = '{default: 0};

    always @(posedge clk) begin
        logic [W+2:0] s;
        s = '0;
        for (int i = 0; i < 8; i++) s += (W+3)'(x[i*W +: W]);
        exp_s[cyk] <= s;
        exp_v[cyk] <= in_valid && !rst;
        if (in_valid && !rst) nwe++;
        cyk <= cyk + 1;
    end

    always @(negedge clk) begin
        if (!rst)
            for (int j = 0; j < NW; j++) begin
                int n;
                n = cyk - LAT[j];
                if (n >= 0) begin
                    if (v[j] !== exp_v[n]) begin
                        $display("%0t: L=%0d out_valid=%b, oczekiwano %b", $time, LAT[j], v[j], exp_v[n]);
                        errors++;
                    end
                    if (v[j] === 1'b1) begin
                        nv[j]++;
                        if (y[j] !== exp_s[n]) begin
                            $display("%0t: L=%0d y=%0d, oczekiwano %0d", $time, LAT[j], y[j], exp_s[n]);
                            errors++;
                        end
                    end
                end
            end
        for (int i = 0; i < 8; i++)
            x[i*W +: W] = ($urandom_range(7) == 0) ? '1 : W'($urandom);
        in_valid = ($urandom_range(3) != 0);
    end

    initial begin
        #23 rst = 1'b0;
        repeat (NCYK) @(posedge clk);
        @(negedge clk);
        $display("wyniki: L2 %0d, L3 %0d, L4 %0d, L4 (RET) %0d z %0d danych", nv[0], nv[1], nv[2], nv[3], nwe);
        if (errors == 0 && nv[0] > NCYK / 2 && nv[3] > NCYK / 2) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #100000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule
