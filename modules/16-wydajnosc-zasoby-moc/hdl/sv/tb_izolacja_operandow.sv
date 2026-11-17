// Testbench izolacja_operandow: ISO = 0 i 1 na tym samym strumieniu (dane ważne co czwarty takt,
// w pozostałych śmieci). Sprawdzane: iloczyny zgodne z modelem; przełączenia bitów rejestru iloczynu
// w wersji z izolacją co najmniej 3 razy rzadsze.
`timescale 1ns / 1ps

module tb_izolacja_operandow;
    localparam int W = 16;
    logic clk = 1'b0, rst = 1'b1, vin = 1'b0, v0, v1;
    logic [W-1:0]   a = '0, b = '0;
    logic [2*W-1:0] p0, p1, p0_d = '0, p1_d = '0;
    always #5 clk = ~clk;

    izolacja_operandow #(.W(W), .ISO(1'b0)) u0 (.clk, .rst, .in_valid(vin), .a, .b, .out_valid(v0), .p(p0));
    izolacja_operandow #(.W(W), .ISO(1'b1)) u1 (.clk, .rst, .in_valid(vin), .a, .b, .out_valid(v1), .p(p1));

    logic [2*W-1:0] q [$];
    int errors = 0, n = 0, rd = 0, t0 = 0, t1 = 0;
    always @(posedge clk) if (!rst && vin) q.push_back((2*W)'(a) * (2*W)'(b));

    always @(negedge clk) begin
        if (!rst) begin
            if (v0 !== v1) begin $display("%0t: out_valid rozne", $time); errors++; end
            if (v0) begin
                if (q.size() == 0 || p0 !== q[0] || p1 !== q[0]) begin
                    $display("%0t: p0=%0d p1=%0d", $time, p0, p1); errors++;
                end
                if (q.size() > 0) void'(q.pop_front());
                rd++;
            end
            t0 += $countones(p0 ^ p0_d);
            t1 += $countones(p1 ^ p1_d);
            p0_d = p0;
            p1_d = p1;
        end
        n++;
        vin = (n % 4 == 0);
        a = W'($urandom);
        b = W'($urandom);
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
