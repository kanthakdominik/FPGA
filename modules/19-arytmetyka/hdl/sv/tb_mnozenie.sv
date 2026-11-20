// Testbench (SystemVerilog) mnożarek z 19.02 na tym samym strumieniu danych (dane z przerwami: in_valid losowe):
//   mnoz_potok 18 × 18 ze znakiem dla LAT = 0…4, bez znaku (LAT = 2), 25 × 18 ze znakiem (LAT = 3),
//   mnoz_szeroki 34 × 34 ze znakiem, mnoz_zesp w wersji z czterema i z trzema mnożeniami.
// Każda instancja porównywana z iloczynem liczonym w testbenchu z historii wejść; sprawdzane też
// opóźnienie (liczba taktów od in_valid do out_valid) i brak zgubionych lub dodatkowych wyników.
// Pierwsze próbki to wartości skrajne (najmniejsza, największa, -1, 0) we wszystkich kombinacjach.
`timescale 1ns / 1ps
`default_nettype none

module tb_mnozenie;
    localparam N = 3000;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic         in_valid = 1'b0;
    logic  [33:0] a = 34'd0, b = 34'd0;
    logic  [15:0] ci = 16'd0, di = 16'd0;

    // historia wejść (w kolejności in_valid)
    logic  [33:0] ha [0:N-1];
    logic  [33:0] hb [0:N-1];
    logic  [15:0] hc [0:N-1];
    logic  [15:0] hd [0:N-1];
    int     nwej = 0, errors = 0, i, takt = 0;
    int     t_wej [0:N-1];

    // ---- mnoz_potok 18 × 18 ze znakiem, LAT = 0…4
    wire  [35:0] p_s [0:4];
    logic [4:0]  v_s;
    genvar g;
    generate
        for (g = 0; g <= 4; g = g + 1) begin : g_lat
            mnoz_potok #(.WA(18), .WB(18), .ZNAK(1), .LAT(g)) u (.clk(clk), .in_valid(in_valid),
                .a(a[17:0]), .b(b[17:0]), .out_valid(v_s[g]), .p(p_s[g]));
            int n = 0;
            always @(posedge clk) if (v_s[g]) begin
                if ($signed(p_s[g]) !== $signed(ha[n][17:0]) * $signed(hb[n][17:0]) || takt - t_wej[n] != g) begin
                    if (errors < 10) $display("potok LAT=%0d probka %0d: %0d", g, n, $signed(p_s[g]));
                    errors = errors + 1;
                end
                n = n + 1;
            end
        end
    endgenerate

    // ---- bez znaku 18 × 18 (LAT = 2) i 25 × 18 ze znakiem (LAT = 3)
    logic [35:0] p_u;
    logic [42:0] p_25;
    logic        v_u, v_25;
    mnoz_potok #(.WA(18), .WB(18), .ZNAK(0), .LAT(2)) u_bz (.clk(clk), .in_valid(in_valid),
        .a(a[17:0]), .b(b[17:0]), .out_valid(v_u), .p(p_u));
    mnoz_potok #(.WA(25), .WB(18), .ZNAK(1), .LAT(3)) u_25 (.clk(clk), .in_valid(in_valid),
        .a(a[24:0]), .b(b[17:0]), .out_valid(v_25), .p(p_25));
    int n_u = 0, n_25 = 0;
    always @(posedge clk) begin
        if (v_u) begin
            if (p_u !== ha[n_u][17:0] * hb[n_u][17:0]) begin
                if (errors < 10) $display("bez znaku probka %0d: %0d", n_u, p_u);
                errors = errors + 1;
            end
            n_u = n_u + 1;
        end
        if (v_25) begin
            if ($signed(p_25) !== $signed(ha[n_25][24:0]) * $signed(hb[n_25][17:0])) begin
                if (errors < 10) $display("25x18 probka %0d: %0d", n_25, $signed(p_25));
                errors = errors + 1;
            end
            n_25 = n_25 + 1;
        end
    end

    // ---- mnoz_szeroki 34 × 34
    logic [67:0] p_w;
    logic        v_w;
    int     n_w = 0;
    mnoz_szeroki #(.H(17)) u_w (.clk(clk), .in_valid(in_valid), .a(a), .b(b), .out_valid(v_w), .p(p_w));
    always @(posedge clk) if (v_w) begin
        if ($signed(p_w) !== $signed(ha[n_w]) * $signed(hb[n_w]) || takt - t_wej[n_w] != 3) begin
            if (errors < 10) $display("szeroki probka %0d: %h", n_w, p_w);
            errors = errors + 1;
        end
        n_w = n_w + 1;
    end

    // ---- mnoz_zesp: a = (a[15:0] + j·ci), b = (b[15:0] + j·di)
    logic [32:0] pr4, pi4, pr3, pi3;
    logic        v4, v3;
    int     n_z = 0;
    logic signed [32:0] er, ei;
    mnoz_zesp #(.W(16), .TRZY(0)) u_z4 (.clk(clk), .in_valid(in_valid), .ar(a[15:0]), .ai(ci),
        .br(b[15:0]), .bi(di), .out_valid(v4), .pr(pr4), .pi(pi4));
    mnoz_zesp #(.W(16), .TRZY(1)) u_z3 (.clk(clk), .in_valid(in_valid), .ar(a[15:0]), .ai(ci),
        .br(b[15:0]), .bi(di), .out_valid(v3), .pr(pr3), .pi(pi3));
    always @(posedge clk) if (v4) begin
        er = $signed(ha[n_z][15:0]) * $signed(hb[n_z][15:0]) - $signed(hc[n_z]) * $signed(hd[n_z]);
        ei = $signed(ha[n_z][15:0]) * $signed(hd[n_z]) + $signed(hc[n_z]) * $signed(hb[n_z][15:0]);
        if (!v3 || pr4 !== er || pi4 !== ei || pr3 !== er || pi3 !== ei || takt - t_wej[n_z] != 4) begin
            if (errors < 10) $display("zesp probka %0d: %0d %0d / %0d %0d, oczekiwano %0d %0d",
                                      n_z, $signed(pr4), $signed(pi4), $signed(pr3), $signed(pi3), er, ei);
            errors = errors + 1;
        end
        n_z = n_z + 1;
    end

    always @(posedge clk) takt <= takt + 1;

    // wartość skrajna szerokości w rozszerzona znakiem do 34 bitów: 0 — najmniejsza, 1 — największa, 2 — -1, 3 — 0
    function [33:0] skrajna(input [1:0] k, input int w);
        case (k)
            2'd0:    skrajna = {34{1'b1}} << (w - 1);
            2'd1:    skrajna = ~({34{1'b1}} << (w - 1));
            2'd2:    skrajna = {34{1'b1}};
            default: skrajna = 34'd0;
        endcase
    endfunction

    initial begin
        repeat (3) @(negedge clk);
        i = 0;
        while (nwej < N - 8) begin
            @(negedge clk);
            if (i < 48) begin                      // skrajne dla 18, 34 i 16 bitów, wszystkie pary
                a  = skrajna(i[1:0], i < 16 ? 18 : i < 32 ? 34 : 16);
                b  = skrajna(i[3:2], i < 16 ? 18 : i < 32 ? 34 : 16);
                ci = b[15:0];
                di = a[15:0];
                in_valid = 1'b1;
            end else begin
                a  = {$random, $random};
                b  = {$random, $random};
                ci = $random;
                di = $random;
                in_valid = ($random % 4) != 0;
            end
            if (in_valid) begin                    // historia wejść zapisywana przed zboczem, które je pobiera
                ha[nwej] = a; hb[nwej] = b; hc[nwej] = ci; hd[nwej] = di; t_wej[nwej] = takt;
                nwej = nwej + 1;
            end
            i = i + 1;
        end
        @(negedge clk) in_valid = 1'b0;
        repeat (8) @(negedge clk);
        $display("probek %0d; wynikow: LAT0 %0d LAT4 %0d bez znaku %0d 25x18 %0d szeroki %0d zesp %0d",
                 nwej, g_lat[0].n, g_lat[4].n, n_u, n_25, n_w, n_z);
        if (g_lat[0].n != nwej || g_lat[1].n != nwej || g_lat[2].n != nwej || g_lat[3].n != nwej ||
            g_lat[4].n != nwej || n_u != nwej || n_25 != nwej || n_w != nwej || n_z != nwej)
            errors = errors + 1;
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
