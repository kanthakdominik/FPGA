// CRC-8 liczone bajt po bajcie (domyślnie wielomian 0x07, wartość początkowa 0x00).
module crc8 #(
    parameter logic [7:0] POLY = 8'h07
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       en,
    input  logic [7:0] data,
    output logic [7:0] crc
);
    function automatic logic [7:0] crc8_byte(logic [7:0] c, logic [7:0] d);
        logic [7:0] r = c ^ d;
        repeat (8)
            r = r[7] ? ((r << 1) ^ POLY) : (r << 1);
        return r;
    endfunction

    always_ff @(posedge clk) begin
        if (rst)     crc <= '0;
        else if (en) crc <= crc8_byte(crc, data);
    end
endmodule
