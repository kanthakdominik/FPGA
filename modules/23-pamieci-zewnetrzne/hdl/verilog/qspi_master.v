// Kontroler pamięci SPI/QSPI flash (23.03), tryb SPI 0 (SCLK w spoczynku 0, próbkowanie na narastającym).
// Jedna transakcja = rozkaz (8 bitów na DQ0) [+ adres 24 bity na DQ0] [+ cykle puste] [+ dane]:
//   dane pojedynczo: zapis na DQ0, odczyt z DQ1 (1-1-1, np. 0x03, 0x0B, 0x9F, 0x05, 0x02),
//   dane poczwórnie: 4 bity na cykl na DQ3..DQ0 (1-1-4, np. odczyt 0x6B, zapis 0x32).
// Bajty zapisu: wdane pobierane impulsem wpobierz (następny bajt potrzebny po 1 bajcie na linii);
// bajty odczytu: rdane z impulsem rwazne. SCLK = f_clk / (2·DIV).
`default_nettype none

module qspi_master #(
    parameter integer DIV = 2
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [7:0]  rozkaz,
    input  wire [23:0] adres,
    input  wire        z_adresem,
    input  wire [3:0]  puste,                   // liczba cykli pustych (dummy)
    input  wire [8:0]  dlugosc,                 // bajty danych (0–256)
    input  wire        zapis,                   // 1: dane do pamięci
    input  wire        quad,                    // dane na 4 liniach
    input  wire [7:0]  wdane,
    output reg         wpobierz,
    output reg  [7:0]  rdane,
    output reg         rwazne,
    output reg         gotowy,
    output reg         sclk,
    output reg         cs_n,
    output reg  [3:0]  dq_o,
    output reg  [3:0]  dq_oe,
    input  wire [3:0]  dq_i
);
    localparam [1:0] S_SPOCZ = 2'd0, S_PRACA = 2'd1, S_KONIEC = 2'd2, S_CS = 2'd3;
    localparam [1:0] F_ROZ = 2'd0, F_PUSTE = 2'd1, F_DANE = 2'd2;
    localparam integer TW = $clog2(DIV + 1);
    /* verilator lint_off WIDTHTRUNC */
    localparam [TW-1:0] DIV_1 = DIV - 1;
    /* verilator lint_on WIDTHTRUNC */

    reg [1:0]    stan, faza;
    reg [TW-1:0] t;
    reg [11:0]   licz;                          // cykle SCLK do końca fazy − 1
    /* verilator lint_off UNUSEDSIGNAL */  // najstarszy bit wysuwany na zewnątrz, nie czytany
    reg [31:0]   sr;                            // rozkaz i adres
    /* verilator lint_on UNUSEDSIGNAL */
    /* verilator lint_off UNUSEDSIGNAL */  // jw.
    reg [7:0]    wsr, rsr;
    /* verilator lint_on UNUSEDSIGNAL */
    reg [2:0]    bw, br;                        // cykl w bajcie: zapis (opadające), odczyt (narastające)
    reg [3:0]    r_puste;
    reg [8:0]    r_dl;
    reg          r_zapis, r_quad;
    wire [2:0]   ost_b = r_quad ? 3'd1 : 3'd7;  // ostatni cykl bajtu

    // przejście do następnej fazy po rozkazie/adresie albo cyklach pustych
    task nastepna_faza(input [1:0] z);
        begin
            if (z == F_ROZ && r_puste != 4'd0) begin
                faza  <= F_PUSTE;
                licz  <= {8'd0, r_puste} - 1'b1;
                dq_oe <= 4'b0000;
            end else if (r_dl != 9'd0) begin
                faza  <= F_DANE;
                licz  <= (r_quad ? {2'd0, r_dl, 1'b0} : {r_dl, 3'b000}) - 1'b1;
                bw    <= 3'd0;
                br    <= 3'd0;
                if (r_zapis) begin
                    dq_oe    <= r_quad ? 4'b1111 : 4'b0001;
                    wsr      <= wdane;
                    wpobierz <= 1'b1;
                    dq_o     <= r_quad ? wdane[7:4] : {3'b000, wdane[7]};
                end else
                    dq_oe <= 4'b0000;
            end else
                stan <= S_KONIEC;
        end
    endtask

    always @(posedge clk) begin
        wpobierz <= 1'b0;
        rwazne   <= 1'b0;
        if (rst) begin
            stan   <= S_SPOCZ;
            sclk   <= 1'b0;
            cs_n   <= 1'b1;
            dq_oe  <= 4'b0000;
            dq_o   <= 4'b0000;
            gotowy <= 1'b1;
        end else case (stan)
            S_SPOCZ:
                if (start) begin
                    gotowy  <= 1'b0;
                    cs_n    <= 1'b0;
                    stan    <= S_PRACA;
                    faza    <= F_ROZ;
                    t       <= DIV_1;
                    sr      <= {rozkaz, adres};
                    licz    <= z_adresem ? 12'd31 : 12'd7;
                    dq_oe   <= 4'b0001;
                    dq_o    <= {3'b000, rozkaz[7]};
                    r_puste <= puste;
                    r_dl    <= dlugosc;
                    r_zapis <= zapis;
                    r_quad  <= quad;
                end
            S_PRACA:
                if (t != 0) t <= t - 1'b1;
                else begin
                    t    <= DIV_1;
                    sclk <= !sclk;
                    if (!sclk) begin                                   // zbocze narastające: próbkowanie
                        if (faza == F_DANE && !r_zapis) begin
                            rsr <= r_quad ? {rsr[3:0], dq_i} : {rsr[6:0], dq_i[1]};
                            br  <= (br == ost_b) ? 3'd0 : br + 1'b1;
                            if (br == ost_b) begin
                                rdane  <= r_quad ? {rsr[3:0], dq_i} : {rsr[6:0], dq_i[1]};
                                rwazne <= 1'b1;
                            end
                        end
                    end else begin                                     // zbocze opadające: następny cykl
                        if (licz != 12'd0) begin
                            licz <= licz - 1'b1;
                            if (faza == F_ROZ) begin
                                sr   <= {sr[30:0], 1'b0};
                                dq_o <= {3'b000, sr[30]};
                            end else if (faza == F_DANE && r_zapis) begin
                                bw <= (bw == ost_b) ? 3'd0 : bw + 1'b1;
                                if (bw == ost_b) begin                 // następny bajt
                                    wsr      <= wdane;
                                    wpobierz <= 1'b1;
                                    dq_o     <= r_quad ? wdane[7:4] : {3'b000, wdane[7]};
                                end else begin
                                    wsr  <= r_quad ? {wsr[3:0], 4'd0} : {wsr[6:0], 1'b0};
                                    dq_o <= r_quad ? wsr[3:0] : {3'b000, wsr[6]};
                                end
                            end
                        end else if (faza == F_DANE)
                            stan <= S_KONIEC;
                        else
                            nastepna_faza(faza);
                    end
                end
            S_KONIEC:                                                  // czas od ostatniego zbocza do CS
                if (t != 0) t <= t - 1'b1;
                else begin
                    cs_n  <= 1'b1;
                    dq_oe <= 4'b0000;
                    t     <= DIV_1;
                    stan  <= S_CS;
                end
            default:                                                   // S_CS: minimalny czas CS nieaktywnego
                if (t != 0) t <= t - 1'b1;
                else begin
                    gotowy <= 1'b1;
                    stan   <= S_SPOCZ;
                end
        endcase
    end
endmodule

`default_nettype wire
