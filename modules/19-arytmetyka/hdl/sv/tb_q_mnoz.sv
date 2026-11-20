// Testbench (SystemVerilog) q_mnoz (19.01): mnożenie Q1.15 × Q1.15 -> Q1.15 z zaokrągleniem zbieżnym i nasyceniem.
// 20 000 losowych par i przypadki brzegowe: (-1) × (-1) = +1 nie mieści się w Q1.15 (nasycenie do
// 0x7FFF z flagą), 0,5 × 0,5, najmniejsze iloczyny (zaokrąglenie do zera), połówki LSB (do parzystej).
// Dane w każdym takcie (in_valid = 1) — sprawdzana też przepustowość i opóźnienie 2 takty.
`timescale 1ns / 1ps
`default_nettype none

module tb_q_mnoz;
    localparam N = 20000, NS = 8;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic         in_valid = 1'b0;
    logic  [15:0] a = 16'd0, b = 16'd0;
    logic        out_valid, przepel;
    logic [15:0] p;
    q_mnoz #(.WA(16), .FA(15), .WB(16), .FB(15), .WO(16), .FO(15), .ZAOKR(2), .NASYC(1))
        dut (.clk(clk), .in_valid(in_valid), .a(a), .b(b), .out_valid(out_valid), .p(p), .przepel(przepel));

    logic [15:0] sa [0:NS-1];
    logic [15:0] sb [0:NS-1];
    int    oczek [0:N+NS-1];
    logic        oczek_p [0:N+NS-1];
    int    errors = 0, i, k = 0, odebrane = 0, takty = 0, iloczyn, y, n_prz = 0;
    logic        prz;

    initial begin
        sa[0] = 16'h8000; sb[0] = 16'h8000;          // -1 × -1 = +1 -> nasycenie
        sa[1] = 16'h4000; sb[1] = 16'h4000;          // 0,5 × 0,5 = 0,25
        sa[2] = 16'h0001; sb[2] = 16'h0001;          // 2^-30 -> 0
        sa[3] = 16'h8000; sb[3] = 16'h0001;          // -2^-15 dokładnie
        sa[4] = 16'h0003; sb[4] = 16'h4000;          // 1,5 LSB -> 2 (do parzystej)
        sa[5] = 16'h0005; sb[5] = 16'h4000;          // 2,5 LSB -> 2 (do parzystej)
        sa[6] = 16'h7FFF; sb[6] = 16'h7FFF;
        sa[7] = 16'h8000; sb[7] = 16'h7FFF;
    end

    // model: iloczyn Q2.30 -> Q1.15, zbieżne, nasycenie
    task model(input int pr, output int yout, output logic p_o);
        int podl, reszta, t;
        begin
            podl   = pr >>> 15;
            reszta = pr - podl * 32768;
            t      = podl + ((reszta > 16384 || (reszta == 16384 && (podl & 1) == 1)) ? 1 : 0);
            p_o    = (t > 32767) || (t < -32768);
            yout   = (t > 32767) ? 32767 : (t < -32768) ? -32768 : t;
        end
    endtask

    always @(posedge clk) begin
        if (in_valid) takty <= takty + 1;
        if (out_valid) begin
            if ($signed(p) !== oczek[odebrane] || przepel !== oczek_p[odebrane]) begin
                if (errors < 10)
                    $display("probka %0d: p=%0d przepel=%b, oczekiwano %0d %b", odebrane, $signed(p), przepel,
                             oczek[odebrane], oczek_p[odebrane]);
                errors = errors + 1;
            end
            if (przepel) n_prz = n_prz + 1;
            odebrane = odebrane + 1;
        end
    end

    initial begin
        repeat (2) @(negedge clk);
        for (i = 0; i < N + NS; i = i + 1) begin
            @(negedge clk);
            if (i < NS) begin a = sa[i]; b = sb[i]; end
            else begin a = $random; b = $random; end
            in_valid = 1'b1;
            iloczyn = $signed(a) * $signed(b);
            model(iloczyn, y, prz);
            oczek[k] = y; oczek_p[k] = prz; k = k + 1;
        end
        @(negedge clk) in_valid = 1'b0;
        repeat (4) @(negedge clk);
        $display("probek %0d, odebranych %0d, nasyconych %0d", k, odebrane, n_prz);
        if (odebrane != k) errors = errors + 1;
        if (oczek[0] != 32767 || !oczek_p[0] || oczek[1] != 8192 || oczek[4] != 2 || oczek[5] != 2) begin
            $display("model: zle przypadki brzegowe");
            errors = errors + 1;
        end
        if (errors == 0 && n_prz == 1) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
