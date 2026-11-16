// Suma kontrolna Internetu (RFC 1071): suma słów 16-bitowych z przeniesieniem dodawanym z powrotem.
module inet_checksum (
    input  logic        clk,
    input  logic        clear,
    input  logic        valid,
    input  logic [15:0] word,
    output logic [15:0] sum,
    output logic [15:0] checksum
);
    logic [16:0] tmp;

    assign tmp = sum + word;                       // lewa strona 17 bitów: przeniesienie zachowane

    always_ff @(posedge clk) begin
        if (clear)      sum <= '0;
        else if (valid) sum <= tmp[15:0] + 16'(tmp[16]);
    end

    assign checksum = ~sum;
endmodule
