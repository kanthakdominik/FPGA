// Testbench arbitra karuzelowego: losowe zgłoszenia porównane z modelem, potem rotacja przy pełnym obciążeniu.
`default_nettype none
`timescale 1ns / 1ps

module tb_rr_arbiter;
    reg        clk = 1'b0, rst = 1'b1;
    reg  [3:0] req = 4'b0000;
    wire [3:0] grant;
    wire [1:0] grant_idx;
    wire       grant_valid;

    always #5 clk = ~clk;

    rr_arbiter dut (.clk(clk), .rst(rst), .req(req), .grant(grant), .grant_idx(grant_idx), .grant_valid(grant_valid));

    integer errors = 0, k, s, last = 3;
    reg [3:0] e;
    reg [7:0] lfsr = 8'hC3;

    initial begin
        @(negedge clk);
        rst = 1'b0;
        for (k = 0; k < 200; k = k + 1) begin
            lfsr = lfsr[0] ? ((lfsr >> 1) ^ 8'hB8) : (lfsr >> 1);
            req  = (k >= 150) ? 4'b1111 : lfsr[3:0];
            #1;
            e = 4'b0000;
            for (s = 1; s <= 4; s = s + 1)
                if (e == 4'b0000 && req[(last + s) % 4]) e[(last + s) % 4] = 1'b1;
            if (grant !== e || grant_valid !== (e != 0) || (e != 0 && e[grant_idx] !== 1'b1)) begin
                $display("takt %0d: req=%b grant=%b idx=%0d, oczekiwano %b", k, req, grant, grant_idx, e); errors = errors + 1;
            end
            if (k >= 150 && grant_idx != (last + 1) % 4) begin
                $display("pelne obciazenie: brak rotacji w takcie %0d", k); errors = errors + 1;
            end
            if (e != 0) last = grant_idx;
            @(negedge clk);
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
