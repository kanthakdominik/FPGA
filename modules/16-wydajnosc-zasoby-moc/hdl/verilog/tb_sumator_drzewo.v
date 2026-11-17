// Testbench sumator_drzewo: cztery warianty (PIPE/RET = 0/0, 1/0, 2/0, 0/2) na tych samych losowych
// danych. Sprawdzane: wynik = suma ośmiu wejść, opóźnienie dokładnie 2 + PIPE + RET taktów,
// wynik w każdym takcie (przepustowość 1), out_valid tylko dla danych z in_valid = 1.
`timescale 1ns / 1ps
`default_nettype none

module tb_sumator_drzewo;
    localparam W = 16, NCYK = 2000;
    reg clk = 1'b0, rst = 1'b1, in_valid = 1'b0;
    reg [8*W-1:0] x = {8*W{1'b0}};
    always #5 clk = ~clk;

    wire          v0, v1, v2, v3;
    wire [W+2:0]  y0, y1, y2, y3;
    sumator_drzewo #(.W(W), .PIPE(0), .RET(0)) u0 (.clk(clk), .rst(rst), .in_valid(in_valid), .x(x), .out_valid(v0), .y(y0));
    sumator_drzewo #(.W(W), .PIPE(1), .RET(0)) u1 (.clk(clk), .rst(rst), .in_valid(in_valid), .x(x), .out_valid(v1), .y(y1));
    sumator_drzewo #(.W(W), .PIPE(2), .RET(0)) u2 (.clk(clk), .rst(rst), .in_valid(in_valid), .x(x), .out_valid(v2), .y(y2));
    sumator_drzewo #(.W(W), .PIPE(0), .RET(2)) u3 (.clk(clk), .rst(rst), .in_valid(in_valid), .x(x), .out_valid(v3), .y(y3));

    // model: suma i ważność danych próbkowanych na zboczu numer n
    reg [W+2:0] exp_s [0:NCYK+15];
    reg         exp_v [0:NCYK+15];
    integer cyk = 0, errors = 0, nv0 = 0, nv1 = 0, nv2 = 0, nv3 = 0, nwe = 0, i;
    reg [W+2:0] s;

    always @(posedge clk) begin
        s = {(W+3){1'b0}};
        for (i = 0; i < 8; i = i + 1) s = s + {3'b000, x[i*W +: W]};
        exp_s[cyk] <= s;
        exp_v[cyk] <= in_valid && !rst;
        if (in_valid && !rst) nwe = nwe + 1;
        cyk <= cyk + 1;
    end

    task sprawdz(input integer lat, input v, input [W+2:0] y, inout integer nv);
        integer n;
        begin
            n = cyk - lat;                      // cyk już zwiększony na ostatnim zboczu
            if (n >= 0) begin
                if (v !== exp_v[n]) begin
                    $display("%0t: L=%0d out_valid=%b, oczekiwano %b", $time, lat, v, exp_v[n]);
                    errors = errors + 1;
                end
                if (v === 1'b1) begin
                    nv = nv + 1;
                    if (y !== exp_s[n]) begin
                        $display("%0t: L=%0d y=%0d, oczekiwano %0d", $time, lat, y, exp_s[n]);
                        errors = errors + 1;
                    end
                end
            end
        end
    endtask

    always @(negedge clk) begin
        if (!rst) begin
            sprawdz(2, v0, y0, nv0);
            sprawdz(3, v1, y1, nv1);
            sprawdz(4, v2, y2, nv2);
            sprawdz(4, v3, y3, nv3);
        end
        // nowe pobudzenia na opadającym zboczu; czasem same jedynki (najdłuższe przeniesienia)
        for (i = 0; i < 8; i = i + 1)
            x[i*W +: W] = ($random % 8 == 0) ? {W{1'b1}} : $random;
        in_valid = ($random % 4 != 0);
    end

    initial begin
        #23 rst = 1'b0;
        repeat (NCYK) @(posedge clk);
        @(negedge clk);
        $display("wyniki: L2 %0d, L3 %0d, L4 %0d, L4 (RET) %0d z %0d danych", nv0, nv1, nv2, nv3, nwe);
        if (errors == 0 && nv0 > NCYK / 2 && nv3 > NCYK / 2) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #100000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule

`default_nettype wire
