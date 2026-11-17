// Testbench dzielnik_mc: 300 dzieleń z losowymi argumentami (5 % z dzielnikiem 0), start także w trakcie
// pracy (musi być zignorowany). Sprawdzane: wynik, opóźnienie dokładnie N taktów, q i r zmieniają się
// tylko w takcie z done = 1 (warunek, na którym opiera się ograniczenie wielotaktowe).
`default_nettype none
`timescale 1ns / 1ps

module tb_dzielnik_mc;
    localparam W = 16, V = 8, N = 4;
    reg          clk = 1'b0, rst = 1'b1, start = 1'b0;
    reg  [W-1:0] a = 16'd0, ea, eq, q_prev;
    reg  [V-1:0] b = 8'd0, eb, er, r_prev;
    wire [W-1:0] q;
    wire [V-1:0] r;
    wire         busy, done;
    integer      errors = 0, n_zero = 0, n_ignored = 0, n_one = 0, k, lat, seed = 14;

    always #5 clk = ~clk;

    dzielnik_mc #(.W(W), .V(V), .N(N)) dut (.clk(clk), .rst(rst), .start(start), .a(a), .b(b), .busy(busy),
                                            .done(done), .q(q), .r(r));

    always @(negedge clk) begin
        if (!rst && !done && (q !== q_prev || r !== r_prev)) begin
            $display("%0t: q/r zmienione bez done", $time);
            errors = errors + 1;
        end
        q_prev <= q;
        r_prev <= r;
    end

    initial begin
        repeat (2) @(negedge clk);
        rst = 1'b0;
        for (k = 0; k < 300; k = k + 1) begin
            ea = $random(seed);
            eb = ($unsigned($random(seed)) % 20 == 0) ? 8'd0 : $random(seed);
            if (k % 50 == 7) eb = 8'd1;
            if (eb == 0) n_zero = n_zero + 1;
            if (eb == 1) n_one = n_one + 1;
            eq = (eb == 0) ? {W{1'b1}} : ea / {8'd0, eb};
            er = (eb == 0) ? ea[V-1:0] : ea % {8'd0, eb};
            a = ea; b = eb; start = 1'b1;
            @(negedge clk);
            if (!busy) begin $display("op %0d: start nieprzyjety", k); errors = errors + 1; end
            lat = 0;
            while (lat == 0 || (!done && lat < N + 2)) begin
                start = ($unsigned($random(seed)) % 4 == 0);
                if (start) begin a = $random(seed); b = $random(seed); n_ignored = n_ignored + 1; end
                @(negedge clk);
                lat = lat + 1;
            end
            start = 1'b0;
            if (lat != N || q !== eq || r !== er) begin
                $display("op %0d: %0d / %0d -> q=%0d r=%0d po %0d taktach, oczekiwano %0d %0d po %0d",
                         k, ea, eb, q, r, lat, eq, er, N);
                errors = errors + 1;
            end
            repeat ($unsigned($random(seed)) % 3) @(negedge clk);
        end
        if (n_zero == 0 || n_ignored == 0 || n_one == 0) begin
            $display("pokrycie: b=0 %0d, b=1 %0d, start zignorowany %0d", n_zero, n_one, n_ignored);
            errors = errors + 1;
        end
        $display("dzielen: 300, z b=0: %0d, startow zignorowanych: %0d", n_zero, n_ignored);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
