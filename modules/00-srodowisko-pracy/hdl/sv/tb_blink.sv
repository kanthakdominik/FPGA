// Testbench samosprawdzający: dioda musi zmieniać stan dokładnie co HALF taktów.
`timescale 1ns / 1ps

module tb_blink;
    localparam int unsigned CLK_HZ   = 1000;
    localparam int unsigned BLINK_HZ = 50;
    localparam int unsigned HALF     = CLK_HZ / (2 * BLINK_HZ);  // 10 taktów

    logic clk = 1'b0;
    logic rst = 1'b1;
    logic led;

    blink #(.CLK_HZ(CLK_HZ), .BLINK_HZ(BLINK_HZ)) dut (.*);

    always #5 clk = ~clk;

    initial begin
        int   errors = 0;
        int   cycles;
        logic prev;

        // pobudzenia zmieniamy na opadającym zboczu — bez wyścigu z układem badanym
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        #1;
        if (led !== 1'b0) errors++;
        // pomiar odstępu między pięcioma kolejnymi zmianami stanu
        repeat (5) begin
            prev   = led;
            cycles = 0;
            while (led === prev && cycles <= 4 * HALF) begin
                @(posedge clk);
                #1;
                cycles++;
            end
            if (cycles != HALF) begin
                $display("zmiana stanu po %0d taktach, oczekiwano %0d", cycles, HALF);
                errors++;
            end
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end

    // zapis przebiegów: iverilog -DDUMP … / verilator --trace -DDUMP … (moduł 00.05)
`ifdef DUMP
    initial begin
        $dumpfile("tb_blink.vcd");
        $dumpvars(0, tb_blink);
    end
`endif

    // watchdog
    initial begin
        #100000;
        $display("FAIL: przekroczony czas symulacji");
        $finish;
    end
endmodule
