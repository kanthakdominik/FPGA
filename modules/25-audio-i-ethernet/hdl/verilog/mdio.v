// Master MDIO (25.03, IEEE 802.3 klauzula 22): odczyt i zapis rejestrów PHY. Ramka: 32 jedynki preambuły,
// ST = 01, OP (10 — odczyt, 01 — zapis), adres PHY (5 bitów), rejestr (5 bitów), TA, 16 bitów danych.
// MDC = clk / (2·DIV) (≤ 2,5 MHz). Master zmienia MDIO przy opadającym MDC; przy odczycie zwalnia linię od TA,
// a dane PHY (wystawiane po narastającym MDC poprzedniego bitu) próbkuje przy narastającym MDC.
`default_nettype none

module mdio #(
    parameter integer DIV = 10                  // 50 MHz / 20 = 2,5 MHz
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        zapis,
    input  wire [4:0]  phy,
    input  wire [4:0]  rej,
    input  wire [15:0] wdane,
    output reg  [15:0] rdane,
    output reg         gotowe,
    output reg         zajety,
    output reg         mdc,
    output reg         mdio_o,
    output reg         mdio_oe,
    input  wire        mdio_i
);
    /* verilator lint_off WIDTHTRUNC */
    localparam [15:0] D1 = DIV - 1;
    /* verilator lint_on WIDTHTRUNC */
    reg  [15:0] t;
    reg  [6:0]  b;                              // numer bitu 0..64 (64 — takt kończący)
    reg  [63:0] ramka;
    reg         r_zapis;

    always @(posedge clk) begin
        gotowe <= 1'b0;
        if (rst) begin
            t <= 16'd0; b <= 7'd0; ramka <= 64'd0; r_zapis <= 1'b0; rdane <= 16'd0; zajety <= 1'b0;
            mdc <= 1'b0; mdio_o <= 1'b1; mdio_oe <= 1'b0;
        end else if (!zajety) begin
            mdc <= 1'b0;
            if (start) begin
                zajety  <= 1'b1;
                r_zapis <= zapis;
                ramka   <= {32'hFFFFFFFF, 2'b01, zapis ? 2'b01 : 2'b10, phy, rej, zapis ? 2'b10 : 2'b11, zapis ? wdane : 16'hFFFF};
                b       <= 7'd0;
                t       <= 16'd0;
                mdio_oe <= 1'b1;
                mdio_o  <= 1'b1;                                  // bit 0 preambuły
            end
        end else if (t != D1) begin
            t <= t + 1'b1;
        end else begin
            t   <= 16'd0;
            mdc <= ~mdc;
            if (!mdc) begin                                       // narastające MDC: próbkowanie
                if (!r_zapis && b >= 7'd48 && b < 7'd64) rdane <= {rdane[14:0], mdio_i};
            end else begin                                        // opadające MDC: następny bit
                if (b == 7'd64) begin
                    zajety  <= 1'b0;
                    gotowe  <= 1'b1;
                    mdio_oe <= 1'b0;
                end else begin
                    b       <= b + 1'b1;
                    mdio_o  <= (b == 7'd63) ? 1'b1 : ramka[6'd62 - b[5:0]];
                    mdio_oe <= (b == 7'd63) ? 1'b0 : (r_zapis || b < 7'd45);
                end
            end
        end
    end
endmodule

`default_nettype wire
