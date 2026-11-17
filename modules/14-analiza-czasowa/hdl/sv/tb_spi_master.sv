// Testbench spi_master (DIV = 2): 100 bajtów z modelem urządzenia podrzędnego SPI w trybie 0.
// Sprawdzane: bajt odebrany przez urządzenie = wysłany, bajt odebrany przez nadajnik = wysłany przez
// urządzenie, okres sclk = 2·DIV taktów, MOSI stabilne co najmniej pół okresu przed i po narastającym
// zboczu sclk (zapas setup i hold po stronie urządzenia), sclk = 0 przy aktywacji cs_n.
`timescale 1ns / 1ps

module tb_spi_master;
    localparam int DIV = 2;
    localparam realtime TCLK = 10ns, HALF = DIV * TCLK;
    logic       clk = 1'b0, rst = 1'b1, start = 1'b0, miso = 1'b0;
    logic [7:0] tx = '0, rx;
    logic       busy, done, sclk, mosi, cs_n;
    int         errors = 0, n_bits = 0;

    always #5 clk = ~clk;

    spi_master #(.DIV(DIV)) dut (.*);

    // ---- model urządzenia podrzędnego ----
    logic [7:0] s_tx = '0, s_sh, s_rx;
    realtime    t_mosi = 0, t_rise = 0;

    always @(negedge cs_n) begin
        if (sclk !== 1'b0) begin $display("%0t: sclk=1 przy aktywacji cs_n", $time); errors++; end
        s_sh   = s_tx;
        miso   = s_sh[7];
        n_bits = 0;
        t_rise = 0;
        t_mosi = $realtime;                        // pierwszy bit ustawiany razem z cs_n
    end
    always @(posedge sclk) if (!cs_n) begin
        if ($realtime - t_mosi < HALF) begin $display("%0t: MOSI zmienione za pozno (setup)", $time); errors++; end
        if (t_rise != 0 && $realtime - t_rise != 2 * HALF) begin
            $display("%0t: zly okres sclk", $time); errors++;
        end
        t_rise = $realtime;
        s_rx   = {s_rx[6:0], mosi};
        n_bits++;
    end
    always @(negedge sclk) if (!cs_n) begin
        s_sh = {s_sh[6:0], 1'b0};
        miso = s_sh[7];
    end
    always @(mosi) if (!cs_n) begin
        if (t_rise != 0 && $realtime - t_rise < HALF) begin $display("%0t: MOSI zmienione za wczesnie (hold)", $time); errors++; end
        t_mosi = $realtime;
    end

    initial begin
        repeat (2) @(negedge clk);
        rst = 1'b0;
        for (int k = 0; k < 100; k++) begin
            tx    = 8'($urandom);
            s_tx  = 8'($urandom);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            wait (done);
            @(negedge clk);
            if (rx !== s_tx || s_rx !== tx || n_bits != 8) begin
                $display("bajt %0d: wyslano %h odebrano w urzadzeniu %h (%0d bitow); urzadzenie %h, odebrano %h",
                         k, tx, s_rx, n_bits, s_tx, rx);
                errors++;
            end
            repeat ($urandom_range(3)) @(negedge clk);
        end
        $display("bajtow: 100, okres sclk: %0d ns", 2 * DIV * 10);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
