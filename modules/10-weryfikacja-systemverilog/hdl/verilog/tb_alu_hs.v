// Testbench alu_hs: losowe operacje z wartościami brzegowymi, losowe wstrzymanie po stronie wyjścia
// (z okresem silnego przeciążenia), potem pełna przepustowość i opróżnianie. Model liczy na liczbach
// całkowitych, niezależnie od kodu układu. Sprawdzane: wynik i flagi każdej operacji, stabilność wyjść
// przy wstrzymaniu, brak przyjęcia przy zajętym rejestrze, in_ready = 1 przy pełnym przepływie,
// pokrycie: każdy kod op, SUB z a == b, przeniesienie, pożyczka, wynik zero.
`default_nettype none
`timescale 1ns / 1ps

module tb_alu_hs;
    localparam W = 8;
    reg          clk = 1'b0, rst = 1'b1, in_valid = 1'b0, out_ready = 1'b0;
    wire         in_ready, out_valid, carry, zero, err;
    reg  [2:0]   op = 3'd0;
    reg  [W-1:0] a = 0, b = 0;
    wire [W-1:0] res;

    always #5 clk = ~clk;

    alu_hs #(.W(W)) dut (.clk(clk), .rst(rst), .in_valid(in_valid), .in_ready(in_ready), .op(op), .a(a), .b(b),
                         .out_valid(out_valid), .out_ready(out_ready), .res(res), .carry(carry), .zero(zero),
                         .err(err));

    // model: {err, zero, carry, res} liczony na liczbach całkowitych
    function [W+2:0] model;
        input integer o, x, y;
        integer r, c, e, m, sh;
        begin
            r = 0; c = 0; e = 0; m = 1 << W; sh = y % W;
            case (o)
                0: begin r = (x + y) % m; c = (x + y >= m); end
                1: begin r = (x - y + m) % m; c = (x < y); end
                2: r = x & y;
                3: r = x | y;
                4: r = x ^ y;
                5: r = (x * (1 << sh)) % m;
                6: r = x / (1 << sh);
                default: e = 1;
            endcase
            model = {e[0], r == 0, c[0], r[W-1:0]};
        end
    endfunction

    integer seed = 101;

    function [W-1:0] operand;
        input integer dummy;
        begin
            case ($random(seed) & 7)
                0:       operand = {W{1'b0}};
                1:       operand = {W{1'b1}};
                2:       operand = 1;
                default: operand = $random(seed);
            endcase
        end
    endfunction

    reg  [W+2:0] exp_q, held;
    reg          has_exp = 1'b0, stalled = 1'b0, pending = 1'b0;
    integer      errors = 0, nin = 0, nout = 0, backpressure = 0, n, i;
    integer      ops [0:7];
    integer      sub_eq = 0, n_carry = 0, n_borrow = 0, n_zero = 0;

    initial begin
        for (i = 0; i < 8; i = i + 1) ops[i] = 0;
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (n = 0; n < 3000; n = n + 1) begin
            // 1. stabilność: wynik niewzięty w poprzednim takcie stoi bez zmian
            if (stalled && (out_valid !== 1'b1 || {err, zero, carry, res} !== held)) begin
                $display("takt %0d: zmiana wyjsc podczas wstrzymania", n); errors = errors + 1;
            end
            // 2. pobudzenia
            if (n < 1000)      out_ready = $random(seed) & 1;
            else if (n < 1500) out_ready = (($random(seed) & 7) == 0);     // silne przeciążenie
            else               out_ready = 1'b1;
            if (!pending) begin                                            // poprzednia operacja przyjęta
                in_valid = (n >= 2900) ? 1'b0 : (n >= 1500) ? 1'b1 : (($random(seed) & 3) != 0);
                op       = $random(seed);
                a        = operand(0);
                b        = (($random(seed) & 7) == 0) ? a : operand(0);    // co ósma: a == b
            end
            #1;
            // 3. przesłania w tym takcie: najpierw wyjście (stary wynik), potem wejście (nowy)
            if (out_valid !== has_exp) begin
                $display("takt %0d: out_valid=%b, oczekiwano %b", n, out_valid, has_exp); errors = errors + 1;
            end
            if (out_valid && out_ready) begin
                if ({err, zero, carry, res} !== exp_q) begin
                    $display("takt %0d: err/zero/carry/res = %b, oczekiwano %b", n, {err, zero, carry, res}, exp_q);
                    errors = errors + 1;
                end
                has_exp = 1'b0;
                nout = nout + 1;
            end
            if (in_valid && in_ready) begin
                if (has_exp) begin
                    $display("takt %0d: przyjecie przy zajetym rejestrze wyjsciowym", n); errors = errors + 1;
                end
                exp_q   = model(op, a, b);
                has_exp = 1'b1;
                nin     = nin + 1;
                ops[op] = ops[op] + 1;
                if (op == 1 && a == b)  sub_eq   = sub_eq + 1;
                if (op == 0 && exp_q[W]) n_carry  = n_carry + 1;
                if (op == 1 && exp_q[W]) n_borrow = n_borrow + 1;
                if (exp_q[W+1])          n_zero   = n_zero + 1;
            end
            if (n >= 1500 && n < 2900 && !in_ready) begin
                $display("takt %0d: in_ready = 0 przy pelnym przeplywie", n); errors = errors + 1;
            end
            pending = in_valid && !in_ready;  // źródło trzyma operację do przyjęcia
            if (out_valid && !out_ready) backpressure = backpressure + 1;
            stalled = out_valid && !out_ready;
            held    = {err, zero, carry, res};
            @(negedge clk);
        end

        if (has_exp || nout != nin) begin
            $display("przyjeto %0d, odebrano %0d", nin, nout); errors = errors + 1;
        end
        for (i = 0; i < 8; i = i + 1)
            if (ops[i] == 0) begin
                $display("pokrycie: brak operacji op=%0d", i); errors = errors + 1;
            end
        if (sub_eq == 0 || n_carry == 0 || n_borrow == 0 || n_zero == 0 || backpressure == 0) begin
            $display("pokrycie: sub_eq=%0d carry=%0d borrow=%0d zero=%0d wstrzymania=%0d",
                     sub_eq, n_carry, n_borrow, n_zero, backpressure);
            errors = errors + 1;
        end
        $display("operacji: %0d, wstrzyman: %0d", nout, backpressure);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
