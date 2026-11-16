// Synchronizator resetu: ustawienie asynchroniczne (od razu), zdjęcie synchroniczne (po STAGES taktach).
module reset_sync #(
    parameter int STAGES = 2                   // co najmniej 2
) (
    input  logic clk,
    input  logic arst_n,                       // reset zewnętrzny, asynchroniczny, aktywny niski
    output logic rst                           // reset dla logiki, aktywny wysoki
);
    logic [STAGES-1:0] sync = '0;              // po konfiguracji układ startuje w resecie

    always_ff @(posedge clk or negedge arst_n)
        if (!arst_n) sync <= '0;
        else         sync <= {sync[STAGES-2:0], 1'b1};

    assign rst = ~sync[STAGES-1];
endmodule
