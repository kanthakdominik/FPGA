// Testbench cdc_handshake: 200 słów w każdym kierunku (100 MHz -> 36,6 MHz i odwrotnie), wysyłane losowo,
// gdy ready = 1. Sprawdzane: kolejność i wartości słów po stronie docelowej, dst_valid trwa 1 takt,
// dst_data zmienia się tylko razem z dst_valid.
`timescale 1ns / 1ps

module tb_cdc_handshake;
    localparam int W = 8;
    logic clk_f = 1'b0, clk_s = 1'b0, rst = 1'b1;
    always #5     clk_f = ~clk_f;
    always #13.65 clk_s = ~clk_s;

    logic         s1 = 1'b0, r1, v1, s2 = 1'b0, r2, v2;
    logic [W-1:0] d1 = '0, o1, d2 = '0, o2;
    cdc_handshake #(.W(W)) u1 (.clk_src(clk_f), .rst_src(rst), .send(s1), .src_data(d1), .ready(r1),
                               .clk_dst(clk_s), .rst_dst(rst), .dst_valid(v1), .dst_data(o1));
    cdc_handshake #(.W(W)) u2 (.clk_src(clk_s), .rst_src(rst), .send(s2), .src_data(d2), .ready(r2),
                               .clk_dst(clk_f), .rst_dst(rst), .dst_valid(v2), .dst_data(o2));

    logic [W-1:0] q1 [$], q2 [$];
    int errors = 0, n1 = 0, n2 = 0;

    // nadawcy
    always @(negedge clk_f) begin
        s1 <= !rst && r1 && ($urandom_range(2) == 0);
        d1 <= W'($urandom);
    end
    always @(posedge clk_f) if (!rst && s1 && r1) q1.push_back(d1);
    always @(negedge clk_s) begin
        s2 <= !rst && r2 && ($urandom_range(1) == 0);
        d2 <= W'($urandom);
    end
    always @(posedge clk_s) if (!rst && s2 && r2) q2.push_back(d2);

    // odbiorcy
    logic [W-1:0] o1_p, o2_p;
    always @(negedge clk_s) if (!rst) begin
        if (v1) begin
            if (q1.size() == 0 || o1 !== q1[0]) begin $display("%0t: u1 odebrano %h", $time, o1); errors++; end
            else void'(q1.pop_front());
            n1++;
        end else if (n1 > 0 && o1 !== o1_p) begin $display("%0t: u1 dane zmienione bez valid", $time); errors++; end
        o1_p = o1;
    end
    always @(negedge clk_f) if (!rst) begin
        if (v2) begin
            if (q2.size() == 0 || o2 !== q2[0]) begin $display("%0t: u2 odebrano %h", $time, o2); errors++; end
            else void'(q2.pop_front());
            n2++;
        end else if (n2 > 0 && o2 !== o2_p) begin $display("%0t: u2 dane zmienione bez valid", $time); errors++; end
        o2_p = o2;
    end

    initial begin
        #100 rst = 1'b0;
        wait (n1 >= 200 && n2 >= 200);
        $display("slow odebranych: szybki->wolny %0d, wolny->szybki %0d", n1, n2);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #500000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule
