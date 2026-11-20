// Testbench cordic (19.04), W = 16, A = 24, N = 18, dane w każdym takcie:
//   obrót: sin i cos dla 4096 kątów z całego okręgu (x_in = 32767/K, y_in = 0) oraz 4000 losowych
//          wektorów i kątów — wzorzec K·(x·cos - y·sin, x·sin + y·cos), K liczone z N,
//   wektorowanie: 4000 losowych wektorów — K·|v| i atan2(y, x) (dla |v| >= 2^12), y_out ≈ 0.
// Tolerancje: 3 LSB dla sin/cos, 4 LSB dla obrotu i modułu, 256 LSB kąta (2^24 na obrót, 9,6·10^-5 rad). Wypisywane
// największe błędy (do porównania z modelem w arytmetyka/cordic_model.py). Opóźnienie N+2 taktów.
`timescale 1ns / 1ps
`default_nettype none

module tb_cordic;
    localparam W = 16, A = 24, N = 18, NS = 4096 + 4000, TOL_KAT = 256;
    localparam real PI = 3.14159265358979323846;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg           in_valid = 1'b0;
    reg  [W-1:0]  x_in = 0, y_in = 0;
    reg  [A-1:0]  z_in = 0;
    wire          vr, vv;
    wire [W+1:0]  xr, yr, xv, yv;
    wire [A-1:0]  zr, zv;
    cordic #(.W(W), .A(A), .N(N), .G(4), .TRYB(0)) u_obr (.clk(clk), .in_valid(in_valid), .x_in(x_in),
        .y_in(y_in), .z_in(z_in), .out_valid(vr), .x_out(xr), .y_out(yr), .z_out(zr));
    cordic #(.W(W), .A(A), .N(N), .G(4), .TRYB(1)) u_wek (.clk(clk), .in_valid(in_valid), .x_in(x_in),
        .y_in(y_in), .z_in({A{1'b0}}), .out_valid(vv), .x_out(xv), .y_out(yv), .z_out(zv));

    reg  [W-1:0] hx [0:NS-1];
    reg  [W-1:0] hy [0:NS-1];
    reg  [A-1:0] hz [0:NS-1];
    integer      ht [0:NS-1];
    integer      i, nw = 0, no = 0, takt = 0, errors = 0, n_kat = 0;
    real         K, th, ex, ey, er, ekat, d, m_sc = 0.0, m_obr = 0.0, m_mod = 0.0, m_kat = 0.0, m_y = 0.0;
    integer      dk;

    initial begin
        K = 1.0;
        for (i = 0; i < N; i = i + 1) K = K * $sqrt(1.0 + $pow(2.0, -2.0 * i));
    end

    function real absr(input real v);
        absr = (v < 0.0) ? -v : v;
    endfunction

    always @(posedge clk) begin
        takt <= takt + 1;
        if (vr) begin
            if (!vv || takt - ht[no] != N + 2) errors = errors + 1;
            // obrót
            th = $itor($signed(hz[no])) * 2.0 * PI / (2.0 ** A);
            ex = K * ($itor($signed(hx[no])) * $cos(th) - $itor($signed(hy[no])) * $sin(th));
            ey = K * ($itor($signed(hx[no])) * $sin(th) + $itor($signed(hy[no])) * $cos(th));
            d  = absr($itor($signed(xr)) - ex);
            if (absr($itor($signed(yr)) - ey) > d) d = absr($itor($signed(yr)) - ey);
            if (no < 4096) begin
                if (d > m_sc) m_sc = d;
                if (d > 3.0) errors = errors + 1;
            end else begin
                if (d > m_obr) m_obr = d;
                if (d > 4.0) errors = errors + 1;
            end
            if (d > 4.0 && errors < 10)
                $display("obrot %0d: x=%0d y=%0d, oczekiwano %f %f", no, $signed(xr), $signed(yr), ex, ey);
            // wektorowanie
            er = K * $sqrt($itor($signed(hx[no])) ** 2 + $itor($signed(hy[no])) ** 2);
            d  = absr($itor($signed(xv)) - er);
            if (d > m_mod) m_mod = d;
            if (absr($itor($signed(yv))) > m_y) m_y = absr($itor($signed(yv)));
            if (d > 4.0 || absr($itor($signed(yv))) > 4.0) begin
                if (errors < 10) $display("wektor %0d: |v| %0d, oczekiwano %f, y=%0d", no, $signed(xv), er, $signed(yv));
                errors = errors + 1;
            end
            if (er >= K * 4096.0) begin
                ekat = $atan2($itor($signed(hy[no])), $itor($signed(hx[no]))) / (2.0 * PI) * (2.0 ** A);
                dk   = $signed(zv) - $rtoi(ekat >= 0.0 ? ekat + 0.5 : ekat - 0.5);
                if (dk >= (1 << (A - 1))) dk = dk - (1 << A);        // różnica kątów modulo pełny obrót
                if (dk < -(1 << (A - 1))) dk = dk + (1 << A);
                if (absr($itor(dk)) > m_kat) m_kat = absr($itor(dk));
                if (dk > TOL_KAT || dk < -TOL_KAT) begin
                    if (errors < 10) $display("wektor %0d: kat %0d, oczekiwano %f", no, $signed(zv), ekat);
                    errors = errors + 1;
                end
                n_kat = n_kat + 1;
            end
            no = no + 1;
        end
    end

    initial begin
        repeat (3) @(negedge clk);
        for (i = 0; i < NS; i = i + 1) begin
            @(negedge clk);
            if (i < 4096) begin
                x_in = $rtoi(32767.0 / K + 0.5);
                y_in = 0;
                z_in = (i << (A - 12)) + ($random & ((1 << (A - 12)) - 1));
            end else begin
                x_in = $random; y_in = $random; z_in = $random;
            end
            in_valid = 1'b1;
            hx[nw] = x_in; hy[nw] = y_in; hz[nw] = z_in; ht[nw] = takt; nw = nw + 1;
        end
        @(negedge clk) in_valid = 1'b0;
        repeat (N + 6) @(negedge clk);
        $display("K = %f; najwiekszy blad: sin/cos %f LSB, obrot %f LSB, modul %f LSB, |y| po wektorowaniu %f, kat %f LSB (2^%0d/obrot, %0d wektorow)",
                 K, m_sc, m_obr, m_mod, m_y, m_kat, A, n_kat);
        if (no != NS) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
