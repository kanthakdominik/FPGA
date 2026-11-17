// Testbench izolacja_operandow: obie wersje (ISO = 0 i 1) na tym samym strumieniu, w którym dane są
// ważne w co czwartym takcie, a w pozostałych na magistrali są losowe śmieci. Sprawdzane: iloczyny
// zgodne z modelem dla ważnych danych w obu wersjach; liczba przełączeń bitów rejestru iloczynu
// (miara mocy dynamicznej) w wersji z izolacją co najmniej 3 razy mniejsza.
`timescale 1ns / 1ps
`default_nettype none

module tb_izolacja_operandow;
    localparam W = 16;
    reg clk = 1'b0, rst = 1'b1, vin = 1'b0;
    reg [W-1:0] a = 0, b = 0;
    always #5 clk = ~clk;

    wire           v0, v1;
    wire [2*W-1:0] p0, p1;
    izolacja_operandow #(.W(W), .ISO(0)) u0 (.clk(clk), .rst(rst), .in_valid(vin), .a(a), .b(b), .out_valid(v0), .p(p0));
    izolacja_operandow #(.W(W), .ISO(1)) u1 (.clk(clk), .rst(rst), .in_valid(vin), .a(a), .b(b), .out_valid(v1), .p(p1));

    reg [2*W-1:0] q [0:4095];
    reg [2*W-1:0] p0_d = 0, p1_d = 0, x;
    integer wr = 0, rd = 0, errors = 0, n = 0, t0 = 0, t1 = 0, k;
    always @(posedge clk) if (!rst && vin) begin
        q[wr % 4096] <= a * b;
        wr <= wr + 1;
    end

    always @(negedge clk) begin
        if (!rst) begin
            if (v0 !== v1) begin $display("%0t: out_valid rozne", $time); errors = errors + 1; end
            if (v0) begin
                if (p0 !== q[rd % 4096] || p1 !== q[rd % 4096]) begin
                    $display("%0t: p0=%0d p1=%0d, oczekiwano %0d", $time, p0, p1, q[rd % 4096]);
                    errors = errors + 1;
                end
                rd = rd + 1;
            end
            // przełączenia bitów rejestru iloczynu
            x = p0 ^ p0_d; for (k = 0; k < 2*W; k = k + 1) if (x[k] === 1'b1) t0 = t0 + 1;
            x = p1 ^ p1_d; for (k = 0; k < 2*W; k = k + 1) if (x[k] === 1'b1) t1 = t1 + 1;
            p0_d = p0;
            p1_d = p1;
        end
        n = n + 1;
        vin = (n % 4 == 0);
        a = $random;
        b = $random;
    end

    initial begin
        #23 rst = 1'b0;
        wait (n == 4000);
        $display("iloczynow: %0d; przelaczen bitow iloczynu: bez izolacji %0d, z izolacja %0d", rd, t0, t1);
        if (errors == 0 && rd > 900 && t1 * 3 < t0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #100000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule

`default_nettype wire
