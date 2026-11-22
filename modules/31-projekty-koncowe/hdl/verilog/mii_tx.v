// Nadajnik MAC dla MII (25.03): ramka z bajtów strumienia (s_dane, s_wazne, s_ostatni, s_gotowy) -> preambuła
// (7 × 0x55), SFD (0xD5), dane, uzupełnienie zerami do 60 bajtów, FCS (CRC-32, najmłodszy bajt pierwszy),
// przerwa międzyramkowa 12 bajtów (24 takty). MII: 4 bity na takt tx_clk (25 MHz przy 100 Mb/s), młodsza połówka
// bajtu pierwsza. Źródło musi podawać bajty bez przerw (co drugi takt); brak bajtu w środku ramki kończy dane
// i ustawia przerwa (ramka zostanie wysłana skrócona, z poprawnym FCS).
`default_nettype none

module mii_tx (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] s_dane,
    input  wire       s_wazne,
    input  wire       s_ostatni,
    output wire       s_gotowy,
    output reg  [3:0] txd,
    output reg        tx_en,
    output reg        przerwa
);
    function [31:0] crc_bajt(input [31:0] c, input [7:0] d);
        reg [31:0] r;
        integer i;
        begin
            r = c ^ {24'd0, d};
            for (i = 0; i < 8; i = i + 1) r = r[0] ? ((r >> 1) ^ 32'hEDB88320) : (r >> 1);
            crc_bajt = r;
        end
    endfunction

    localparam [2:0] S_BEZCZ = 3'd0, S_PREAMB = 3'd1, S_DANE = 3'd2, S_UZUP = 3'd3, S_FCS = 3'd4, S_IFG = 3'd5;
    reg  [2:0]  stan;
    reg  [4:0]  n;                              // licznik połówek bajtu w preambule, FCS i przerwie
    reg         h;                              // 0 — młodsza połówka, 1 — starsza
    reg  [3:0]  bh;                             // starsza połówka bieżącego bajtu
    reg  [10:0] dl;                             // bajty wysłane (dane + uzupełnienie)
    reg  [31:0] crc;
    reg         ost;
    assign s_gotowy = (stan == S_DANE) && !h;
    wire [7:0]  bajt  = (stan == S_DANE && s_wazne) ? s_dane : 8'd0;
    wire [31:0] crc_n = crc_bajt(crc, bajt);
    wire [31:0] fcs   = ~crc;

    always @(posedge clk) begin
        przerwa <= 1'b0;
        if (rst) begin
            stan <= S_BEZCZ; n <= 5'd0; h <= 1'b0; bh <= 4'd0; dl <= 11'd0; crc <= 32'hFFFFFFFF; ost <= 1'b0;
            txd <= 4'd0; tx_en <= 1'b0;
        end else case (stan)
            S_BEZCZ: begin
                tx_en <= 1'b0;
                txd   <= 4'd0;
                if (s_wazne) begin stan <= S_PREAMB; n <= 5'd0; end
            end
            S_PREAMB: begin                                  // 15 × 0x5, potem 0xD (SFD = 0xD5)
                tx_en <= 1'b1;
                txd   <= (n == 5'd15) ? 4'hD : 4'h5;
                n     <= n + 1'b1;
                if (n == 5'd15) begin stan <= S_DANE; h <= 1'b0; dl <= 11'd0; crc <= 32'hFFFFFFFF; end
            end
            S_DANE, S_UZUP: begin
                if (!h) begin
                    bh  <= bajt[7:4];
                    txd <= bajt[3:0];
                    crc <= crc_n;
                    dl  <= dl + 1'b1;
                    h   <= 1'b1;
                    if (stan == S_DANE && !s_wazne) begin    // brak danych: bajt zerowy i koniec danych
                        przerwa <= 1'b1;
                        stan    <= S_UZUP;
                        ost     <= (dl >= 11'd59);
                    end else
                        ost <= (stan == S_UZUP) ? (dl >= 11'd59) : s_ostatni;
                end else begin
                    txd <= bh;
                    h   <= 1'b0;
                    if (ost || (stan == S_DANE && dl == 11'd2047)) begin
                        stan <= (dl < 11'd60) ? S_UZUP : S_FCS;
                        n    <= 5'd0;
                        ost  <= 1'b0;
                    end
                end
            end
            S_FCS: begin                                     // 8 połówek, najmłodsza pierwsza
                txd <= fcs[{n[2:0], 2'b00} +: 4];
                n   <= n + 1'b1;
                if (n == 5'd7) begin stan <= S_IFG; n <= 5'd0; end
            end
            default: begin                                   // przerwa międzyramkowa: 24 takty
                tx_en <= 1'b0;
                txd   <= 4'd0;
                n     <= n + 1'b1;
                if (n == 5'd23) stan <= S_BEZCZ;
            end
        endcase
    end
endmodule

`default_nettype wire
