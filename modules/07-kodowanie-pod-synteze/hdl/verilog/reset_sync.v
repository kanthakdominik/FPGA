// Synchronizator resetu: ustawienie asynchroniczne (od razu), zdjęcie synchroniczne (po STAGES taktach).
`default_nettype none

module reset_sync #(
    parameter STAGES = 2                       // co najmniej 2
) (
    input  wire clk,
    input  wire arst_n,                        // reset zewnętrzny, asynchroniczny, aktywny niski
    output wire rst                            // reset dla logiki, aktywny wysoki
);
    reg [STAGES-1:0] sync = {STAGES{1'b0}};    // po konfiguracji układ startuje w resecie

    always @(posedge clk or negedge arst_n)
        if (!arst_n) sync <= {STAGES{1'b0}};
        else         sync <= {sync[STAGES-2:0], 1'b1};

    assign rst = ~sync[STAGES-1];
endmodule

`default_nettype wire
