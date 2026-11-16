// CRC-8 liczone bajt po bajcie (wielomian x^8 + x^2 + x + 1 = 0x07, wartość początkowa 0x00).
// Wielomian można zmienić dyrektywą `define przed kompilacją; funkcja liczy jeden bajt.
`default_nettype none

`ifndef CRC8_POLY
    `define CRC8_POLY 8'h07
`endif

module crc8 (
    input  wire       clk,
    input  wire       rst,                         // synchroniczny: crc = 0
    input  wire       en,                          // przyjęcie bajtu data
    input  wire [7:0] data,
    output reg  [7:0] crc
);
    // funkcja: logika kombinacyjna wstawiana w miejscu wywołania
    function [7:0] crc8_byte(input [7:0] c, input [7:0] d);
        integer i;
        reg [7:0] r;
        begin
            r = c ^ d;
            for (i = 0; i < 8; i = i + 1)
                r = r[7] ? ((r << 1) ^ `CRC8_POLY) : (r << 1);
            crc8_byte = r;
        end
    endfunction

    always @(posedge clk) begin
        if (rst)     crc <= 8'h00;
        else if (en) crc <= crc8_byte(crc, data);
    end
endmodule

`default_nettype wire
