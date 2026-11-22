// CRC-32 (IEEE 802.3, wielomian odbity 0xEDB88320, wartość początkowa i końcowa negacja) liczone bajt po
// bajcie (29.02): sprawdzenie obrazu konfiguracji przed przełączeniem. zeruj — nowy obraz, we — kolejny bajt;
// crc — wynik dla dotychczasowych bajtów. Wartość kontrolna: "123456789" -> 0xCBF43926.
`default_nettype none

module crc32 (
    input  logic        clk,
    input  logic        zeruj,
    input  logic        we,
    input  logic [7:0]  bajt,
    output logic [31:0] crc
);
    logic [31:0] r = 32'hFFFF_FFFF;

    function [31:0] krok(input [31:0] c, input [7:0] b);
        integer i;
        logic [31:0] t;
        begin
            t = c ^ {24'd0, b};
            for (i = 0; i < 8; i = i + 1)
                t = t[0] ? (t >> 1) ^ 32'hEDB8_8320 : (t >> 1);
            krok = t;
        end
    endfunction

    logic [31:0] nast;
    assign nast = krok(r, bajt);
    always_ff @(posedge clk)
        if (zeruj)   r <= 32'hFFFF_FFFF;
        else if (we) r <= nast;

    assign crc = ~r;
endmodule

`default_nettype wire
