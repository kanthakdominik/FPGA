// Trzy rejestry z tym samym wejściem: reset asynchroniczny, reset synchroniczny i bez resetu.
module reg_styles #(
    parameter int W = 8
) (
    input  logic         clk,
    input  logic         arst,                 // asynchroniczny, aktywny wysoki
    input  logic         srst,                 // synchroniczny, aktywny wysoki
    input  logic [W-1:0] d,
    output logic [W-1:0] q_async,
    output logic [W-1:0] q_sync,
    output logic [W-1:0] q_none
);
    always_ff @(posedge clk or posedge arst)   // reset na liście wrażliwości
        if (arst) q_async <= '0;
        else      q_async <= d;

    always_ff @(posedge clk)                   // reset sprawdzany tylko na zboczu zegara
        if (srst) q_sync <= '0;
        else      q_sync <= d;

    always_ff @(posedge clk)                   // rejestr danych bez resetu
        q_none <= d;
endmodule
