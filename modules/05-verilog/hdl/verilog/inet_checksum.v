// Suma kontrolna Internetu (RFC 1071): suma 16-bitowych słów w arytmetyce uzupełnienia do jedynki.
// Przeniesienie z najstarszego bitu jest dodawane z powrotem do najmłodszego (end-around carry).
`default_nettype none

module inet_checksum (
    input  wire        clk,
    input  wire        clear,                      // synchroniczne zerowanie sumy
    input  wire        valid,                      // przyjęcie słowa
    input  wire [15:0] word,
    output reg  [15:0] sum,
    output wire [15:0] checksum                    // wartość do wpisania w nagłówek
);
    wire [16:0] tmp = sum + word;                  // 17 bitów: przeniesienie nie ginie

    always @(posedge clk) begin
        if (clear)      sum <= 16'h0000;
        else if (valid) sum <= tmp[15:0] + tmp[16];   // przeniesienie wraca na pozycję 0
    end

    assign checksum = ~sum;
endmodule

`default_nettype wire
