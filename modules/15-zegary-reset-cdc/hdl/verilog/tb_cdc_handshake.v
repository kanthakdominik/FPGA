// Testbench cdc_handshake: 200 słów w każdym kierunku (100 MHz -> 36,6 MHz i odwrotnie), wysyłane losowo,
// gdy ready = 1. Sprawdzane: kolejność i wartości słów po stronie docelowej, dst_data zmienia się tylko
// razem z dst_valid.
`default_nettype none
`timescale 1ns / 1ps

module tb_cdc_handshake;
    localparam W = 8;
    reg clk_f = 1'b0, clk_s = 1'b0, rst = 1'b1;
    always #5     clk_f = ~clk_f;
    always #13.65 clk_s = ~clk_s;

    reg          s1 = 1'b0, s2 = 1'b0;
    reg  [W-1:0] d1 = 8'd0, d2 = 8'd0;
    wire         r1, v1, r2, v2;
    wire [W-1:0] o1, o2;
    cdc_handshake #(.W(W)) u1 (.clk_src(clk_f), .rst_src(rst), .send(s1), .src_data(d1), .ready(r1),
                               .clk_dst(clk_s), .rst_dst(rst), .dst_valid(v1), .dst_data(o1));
    cdc_handshake #(.W(W)) u2 (.clk_src(clk_s), .rst_src(rst), .send(s2), .src_data(d2), .ready(r2),
                               .clk_dst(clk_f), .rst_dst(rst), .dst_valid(v2), .dst_data(o2));

    // kolejki oczekiwanych słów (bufory cykliczne)
    reg [W-1:0] q1 [0:255], q2 [0:255];
    integer w1 = 0, rd1 = 0, w2 = 0, rd2 = 0, errors = 0, seed = 7;
    reg [W-1:0] o1_p = 8'd0, o2_p = 8'd0;

    always @(negedge clk_f) begin
        s1 <= !rst && r1 && ($unsigned($random(seed)) % 3 == 0);
        d1 <= $random(seed);
    end
    always @(posedge clk_f) if (!rst && s1 && r1) begin q1[w1 % 256] = d1; w1 = w1 + 1; end
    always @(negedge clk_s) begin
        s2 <= !rst && r2 && (($random(seed) & 1) == 0);
        d2 <= $random(seed);
    end
    always @(posedge clk_s) if (!rst && s2 && r2) begin q2[w2 % 256] = d2; w2 = w2 + 1; end

    always @(negedge clk_s) if (!rst) begin
        if (v1) begin
            if (rd1 >= w1 || o1 !== q1[rd1 % 256]) begin $display("%0t: u1 odebrano %h", $time, o1); errors = errors + 1; end
            rd1 = rd1 + 1;
        end else if (rd1 > 0 && o1 !== o1_p) begin $display("%0t: u1 dane bez valid", $time); errors = errors + 1; end
        o1_p = o1;
    end
    always @(negedge clk_f) if (!rst) begin
        if (v2) begin
            if (rd2 >= w2 || o2 !== q2[rd2 % 256]) begin $display("%0t: u2 odebrano %h", $time, o2); errors = errors + 1; end
            rd2 = rd2 + 1;
        end else if (rd2 > 0 && o2 !== o2_p) begin $display("%0t: u2 dane bez valid", $time); errors = errors + 1; end
        o2_p = o2;
    end

    initial begin
        #100 rst = 1'b0;
        wait (rd1 >= 200 && rd2 >= 200);
        $display("slow odebranych: szybki->wolny %0d, wolny->szybki %0d", rd1, rd2);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #500000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule

`default_nettype wire
