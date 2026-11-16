// Testbench samosprawdzający: dioda musi zmieniać stan dokładnie co HALF taktów.
`default_nettype none
`timescale 1ns / 1ps

module tb_blink;
    localparam integer CLK_HZ   = 1000;
    localparam integer BLINK_HZ = 50;
    localparam integer HALF     = CLK_HZ / (2 * BLINK_HZ);  // 10 taktów

    reg  clk = 1'b0;
    reg  rst = 1'b1;
    wire led;

    blink #(.CLK_HZ(CLK_HZ), .BLINK_HZ(BLINK_HZ)) dut (
        .clk(clk), .rst(rst), .led(led)
    );

    always #5 clk = ~clk;

    integer i, cycles, errors;
    reg     prev;

    initial begin
        errors = 0;
        // pobudzenia zmieniamy na opadającym zboczu — bez wyścigu z układem badanym
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        #1;
        if (led !== 1'b0) errors = errors + 1;
        // pomiar odstępu między pięcioma kolejnymi zmianami stanu
        for (i = 0; i < 5; i = i + 1) begin
            prev   = led;
            cycles = 0;
            while (led === prev && cycles <= 4 * HALF) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
            end
            if (cycles != HALF) begin
                $display("zmiana stanu po %0d taktach, oczekiwano %0d", cycles, HALF);
                errors = errors + 1;
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

`default_nettype wire
