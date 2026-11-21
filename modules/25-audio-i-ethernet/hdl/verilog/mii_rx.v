// Odbiornik MAC dla MII (25.03): szuka preambuły (0x5…) i SFD (0xD), składa bajty z połówek (młodsza pierwsza),
// podaje bajty danych (m_dane, m_wazne) z opóźnieniem 4 bajtów — ostatnie 4 bajty ramki to FCS i nie są
// przekazywane. Na końcu ramki (rx_dv = 0) impuls koniec z crc_ok (CRC-32 liczone po danych i FCS daje stałą
// resztę 0xDEBB20E3), dlugosc (bajty bez FCS) i blad (rx_er w ramce albo niepełny bajt).
`default_nettype none

module mii_rx (
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  rxd,
    input  wire        rx_dv,
    input  wire        rx_er,
    output reg  [7:0]  m_dane,
    output reg         m_wazne,
    output reg         koniec,
    output reg         crc_ok,
    output reg  [10:0] dlugosc,
    output reg         blad
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

    localparam [1:0] S_BEZCZ = 2'd0, S_PREAMB = 2'd1, S_DANE = 2'd2, S_POMIN = 2'd3;
    reg  [1:0]  stan;
    reg         h;
    reg  [3:0]  mlodsza;
    reg  [31:0] opozn;                          // 4 ostatnie bajty (najstarszy w bitach 31..24)
    reg  [10:0] n;
    reg  [31:0] crc;
    reg         er;
    wire [7:0]  bajt  = {rxd, mlodsza};
    wire [31:0] crc_n = crc_bajt(crc, bajt);

    always @(posedge clk) begin
        m_wazne <= 1'b0;
        koniec  <= 1'b0;
        if (rst) begin
            stan <= S_BEZCZ; h <= 1'b0; mlodsza <= 4'd0; opozn <= 32'd0; n <= 11'd0; crc <= 32'hFFFFFFFF;
            er <= 1'b0; m_dane <= 8'd0; crc_ok <= 1'b0; dlugosc <= 11'd0; blad <= 1'b0;
        end else case (stan)
            S_BEZCZ:
                if (rx_dv) stan <= (rxd == 4'h5) ? S_PREAMB : S_POMIN;
            S_PREAMB:
                if (!rx_dv)            stan <= S_BEZCZ;
                else if (rxd == 4'hD) begin
                    stan <= S_DANE; h <= 1'b0; n <= 11'd0; crc <= 32'hFFFFFFFF; er <= rx_er;
                end else if (rxd != 4'h5) stan <= S_POMIN;
            S_DANE:
                if (!rx_dv) begin                                     // koniec ramki
                    koniec  <= 1'b1;
                    crc_ok  <= (crc == 32'hDEBB20E3) && !h && !er && (n >= 11'd4);
                    blad    <= er || h;
                    dlugosc <= (n >= 11'd4) ? n - 11'd4 : 11'd0;
                    stan    <= S_BEZCZ;
                end else begin
                    if (rx_er) er <= 1'b1;
                    if (!h) begin
                        mlodsza <= rxd;
                        h       <= 1'b1;
                    end else begin
                        h     <= 1'b0;
                        crc   <= crc_n;
                        opozn <= {opozn[23:0], bajt};
                        if (n != 11'd2047) n <= n + 1'b1;
                        if (n >= 11'd4) begin m_dane <= opozn[31:24]; m_wazne <= 1'b1; end
                    end
                end
            default:                                                  // ramka niepoprawna: czekaj na koniec
                if (!rx_dv) stan <= S_BEZCZ;
        endcase
    end
endmodule

`default_nettype wire
