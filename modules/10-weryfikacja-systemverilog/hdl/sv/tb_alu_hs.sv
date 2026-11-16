// Testbench alu_hs (bez klas — wersja „z modułu 09”): losowe operacje z wartościami brzegowymi, losowe
// wstrzymanie po stronie wyjścia (z okresem silnego przeciążenia), potem pełna przepustowość i opróżnianie.
// Model liczy na liczbach całkowitych, niezależnie od kodu układu. Sprawdzane: wynik i flagi każdej
// operacji, stabilność wyjść przy wstrzymaniu, brak przyjęcia przy zajętym rejestrze, in_ready = 1
// przy pełnym przepływie, pokrycie: każdy kod op, SUB z a == b, przeniesienie, pożyczka, wynik zero.
`timescale 1ns / 1ps

module tb_alu_hs;
    localparam int W = 8;
    logic         clk = 1'b0, rst = 1'b1, in_valid = 1'b0, out_ready = 1'b0;
    logic         in_ready, out_valid, carry, zero, err;
    logic [2:0]   op = '0;
    logic [W-1:0] a = '0, b = '0, res;

    always #5 clk = ~clk;

    alu_hs #(.W(W)) dut (.*);

    // model: {err, zero, carry, res} liczony na liczbach całkowitych
    function automatic logic [W+2:0] model(int o, int x, int y);
        int r = 0, c = 0, e = 0, m = 1 << W, sh = y % W;
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
        return {1'(e), 1'(r == 0), 1'(c), W'(r)};
    endfunction

    function automatic logic [W-1:0] operand();
        case ($urandom_range(7))
            0: return '0;
            1: return '1;
            2: return W'(1);
            default: return W'($urandom);
        endcase
    endfunction

    logic [W+2:0] exp_q, held;
    logic         has_exp = 1'b0, stalled = 1'b0, pending = 1'b0;
    int           errors = 0, nin = 0, nout = 0, backpressure = 0;
    int           ops [8] = '{default: 0};
    int           sub_eq = 0, n_carry = 0, n_borrow = 0, n_zero = 0;

    initial begin
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (int n = 0; n < 3000; n++) begin
            // 1. stabilność: wynik niewzięty w poprzednim takcie stoi bez zmian
            if (stalled && (out_valid !== 1'b1 || {err, zero, carry, res} !== held)) begin
                $display("takt %0d: zmiana wyjsc podczas wstrzymania", n); errors++;
            end
            // 2. pobudzenia
            if (n < 1000)      out_ready = 1'($urandom);
            else if (n < 1500) out_ready = ($urandom_range(7) == 0);        // silne przeciążenie
            else               out_ready = 1'b1;
            if (!pending) begin                                             // poprzednia operacja przyjęta
                in_valid = (n >= 2900) ? 1'b0 : (n >= 1500) ? 1'b1 : ($urandom_range(3) != 0);
                op       = 3'($urandom);
                a        = operand();
                b        = ($urandom_range(7) == 0) ? a : operand();       // co ósma: a == b
            end
            #1;
            // 3. przesłania w tym takcie: najpierw wyjście (stary wynik), potem wejście (nowy)
            if (out_valid !== has_exp) begin
                $display("takt %0d: out_valid=%b, oczekiwano %b", n, out_valid, has_exp); errors++;
            end
            if (out_valid && out_ready) begin
                if ({err, zero, carry, res} !== exp_q) begin
                    $display("takt %0d: err/zero/carry/res = %b, oczekiwano %b", n, {err, zero, carry, res}, exp_q);
                    errors++;
                end
                has_exp = 1'b0;
                nout++;
            end
            if (in_valid && in_ready) begin
                if (has_exp) begin
                    $display("takt %0d: przyjecie przy zajetym rejestrze wyjsciowym", n); errors++;
                end
                exp_q   = model(op, a, b);
                has_exp = 1'b1;
                nin++;
                ops[op]++;
                if (op == 1 && a == b) sub_eq++;
                if (op == 0 && exp_q[W]) n_carry++;
                if (op == 1 && exp_q[W]) n_borrow++;
                if (exp_q[W+1])          n_zero++;
            end
            if (n >= 1500 && n < 2900 && !in_ready) begin
                $display("takt %0d: in_ready = 0 przy pelnym przeplywie", n); errors++;
            end
            pending = in_valid && !in_ready;  // źródło trzyma operację do przyjęcia
            if (out_valid && !out_ready) backpressure++;
            stalled = out_valid && !out_ready;
            held    = {err, zero, carry, res};
            @(negedge clk);
        end

        if (has_exp || nout != nin) begin
            $display("przyjeto %0d, odebrano %0d", nin, nout); errors++;
        end
        foreach (ops[i]) if (ops[i] == 0) begin
            $display("pokrycie: brak operacji op=%0d", i); errors++;
        end
        if (sub_eq == 0 || n_carry == 0 || n_borrow == 0 || n_zero == 0 || backpressure == 0) begin
            $display("pokrycie: sub_eq=%0d carry=%0d borrow=%0d zero=%0d wstrzymania=%0d",
                     sub_eq, n_carry, n_borrow, n_zero, backpressure);
            errors++;
        end
        $display("operacji: %0d, wstrzyman: %0d", nout, backpressure);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
