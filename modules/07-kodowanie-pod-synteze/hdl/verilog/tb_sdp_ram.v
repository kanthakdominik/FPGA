// Testbench sdp_ram: wypełnienie całej pamięci, potem losowe zapisy i odczyty z modelem.
// Co ósmy takt odczyt spod adresu zapisywanego w tym samym takcie — oczekiwane stare dane.
`default_nettype none
`timescale 1ns / 1ps

module tb_sdp_ram;
    reg        clk = 1'b0, we = 1'b0;
    reg  [4:0] waddr = 5'd0, raddr = 5'd0;
    reg  [7:0] wdata = 8'h00;
    wire [7:0] rdata;

    always #5 clk = ~clk;

    sdp_ram #(.W(8), .AW(5)) dut (.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(raddr), .rdata(rdata));

    reg [7:0] model [0:31];
    reg [7:0] e;
    integer errors = 0, n, collisions = 0, seed = 9;

    initial begin
        for (n = 0; n < 32; n = n + 1) begin   // wypełnienie
            @(negedge clk);
            we = 1'b1; waddr = n; wdata = $random(seed);
            model[n] = wdata;
        end
        @(negedge clk) we = 1'b0;

        for (n = 0; n < 400; n = n + 1) begin
            we    = (($random(seed) & 1) != 0);
            waddr = $random(seed);
            wdata = $random(seed);
            raddr = (n % 8 == 0) ? waddr : $random(seed);
            if (n % 8 == 0) we = 1'b1;
            if (we && raddr == waddr) collisions = collisions + 1;
            e = model[raddr];                  // stan sprzed zapisu w tym takcie
            if (we) model[waddr] = wdata;
            @(negedge clk);
            if (rdata !== e) begin
                $display("takt %0d: raddr=%0d rdata=%h, oczekiwano %h", n, raddr, rdata, e); errors = errors + 1;
            end
        end

        if (collisions == 0) begin
            $display("test nie sprawdzil odczytu podczas zapisu"); errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
