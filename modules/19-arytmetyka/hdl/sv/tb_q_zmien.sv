// Testbench (SystemVerilog) q_zmien (19.01): wyczerpująco wszystkie wejścia kilku konfiguracji, porównanie z modelem
// liczonym na liczbach całkowitych w testbenchu. Konfiguracje:
//   A: Q8.8 (16 b) -> Q4.4 (8 b): obcięcie, połówka w górę, zbieżne z nasyceniem; zbieżne z zawijaniem,
//   B: Q7.1 -> Q8.0 zbieżne (ubywa jeden bit — przypadek brzegowy D = 1),
//   C: Q4.4 -> Q8.8 (przybywa bitów ułamkowych — bez zaokrąglania), D: Q4.4 (8 b) -> Q0.4 (4 b): samo nasycenie.
// Dodatkowo średni błąd (obciążenie) trzech sposobów zaokrąglania dla A w LSB wyjścia:
// obcięcie -15/32 = -0,46875, połówka w górę +1/32 = +0,03125, zbieżne 0.
`timescale 1ns / 1ps
`default_nettype none

module tb_q_zmien;
    logic  [15:0] xa = 16'd0;
    logic  [7:0]  xb = 8'd0;
    logic [7:0]  ya0, ya1, ya2, ya3, yb;
    logic [15:0] yc;
    logic [3:0]  yd;
    logic        pa0, pa1, pa2, pa3, pb, pc, pd;

    q_zmien #(.WI(16), .FI(8), .WO(8), .FO(4), .ZAOKR(0), .NASYC(1)) ua0 (.din(xa), .dout(ya0), .przepel(pa0));
    q_zmien #(.WI(16), .FI(8), .WO(8), .FO(4), .ZAOKR(1), .NASYC(1)) ua1 (.din(xa), .dout(ya1), .przepel(pa1));
    q_zmien #(.WI(16), .FI(8), .WO(8), .FO(4), .ZAOKR(2), .NASYC(1)) ua2 (.din(xa), .dout(ya2), .przepel(pa2));
    q_zmien #(.WI(16), .FI(8), .WO(8), .FO(4), .ZAOKR(2), .NASYC(0)) ua3 (.din(xa), .dout(ya3), .przepel(pa3));
    q_zmien #(.WI(8),  .FI(1), .WO(8), .FO(0), .ZAOKR(2), .NASYC(1)) ub  (.din(xb), .dout(yb),  .przepel(pb));
    q_zmien #(.WI(8),  .FI(4), .WO(16), .FO(8), .ZAOKR(2), .NASYC(1)) uc (.din(xb), .dout(yc),  .przepel(pc));
    q_zmien #(.WI(8),  .FI(4), .WO(4), .FO(4), .ZAOKR(2), .NASYC(1)) ud  (.din(xb), .dout(yd),  .przepel(pd));

    int errors = 0, i, x, y, n_bez = 0, n_prz = 0;
    logic     prz;
    real    blad0 = 0.0, blad1 = 0.0, blad2 = 0.0, sr0, sr1, sr2;

    // model: d — liczba usuwanych bitów ułamkowych (ujemna: dopisywanych), tryb zaokrąglania, wo — bity wyjścia
    task model(input int xin, input int d, input int tryb, input int wo, input int nasyc,
               output int yout, output logic p);
        int podl, reszta, pol, t, maks, mini;
        begin
            if (d > 0) begin
                podl   = xin >>> d;
                reszta = xin - podl * (1 << d);
                pol    = 1 << (d - 1);
                if (tryb == 0)      t = podl;
                else if (tryb == 1) t = podl + ((reszta >= pol) ? 1 : 0);
                else                t = podl + ((reszta > pol || (reszta == pol && (podl & 1) == 1)) ? 1 : 0);
            end else
                t = xin * (1 << (-d));
            maks = (1 << (wo - 1)) - 1;
            mini = -(1 << (wo - 1));
            p = (t > maks) || (t < mini);
            if (!p)         yout = t;
            else if (nasyc) yout = (t > maks) ? maks : mini;
            else begin
                yout = t & ((1 << wo) - 1);
                if (yout > maks) yout = yout - (1 << wo);
            end
        end
    endtask

    task sprawdz(input [8*3-1:0] nazwa, input int wynik, input logic p_dut, input int oczek, input logic p_oczek);
        begin
            if (wynik !== oczek || p_dut !== p_oczek) begin
                if (errors < 10)
                    $display("%s x=%0d: wynik %0d (przepel %b), oczekiwano %0d (%b)", nazwa, x, wynik, p_dut, oczek, p_oczek);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        for (i = 0; i < 65536; i = i + 1) begin
            xa = i[15:0];
            xb = i[7:0];
            #1;
            x = $signed(xa);
            model(x, 4, 0, 8, 1, y, prz); sprawdz("A0 ", $signed(ya0), pa0, y, prz);
            if (!prz) blad0 = blad0 + (y * 16 - x);
            model(x, 4, 1, 8, 1, y, prz); sprawdz("A1 ", $signed(ya1), pa1, y, prz);
            if (!prz) blad1 = blad1 + (y * 16 - x);
            model(x, 4, 2, 8, 1, y, prz); sprawdz("A2 ", $signed(ya2), pa2, y, prz);
            if (!prz) begin blad2 = blad2 + (y * 16 - x); n_bez = n_bez + 1; end
            else n_prz = n_prz + 1;
            model(x, 4, 2, 8, 0, y, prz); sprawdz("A3 ", $signed(ya3), pa3, y, prz);
            if (i < 256) begin
                x = $signed(xb);
                model(x, 1, 2, 8, 1, y, prz);   sprawdz("B  ", $signed(yb), pb, y, prz);
                model(x, -4, 2, 16, 1, y, prz); sprawdz("C  ", $signed(yc), pc, y, prz);
                model(x, 0, 2, 4, 1, y, prz);   sprawdz("D  ", $signed(yd), pd, y, prz);
            end
        end
        sr0 = blad0 / (n_bez * 16.0);
        sr1 = blad1 / (n_bez * 16.0);
        sr2 = blad2 / (n_bez * 16.0);
        $display("A: %0d wartosci w zakresie, %0d nasyconych; sredni blad [LSB wyjscia]: obciecie %f, polowka w gore %f, zbiezne %f",
                 n_bez, n_prz, sr0, sr1, sr2);
        if (sr0 > -0.46 || sr0 < -0.48 || sr1 < 0.025 || sr1 > 0.04 || sr2 > 0.005 || sr2 < -0.005) begin
            $display("niezgodne obciazenie zaokraglania");
            errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
