// Testbench (SystemVerilog) dzielenia i pierwiastka (19.03):
//   dziel_iter W = 8 bez znaku i ze znakiem — wszystkie 65 536 par (także dzielenie przez zero
//   i -128 / -1), W = 16 bez znaku i ze znakiem — 3000 losowych par i wartości skrajne,
//   dziel_potok W = 8 — wszystkie pary strumieniem (wynik w każdym takcie), W = 16 — 5000 losowych,
//   pierw_iter W = 8 (x 16-bitowe) — wszystkie x, W = 16 (x 32-bitowe) — 3000 losowych i kwadraty.
// Wzorzec: operatory / i % Veriloga (ze znakiem: zaokrąglenie do zera, reszta ze znakiem dzielnej),
// dla pierwiastka: p² <= x < (p+1)² i reszta = x - p². Sprawdzana też liczba taktów na wynik.
`timescale 1ns / 1ps
`default_nettype none

module tb_dzielenie;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0, i, j, t0, takty_d8 = 0, takty_p8 = 0;

    // ---------------- dziel_iter
    logic         st8 = 1'b0, st16 = 1'b0;
    logic  [7:0]  a8 = 8'd0, b8 = 8'd0;
    logic  [15:0] a16 = 16'd0, b16 = 16'd0;
    logic        bu8, du8, zu8, bs8, ds8, zs8, bu16, du16, zu16, bs16, ds16, zs16;
    logic [7:0]  qu8, ru8, qs8, rs8;
    logic [15:0] qu16, ru16, qs16, rs16;
    dziel_iter #(.W(8),  .ZNAK(0)) u8  (clk, rst, st8,  a8,  b8,  bu8,  du8,  qu8,  ru8,  zu8);
    dziel_iter #(.W(8),  .ZNAK(1)) s8  (clk, rst, st8,  a8,  b8,  bs8,  ds8,  qs8,  rs8,  zs8);
    dziel_iter #(.W(16), .ZNAK(0)) u16 (clk, rst, st16, a16, b16, bu16, du16, qu16, ru16, zu16);
    dziel_iter #(.W(16), .ZNAK(1)) s16 (clk, rst, st16, a16, b16, bs16, ds16, qs16, rs16, zs16);

    // oczekiwany wynik (W bitów) z operatorów Veriloga; dzielenie przez zero — konwencja RISC-V
    task oczek_dziel(input int w, input int zn, input [15:0] x, input [15:0] y,
                     output [15:0] q, output [15:0] r);
        int xi, yi, qi, ri;
        begin
            // bez operatora ?: — mieszanie wyrażeń ze znakiem i bez znaku daje wynik bez znaku
            if (w == 8 && zn != 0)      begin xi = $signed(x[7:0]); yi = $signed(y[7:0]); end
            else if (w == 8)            begin xi = x[7:0];          yi = y[7:0];          end
            else if (zn != 0)           begin xi = $signed(x);      yi = $signed(y);      end
            else                        begin xi = x;               yi = y;               end
            if (yi == 0) begin
                qi = -1; ri = xi;
            end else begin
                qi = xi / yi; ri = xi % yi;
            end
            q = qi[15:0] & ((w == 8) ? 16'h00FF : 16'hFFFF);
            r = ri[15:0] & ((w == 8) ? 16'h00FF : 16'hFFFF);
        end
    endtask

    task porownaj(input [8*4-1:0] nazwa, input [15:0] q, input [15:0] r, input z, input [15:0] eq,
                  input [15:0] er, input ez, input [15:0] x, input [15:0] y);
        begin
            if (q !== eq || r !== er || z !== ez) begin
                if (errors < 12)
                    $display("%s %h / %h: q=%h r=%h z=%b, oczekiwano q=%h r=%h z=%b", nazwa, x, y, q, r, z, eq, er, ez);
                errors = errors + 1;
            end
        end
    endtask

    logic [15:0] eq, er;

    // ---------------- dziel_potok
    logic         pv8 = 1'b0, pv16 = 1'b0;
    logic  [7:0]  pa8 = 8'd0, pb8 = 8'd0;
    logic  [15:0] pa16 = 16'd0, pb16 = 16'd0;
    logic        ov8, ov16;
    logic [7:0]  pq8, pr8;
    logic [15:0] pq16, pr16;
    dziel_potok #(.W(8))  p8  (clk, pv8,  pa8,  pb8,  ov8,  pq8,  pr8);
    dziel_potok #(.W(16)) p16 (clk, pv16, pa16, pb16, ov16, pq16, pr16);
    logic  [15:0] hx [0:65535];
    logic  [15:0] hy [0:65535];
    logic  [15:0] gx [0:4999];
    logic  [15:0] gy [0:4999];
    int     n8 = 0, n16 = 0, o8 = 0, o16 = 0, takt = 0;
    int     t8 [0:65535];
    always @(posedge clk) begin
        takt <= takt + 1;
        if (ov8) begin
            oczek_dziel(8, 0, hx[o8], hy[o8], eq, er);
            porownaj("pt8 ", {8'd0, pq8}, {8'd0, pr8}, 1'b0, eq, er, 1'b0, hx[o8], hy[o8]);
            if (takt - t8[o8] != 8) errors = errors + 1;
            o8 = o8 + 1;
        end
        if (ov16) begin
            oczek_dziel(16, 0, gx[o16], gy[o16], eq, er);
            porownaj("pt16", pq16, pr16, 1'b0, eq, er, 1'b0, gx[o16], gy[o16]);
            o16 = o16 + 1;
        end
    end

    // ---------------- pierw_iter
    logic         sp8 = 1'b0, sp16 = 1'b0;
    logic  [15:0] x16 = 16'd0;
    logic  [31:0] x32 = 32'd0;
    logic        pb8_, pd8, pb16_, pd16;
    logic [7:0]  pp8;
    logic [8:0]  prs8;
    logic [15:0] pp16;
    logic [16:0] prs16;
    pierw_iter #(.W(8))  q8  (clk, rst, sp8,  x16, pb8_,  pd8,  pp8,  prs8);
    pierw_iter #(.W(16)) q16 (clk, rst, sp16, x32, pb16_, pd16, pp16, prs16);

    task sprawdz_pierw(input [31:0] x, input [31:0] p, input [31:0] r);
        logic [63:0] p2, p12;
        begin
            p2  = p * p;
            p12 = (p + 1) * (p + 1);
            if (!(p2 <= x && x < p12) || r !== x - p2[31:0]) begin
                if (errors < 12) $display("pierw(%0d) = %0d reszta %0d", x, p, r);
                errors = errors + 1;
            end
        end
    endtask

    // losowe 16 bitów z przewagą wartości skrajnych
    function [15:0] los16(input int k);
        case (k % 8)
            0: los16 = 16'h8000;
            1: los16 = 16'h7FFF;
            2: los16 = 16'hFFFF;
            3: los16 = 16'h0001;
            default: los16 = $random;
        endcase
    endfunction

    initial begin
        repeat (2) @(negedge clk);
        rst = 1'b0;

        // dziel_iter W = 8: wszystkie pary
        for (i = 0; i < 65536; i = i + 1) begin
            @(negedge clk);
            a8 = i[15:8]; b8 = i[7:0]; st8 = 1'b1; t0 = takt;
            @(negedge clk) st8 = 1'b0;
            while (!du8) @(negedge clk);
            if (takty_d8 == 0) takty_d8 = takt - t0;
            if (!ds8) errors = errors + 1;
            oczek_dziel(8, 0, {8'd0, a8}, {8'd0, b8}, eq, er);
            porownaj("u8  ", {8'd0, qu8}, {8'd0, ru8}, zu8, eq, er, b8 == 8'd0, {8'd0, a8}, {8'd0, b8});
            oczek_dziel(8, 1, {8'd0, a8}, {8'd0, b8}, eq, er);
            porownaj("s8  ", {8'd0, qs8}, {8'd0, rs8}, zs8, eq, er, b8 == 8'd0, {8'd0, a8}, {8'd0, b8});
        end
        // W = 16: losowe i skrajne
        for (i = 0; i < 3000; i = i + 1) begin
            @(negedge clk);
            a16 = (i < 64) ? los16(i) : $random;
            b16 = (i < 64) ? los16(i / 8) : (i % 5 == 0) ? ($random % 256) : $random;
            st16 = 1'b1;
            @(negedge clk) st16 = 1'b0;
            while (!du16) @(negedge clk);
            oczek_dziel(16, 0, a16, b16, eq, er);
            porownaj("u16 ", qu16, ru16, zu16, eq, er, b16 == 16'd0, a16, b16);
            oczek_dziel(16, 1, a16, b16, eq, er);
            porownaj("s16 ", qs16, rs16, zs16, eq, er, b16 == 16'd0, a16, b16);
        end

        // dziel_potok: strumień, nowe dane w każdym takcie
        for (i = 0; i < 65536; i = i + 1) begin
            @(negedge clk);
            pa8 = i[15:8]; pb8 = i[7:0]; pv8 = 1'b1;
            hx[n8] = {8'd0, pa8}; hy[n8] = {8'd0, pb8}; t8[n8] = takt; n8 = n8 + 1;
            pa16 = (i < 5000) ? ((i < 64) ? los16(i) : $random) : 16'd0;
            pb16 = (i < 5000) ? ((i < 64) ? los16(i / 8) : $random) : 16'd0;
            pv16 = (i < 5000);
            if (i < 5000) begin gx[n16] = pa16; gy[n16] = pb16; n16 = n16 + 1; end
        end
        @(negedge clk) pv8 = 1'b0; pv16 = 1'b0;
        repeat (20) @(negedge clk);
        if (o8 != 65536 || o16 != 5000) begin
            $display("dziel_potok: wynikow %0d / %0d", o8, o16);
            errors = errors + 1;
        end

        // pierw_iter
        for (i = 0; i < 65536; i = i + 1) begin
            @(negedge clk);
            x16 = i[15:0]; sp8 = 1'b1; t0 = takt;
            @(negedge clk) sp8 = 1'b0;
            while (!pd8) @(negedge clk);
            if (takty_p8 == 0) takty_p8 = takt - t0;
            sprawdz_pierw({16'd0, x16}, {24'd0, pp8}, {23'd0, prs8});
        end
        for (i = 0; i < 3000; i = i + 1) begin
            @(negedge clk);
            j = $random;
            x32 = (i < 16) ? (i * i * 4099 * 4099) : (i < 32) ? (32'hFFFFFFFF - i) : $random;
            if (i % 7 == 0 && i >= 32) x32 = (j[15:0] * j[15:0]) - (i % 2);   // kwadraty i o jeden mniej
            sp16 = 1'b1;
            @(negedge clk) sp16 = 1'b0;
            while (!pd16) @(negedge clk);
            sprawdz_pierw(x32, {16'd0, pp16}, {15'd0, prs16});
        end

        $display("takty na wynik: dziel_iter W=8 %0d, pierw_iter W=8 %0d", takty_d8, takty_p8);
        if (takty_d8 != 10 || takty_p8 != 10) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
