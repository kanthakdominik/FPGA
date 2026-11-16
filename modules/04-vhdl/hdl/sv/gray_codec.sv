// Konwersja binarny <-> Gray i parzystość, z użyciem funkcji z pakietu gray_pkg (W <= 32).
module gray_codec
    import gray_pkg::*;                            // import pakietu w nagłówku modułu
#(
    parameter int W = 8
) (
    input  logic [W-1:0] bin_in,
    output logic [W-1:0] gray_out,
    input  logic [W-1:0] gray_in,
    output logic [W-1:0] bin_out,
    output logic         par                       // 1 przy nieparzystej liczbie jedynek w bin_in
);
    assign gray_out = W'(bin2gray(32'(bin_in)));
    assign bin_out  = W'(gray2bin(32'(gray_in)));
    assign par      = parity(32'(bin_in));
endmodule
