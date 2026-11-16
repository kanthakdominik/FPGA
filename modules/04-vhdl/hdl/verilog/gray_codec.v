// Konwersja binarny <-> Gray i parzystość. Verilog nie ma pakietów —
// funkcje deklaruje się w module (albo w pliku dołączanym przez `include).
`default_nettype none

module gray_codec #(
    parameter integer W = 8
) (
    input  wire [W-1:0] bin_in,
    output wire [W-1:0] gray_out,
    input  wire [W-1:0] gray_in,
    output wire [W-1:0] bin_out,
    output wire         par                        // 1 przy nieparzystej liczbie jedynek w bin_in
);
    function [W-1:0] bin2gray(input [W-1:0] b);
        bin2gray = b ^ (b >> 1);
    endfunction

    function [W-1:0] gray2bin(input [W-1:0] g);
        integer i;
        begin
            gray2bin[W-1] = g[W-1];
            for (i = W - 2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ g[i];   // łańcuch XOR od najstarszego bitu
        end
    endfunction

    assign gray_out = bin2gray(bin_in);
    assign bin_out  = gray2bin(gray_in);
    assign par      = ^bin_in;                     // operator redukcji XOR
endmodule

`default_nettype wire
