// Testbench 21.01: axis_skid i axis_8na32 z losowym valid po stronie źródła i losowym ready po stronie
// odbiornika (przeciwciśnienie). Sprawdzane:
//   - kolejność i zawartość słów, TLAST, TKEEP (model konwersji liczony z góry),
//   - reguły protokołu na wyjściu: gdy valid && !ready, w następnym takcie valid nadal 1 i dane bez zmian,
//   - przepustowość bufora: przy valid = ready = 1 stale jedno słowo na takt.
`timescale 1ns / 1ps
`default_nettype none

module tb_strumien;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    integer errors = 0, seed = 7;
    integer pv = 50, pr = 50;                     // prawdopodobieństwo valid i ready w %
    function integer los(input integer zakres);
        los = ($random(seed) & 32'h7fff_ffff) % zakres;
    endfunction

    // ================= axis_skid
    localparam integer N1 = 1500;
    reg  [7:0] sd;
    reg        sl, sv = 1'b0, mr = 1'b0;
    wire       sr, ml, mv;
    wire [7:0] md;
    integer    wyst = 0, odeb = 0;
    axis_skid #(.W(8)) u_skid (.clk(clk), .rst(rst), .s_data(sd), .s_last(sl), .s_valid(sv), .s_ready(sr),
        .m_data(md), .m_last(ml), .m_valid(mv), .m_ready(mr));

    always @(posedge clk) begin
        if (!rst) begin
            if (!sv || sr) begin                      // poprzednie słowo przyjęte albo brak słowa
                if (wyst < N1 && los(100) < pv) begin
                    sv   <= 1'b1;
                    sd   <= wyst[7:0] ^ 8'h5A;
                    sl   <= (wyst % 7 == 6);
                    wyst <= wyst + 1;
                end else
                    sv <= 1'b0;
            end
            mr <= (los(100) < pr);
        end
    end

    reg       pop_v_stoi = 1'b0;
    reg [8:0] pop_d;
    always @(posedge clk) begin
        if (!rst) begin
            if (pop_v_stoi && (!mv || {ml, md} != pop_d)) begin
                $display("skid: zmiana wyjscia przy valid && !ready");
                errors = errors + 1;
            end
            pop_v_stoi <= mv && !mr;
            pop_d      <= {ml, md};
            if (mv && mr) begin
                if (md != (odeb[7:0] ^ 8'h5A) || ml != (odeb % 7 == 6)) begin
                    if (errors < 10) $display("skid: slowo %0d = %h", odeb, md);
                    errors = errors + 1;
                end
                odeb = odeb + 1;
            end
        end
    end

    // ================= axis_8na32
    localparam integer NB = 700;
    reg  [7:0]  bajty [0:NB-1];
    reg         ost   [0:NB-1];
    reg  [31:0] ed    [0:NB-1];
    reg  [3:0]  ek    [0:NB-1];
    reg         el    [0:NB-1];
    integer     nslow = 0;
    reg  [7:0]  ud;
    reg         ul, uv = 1'b0, ur = 1'b0;
    wire        us_r, um_l, um_v;
    wire [31:0] um_d;
    wire [3:0]  um_k;
    integer     u_wyst = 0, u_odeb = 0;
    axis_8na32 u_konw (.clk(clk), .rst(rst), .s_data(ud), .s_last(ul), .s_valid(uv), .s_ready(us_r),
        .m_data(um_d), .m_keep(um_k), .m_last(um_l), .m_valid(um_v), .m_ready(ur));

    always @(posedge clk) begin
        if (!rst) begin
            if (!uv || us_r) begin
                if (u_wyst < NB && los(100) < pv) begin
                    uv     <= 1'b1;
                    ud     <= bajty[u_wyst];
                    ul     <= ost[u_wyst];
                    u_wyst <= u_wyst + 1;
                end else
                    uv <= 1'b0;
            end
            ur <= (los(100) < pr);
        end
    end

    always @(posedge clk) begin
        if (!rst && um_v && ur) begin
            if (um_d != ed[u_odeb] || um_k != ek[u_odeb] || um_l != el[u_odeb]) begin
                if (errors < 10) $display("8na32: slowo %0d = %h keep %b last %b, oczekiwano %h %b %b", u_odeb,
                                          um_d, um_k, um_l, ed[u_odeb], ek[u_odeb], el[u_odeb]);
                errors = errors + 1;
            end
            u_odeb = u_odeb + 1;
        end
    end

    // model konwersji: słowa liczone z góry
    integer i, poz, dl, t0, n_takt;
    reg [31:0] w;
    reg [3:0]  k;
    initial begin
        poz = 0;
        for (i = 0; i < NB; i = i + 1) begin
            if (poz == 0) dl = 1 + los(13);       // długość pakietu 1…13 bajtów
            bajty[i] = los(256);
            poz = poz + 1;
            ost[i] = (poz == dl) || (i == NB - 1);
            if (ost[i]) poz = 0;
        end
        poz = 0; w = 0; k = 0;
        for (i = 0; i < NB; i = i + 1) begin
            w[poz*8 +: 8] = bajty[i];
            k[poz] = 1'b1;
            if (poz == 3 || ost[i]) begin
                ed[nslow] = w; ek[nslow] = k; el[nslow] = ost[i];
                nslow = nslow + 1;
                w = 0; k = 0; poz = 0;
            end else
                poz = poz + 1;
        end

        repeat (5) @(negedge clk);
        rst = 1'b0;
        wait (odeb == N1 - 200);
        // ostatnie 200 słów: valid i ready stale 1 — oczekiwane jedno słowo na takt
        @(negedge clk);
        pv = 100; pr = 100;
        wait (odeb == N1 - 190);
        t0 = $time;
        wait (odeb == N1);
        n_takt = ($time - t0) / 10;
        wait (u_odeb == nslow);
        repeat (10) @(negedge clk);
        $display("skid: %0d slow; przy valid = ready = 1: 190 slow w %0d taktach", odeb, n_takt);
        $display("8na32: %0d bajtow -> %0d slow (pakiety 1-13 bajtow)", NB, u_odeb);
        if (n_takt > 191) errors = errors + 1;
        if (wyst != N1 || odeb != N1) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
