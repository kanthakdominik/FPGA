// Demozaikowanie RGGB metodą dwuliniową (31.05): okno 3×3 surowych próbek z dwóch linii opóźniających
// (jak filtr3x3 z 24.06), w środku okna brakujące składowe jako średnie sąsiadów:
//   R (wiersz parz., kol. parz.):  G = krzyż/4, B = przekątne/4
//   G na wierszu R:                R = poziome/2,  B = pionowe/2
//   G na wierszu B:                R = pionowe/2,  B = poziome/2
//   B (wiersz nieparz., kol. nieparz.): G = krzyż/4, R = przekątne/4
// Średnie zaokrąglane (+2 przed /4, +1 przed /2). Piksele wygaszania wchodzą jako 0 (ciemniejsze brzegi).
// Pozycję środka okna (parzystość wiersza i kolumny) liczą liczniki z opóźnionych de i vs. Opóźnienie L + 4.
`default_nettype none

module demozaika #(
    parameter integer L = 800                  // pełna długość linii z wygaszaniem
) (
    input  logic        clk,
    input  logic        de,
    input  logic        hs,
    input  logic        vs,
    input  logic [7:0]  raw,
    output logic         o_de = 1'b0,
    output logic         o_hs = 1'b1,
    output logic         o_vs = 1'b1,
    output logic  [23:0] rgb = 24'd0
);
    localparam integer AW = $clog2(L);
    /* verilator lint_off WIDTHTRUNC */
    localparam [AW-1:0] OST = L - 1;
    /* verilator lint_on WIDTHTRUNC */

    logic  [10:0] w0 = 11'd0;
    always_ff @(posedge clk) w0 <= {de, hs, vs, de ? raw : 8'd0};
    logic  [10:0]   lin1 [0:L-1];
    logic  [7:0]    lin2 [0:L-1];
    logic  [AW-1:0] a = {AW{1'b0}};
    logic  [AW-1:0] an = {AW{1'b0}};
    logic  [10:0]   w1 = 11'd0;
    logic  [7:0]    w2 = 8'd0;
    integer i;
    initial for (i = 0; i < L; i = i + 1) begin lin1[i] = 11'd0; lin2[i] = 8'd0; end
    always_ff @(posedge clk) begin
        a  <= an;
        an <= (an == OST) ? {AW{1'b0}} : an + 1'b1;
        lin1[a] <= w0;
        lin2[a] <= w1[7:0];
        w1 <= lin1[an];
        w2 <= lin2[an];
    end

    logic [7:0] p00 = 8'd0;
    logic [7:0] p01 = 8'd0;
    logic [7:0] p02 = 8'd0;
    logic [7:0] p10 = 8'd0;
    logic [7:0] p11 = 8'd0;
    logic [7:0] p12 = 8'd0;
    logic [7:0] p20 = 8'd0;
    logic [7:0] p21 = 8'd0;
    logic [7:0] p22 = 8'd0;
    logic [2:0] s1 = 3'b011;
    logic [2:0] s2 = 3'b011;                      // {de, hs, vs} środka okna
    always_ff @(posedge clk) begin
        p00 <= w0[7:0]; p01 <= p00; p02 <= p01;
        p10 <= w1[7:0]; p11 <= p10; p12 <= p11;
        p20 <= w2;      p21 <= p20; p22 <= p21;
        s1  <= w1[10:8];
        s2  <= s1;
    end

    // pozycja środka okna: kolumna od początku de, wiersz od impulsu vs (liczony na końcach linii)
    logic        de_p = 1'b0;
    logic        vs_p = 1'b1;
    logic        kol = 1'b0;
    logic        wier = 1'b0;
    always_ff @(posedge clk) begin
        de_p <= s2[2];
        vs_p <= s2[0];
        if (s2[2]) kol <= ~kol; else kol <= 1'b0;
        if (vs_p && !s2[0])        wier <= 1'b0;          // początek impulsu vs (ujemnego)
        else if (de_p && !s2[2])   wier <= ~wier;          // koniec linii aktywnej
    end

    logic [9:0] krzyz;
    assign krzyz = {2'd0, p01} + {2'd0, p10} + {2'd0, p12} + {2'd0, p21} + 10'd2;
    logic [9:0] przek;
    assign przek = {2'd0, p00} + {2'd0, p02} + {2'd0, p20} + {2'd0, p22} + 10'd2;
    logic [8:0] poz;
    assign poz = {1'b0, p10} + {1'b0, p12} + 9'd1;
    logic [8:0] pion;
    assign pion = {1'b0, p01} + {1'b0, p21} + 9'd1;

    always_ff @(posedge clk) begin
        {o_de, o_hs, o_vs} <= s2;
        case ({wier, kol})
            2'b00:   rgb <= {p11, krzyz[9:2], przek[9:2]};
            2'b01:   rgb <= {poz[8:1], p11, pion[8:1]};
            2'b10:   rgb <= {pion[8:1], p11, poz[8:1]};
            default: rgb <= {przek[9:2], krzyz[9:2], p11};
        endcase
    end
endmodule

`default_nettype wire
