// Testbench timera: zezwolenie pseudolosowe, przeładowania period w trakcie pracy, porównanie z modelem.
`default_nettype none
`timescale 1ns / 1ps

module tb_down_timer;
    localparam integer W = 8;

    reg          clk = 1'b0, rst = 1'b1, en = 1'b0, load = 1'b0;
    reg  [W-1:0] period = 8'd4;
    wire [W-1:0] count;
    wire         tick;

    always #5 clk = ~clk;

    down_timer #(.W(W)) dut (.clk(clk), .rst(rst), .en(en), .load(load), .period(period), .count(count), .tick(tick));

    integer errors = 0, ticks = 0, k;
    reg [W-1:0] m_count = 0;
    reg         m_tick  = 1'b0;
    reg [15:0]  lfsr    = 16'hBEEF;

    initial begin
        @(negedge clk);
        rst = 1'b0;
        for (k = 0; k < 300; k = k + 1) begin
            if (count !== m_count || tick !== m_tick) begin
                $display("takt %0d: count=%0d tick=%b, model %0d %b", k, count, tick, m_count, m_tick); errors = errors + 1;
            end
            ticks = ticks + tick;
            lfsr = lfsr[0] ? ((lfsr >> 1) ^ 16'hB400) : (lfsr >> 1);
            en   = lfsr[0] | lfsr[1];
            load = (k == 100 || k == 200);
            if (k == 100) period = 8'd2;
            if (k == 200) period = 8'd0;
            m_tick = 1'b0;
            if (load) m_count = period;
            else if (en) begin
                if (m_count == 0) begin m_count = period; m_tick = 1'b1; end
                else m_count = m_count - 1;
            end
            @(negedge clk);
        end
        if (ticks < 20) begin
            $display("za malo impulsow tick: %0d", ticks); errors = errors + 1;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
