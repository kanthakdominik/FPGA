// Uśrednianie z decymacją (20.06): suma 2^K kolejnych próbek, wynik = suma >> K co 2^K próbek.
// Szum nieskorelowany maleje √(2^K) razy (K = 6: 8 razy, ok. 3 bity rozdzielczości więcej).
`default_nettype none

module adc_srednia #(
    parameter W = 12,
    parameter K = 6
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         wazne,
    input  wire [W-1:0] dane,
    output reg          wyj_wazne = 1'b0,
    output reg  [W-1:0] srednia = {W{1'b0}}
);
    reg [W+K-1:0] suma = {(W+K){1'b0}};
    reg [K-1:0]   licz = {K{1'b0}};
    wire [W+K-1:0] nowa = suma + {{K{1'b0}}, dane};

    always @(posedge clk) begin
        wyj_wazne <= 1'b0;
        if (rst) begin
            suma <= {(W+K){1'b0}};
            licz <= {K{1'b0}};
        end else if (wazne) begin
            licz <= licz + 1'b1;
            if (&licz) begin                              // 2^K-ta próbka
                srednia   <= nowa[W+K-1:K];
                wyj_wazne <= 1'b1;
                suma      <= {(W+K){1'b0}};
            end else
                suma <= nowa;
        end
    end
endmodule

`default_nettype wire
