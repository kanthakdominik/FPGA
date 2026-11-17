// Testbench iloczyn_rown i iloczyn_szer: te same losowe wektory. Wersja równoległa — wynik po 2 taktach
// dla każdych danych; szeregowa — dane podawane, gdy ready = 1, wynik z done po 5 taktach od startu.
// Sprawdzane: wyniki zgodne z modelem, szeregowa daje wynik co 4 takty przy ciągłym starcie.
`timescale 1ns / 1ps
`default_nettype none

module tb_iloczyn;
    localparam N = 400;
    reg clk = 1'b0, rst = 1'b1;
    always #5 clk = ~clk;

    reg  [31:0] a = 32'd0, b = 32'd0;
    reg         vin = 1'b0, start = 1'b0;
    wire        vout, ready, done;
    wire [17:0] y_rown, y_szer;
    iloczyn_rown u_r (.clk(clk), .rst(rst), .in_valid(vin), .a(a), .b(b), .out_valid(vout), .y(y_rown));
    iloczyn_szer u_s (.clk(clk), .rst(rst), .start(start), .a(a), .b(b), .ready(ready), .done(done), .y(y_szer));

    function [17:0] model(input [31:0] fa, input [31:0] fb);
        integer k;
        begin
            model = 18'd0;
            for (k = 0; k < 4; k = k + 1) model = model + fa[8*k +: 8] * fb[8*k +: 8];
        end
    endfunction

    // kolejki oczekiwanych wyników
    reg [17:0] q_r [0:1023];
    reg [17:0] q_s [0:1023];
    integer wr_r = 0, rd_r = 0, wr_s = 0, rd_s = 0, errors = 0, takt = 0, t_done = 0, odst_ok = 0, odst = 0;

    always @(posedge clk) if (!rst) begin
        takt <= takt + 1;
        if (vin) begin q_r[wr_r % 1024] <= model(a, b); wr_r <= wr_r + 1; end
        if (start && ready) begin q_s[wr_s % 1024] <= model(a, b); wr_s <= wr_s + 1; end
    end

    always @(negedge clk) if (!rst) begin
        if (vout) begin
            if (y_rown !== q_r[rd_r % 1024]) begin
                $display("%0t: rownolegly y=%0d, oczekiwano %0d", $time, y_rown, q_r[rd_r % 1024]);
                errors = errors + 1;
            end
            rd_r = rd_r + 1;
        end
        if (done) begin
            if (y_szer !== q_s[rd_s % 1024]) begin
                $display("%0t: szeregowy y=%0d, oczekiwano %0d", $time, y_szer, q_s[rd_s % 1024]);
                errors = errors + 1;
            end
            if (rd_s > 0) begin
                odst = odst + 1;
                if (takt - t_done == 4) odst_ok = odst_ok + 1;
            end
            t_done = takt;
            rd_s = rd_s + 1;
        end
        // pobudzenia: losowe argumenty (czasem 255); start ciągły w drugiej połowie testu
        a = ($random % 6 == 0) ? 32'hFFFFFFFF : $random;
        b = ($random % 6 == 0) ? 32'hFFFFFFFF : $random;
        vin   = ($random % 3 != 0);
        start = (rd_s >= N / 2) ? 1'b1 : ($random % 3 == 0);
    end

    initial begin
        #23 rst = 1'b0;
        wait (rd_s >= N);
        @(negedge clk);
        $display("rownolegly: %0d wynikow, szeregowy: %0d wynikow; odstep 4 takty: %0d z %0d", rd_r, rd_s, odst_ok, odst);
        if (errors == 0 && rd_r > N && odst_ok >= N / 2 - 2) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #200000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule

`default_nettype wire
