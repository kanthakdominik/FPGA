// Testbench sdp_ram: wypełnienie całej pamięci, potem losowe zapisy i odczyty z modelem.
// Co ósmy takt odczyt spod adresu zapisywanego w tym samym takcie — oczekiwane stare dane.
`timescale 1ns / 1ps

module tb_sdp_ram;
    logic       clk = 1'b0, we = 1'b0;
    logic [4:0] waddr = '0, raddr = '0;
    logic [7:0] wdata = '0, rdata;

    always #5 clk = ~clk;

    sdp_ram #(.W(8), .AW(5)) dut (.*);

    logic [7:0] model [32];
    int errors = 0, collisions = 0;

    initial begin
        for (int n = 0; n < 32; n++) begin     // wypełnienie
            @(negedge clk);
            we = 1'b1; waddr = 5'(n); wdata = 8'($urandom);
            model[n] = wdata;
        end
        @(negedge clk) we = 1'b0;

        for (int n = 0; n < 400; n++) begin
            logic [7:0] e;
            we    = ($urandom_range(1) != 0) || (n % 8 == 0);
            waddr = 5'($urandom);
            wdata = 8'($urandom);
            raddr = (n % 8 == 0) ? waddr : 5'($urandom);
            if (we && raddr == waddr) collisions++;
            e = model[raddr];                  // stan sprzed zapisu w tym takcie
            if (we) model[waddr] = wdata;
            @(negedge clk);
            if (rdata != e) begin
                $display("takt %0d: raddr=%0d rdata=%h, oczekiwano %h", n, raddr, rdata, e); errors++;
            end
        end

        if (collisions == 0) begin
            $display("test nie sprawdzil odczytu podczas zapisu"); errors++;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
