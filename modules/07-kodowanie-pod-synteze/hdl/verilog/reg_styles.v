// Trzy rejestry z tym samym wejściem: reset asynchroniczny, reset synchroniczny i bez resetu.
`default_nettype none

module reg_styles #(
    parameter W = 8
) (
    input  wire         clk,
    input  wire         arst,                  // asynchroniczny, aktywny wysoki
    input  wire         srst,                  // synchroniczny, aktywny wysoki
    input  wire [W-1:0] d,
    output reg  [W-1:0] q_async,
    output reg  [W-1:0] q_sync,
    output reg  [W-1:0] q_none
);
    always @(posedge clk or posedge arst)      // reset na liście wrażliwości
        if (arst) q_async <= {W{1'b0}};
        else      q_async <= d;

    always @(posedge clk)                      // reset sprawdzany tylko na zboczu zegara
        if (srst) q_sync <= {W{1'b0}};
        else      q_sync <= d;

    always @(posedge clk)                      // rejestr danych bez resetu
        q_none <= d;
endmodule

`default_nettype wire
