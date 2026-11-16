// Testbench timera: zezwolenie pseudolosowe, przeładowania period w trakcie pracy, porównanie z modelem w każdym takcie.
`timescale 1ns / 1ps

module tb_down_timer;
    localparam int W = 8;

    logic         clk = 1'b0, rst = 1'b1, en = 1'b0, load = 1'b0;
    logic [W-1:0] period = 8'd4, count;
    logic         tick;

    always #5 clk = ~clk;

    down_timer #(.W(W)) dut (.*);

    int errors = 0, ticks = 0;

    initial begin
        logic [W-1:0] m_count = '0;
        logic         m_tick  = 1'b0;
        logic [15:0]  lfsr    = 16'hBEEF;
        @(negedge clk);
        rst = 1'b0;
        for (int k = 0; k < 300; k++) begin
            if (count != m_count || tick != m_tick) begin
                $display("takt %0d: count=%0d tick=%b, model %0d %b", k, count, tick, m_count, m_tick); errors++;
            end
            ticks += tick;
            // nowe pobudzenia
            lfsr   = lfsr[0] ? ((lfsr >> 1) ^ 16'hB400) : (lfsr >> 1);
            en     = lfsr[0] | lfsr[1];                 // ok. 75% taktów z zezwoleniem
            load   = (k == 100 || k == 200);
            if (k == 100) period = 8'd2;
            if (k == 200) period = 8'd0;                // period = 0: tick w każdym takcie zezwolenia
            // model następnego stanu
            m_tick = 1'b0;
            if (load) m_count = period;
            else if (en) begin
                if (m_count == 0) begin m_count = period; m_tick = 1'b1; end
                else m_count--;
            end
            @(negedge clk);
        end
        if (ticks < 20) begin
            $display("za malo impulsow tick: %0d", ticks); errors++;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
