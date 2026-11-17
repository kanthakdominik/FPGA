// Testbench dzielnik_mc: 300 dzieleń z losowymi argumentami (5 % z dzielnikiem 0), start także w trakcie
// pracy (musi być zignorowany). Sprawdzane: wynik, opóźnienie dokładnie N taktów, q i r zmieniają się
// tylko w takcie z done = 1 (warunek, na którym opiera się ograniczenie wielotaktowe).
`timescale 1ns / 1ps

module tb_dzielnik_mc;
    localparam int W = 16, V = 8, N = 4;
    logic         clk = 1'b0, rst = 1'b1, start = 1'b0;
    logic [W-1:0] a = '0, q, q_prev;
    logic [V-1:0] b = '0, r, r_prev;
    logic         busy, done;
    int           errors = 0, n_zero = 0, n_ignored = 0, n_one = 0;

    always #5 clk = ~clk;

    dzielnik_mc #(.W(W), .V(V), .N(N)) dut (.*);

    // wynik zmienia się tylko razem z done
    always @(negedge clk) begin
        if (!rst && !done && (q !== q_prev || r !== r_prev)) begin
            $display("%0t: q/r zmienione bez done", $time);
            errors++;
        end
        q_prev <= q;
        r_prev <= r;
    end

    initial begin
        logic [W-1:0] ea, eq;
        logic [V-1:0] eb, er;
        int           lat;
        repeat (2) @(negedge clk);
        rst = 1'b0;
        for (int k = 0; k < 300; k++) begin
            ea = W'($urandom);
            eb = ($urandom_range(19) == 0) ? '0 : V'($urandom);
            if (k % 50 == 7) eb = 8'd1;
            if (eb == 0) n_zero++;
            if (eb == 1) n_one++;
            eq = (eb == 0) ? '1 : ea / W'(eb);
            er = (eb == 0) ? V'(ea) : V'(ea % W'(eb));
            a = ea; b = eb; start = 1'b1;
            @(negedge clk);
            if (!busy) begin $display("op %0d: start nieprzyjety", k); errors++; end
            lat = 0;
            do begin
                start = ($urandom_range(3) == 0);           // start w trakcie pracy — ignorowany
                if (start) begin a = W'($urandom); b = V'($urandom); n_ignored++; end
                @(negedge clk);
                lat++;
            end while (!done && lat < N + 2);
            start = 1'b0;
            if (lat != N || q !== eq || r !== er) begin
                $display("op %0d: %0d / %0d -> q=%0d r=%0d po %0d taktach, oczekiwano %0d %0d po %0d",
                         k, ea, eb, q, r, lat, eq, er, N);
                errors++;
            end
            repeat ($urandom_range(2)) @(negedge clk);
        end
        if (n_zero == 0 || n_ignored == 0 || n_one == 0) begin
            $display("pokrycie: b=0 %0d, b=1 %0d, start zignorowany %0d", n_zero, n_one, n_ignored);
            errors++;
        end
        $display("dzielen: 300, z b=0: %0d, startow zignorowanych: %0d", n_zero, n_ignored);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
