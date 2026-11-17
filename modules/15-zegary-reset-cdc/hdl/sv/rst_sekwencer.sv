// Reset dwóch domen z kolejnością zwalniania (15.06). arst_n (przycisk, brak synchronizacji PLL) ustawia
// reset w obu domenach natychmiast i asynchronicznie. Zdjęcie: najpierw domena A (po STAGES taktach clk_a),
// potem domena B — dopiero gdy informacja "A pracuje" dotrze do domeny B przez synchronizator
// (np. B jest konsumentem danych z A i nie może startować wcześniej niż producent).
// Każdy reset jest zdejmowany synchronicznie ze swoim zegarem — brak naruszeń recovery/removal.
module rst_sekwencer #(
    parameter int STAGES = 2
) (
    input  logic arst_n,
    input  logic clk_a,
    output logic rst_a,
    input  logic clk_b,
    output logic rst_b
);
    logic [STAGES-1:0] sync_a = '0, sync_b = '0;

    always_ff @(posedge clk_a or negedge arst_n)
        if (!arst_n) sync_a <= '0;
        else         sync_a <= {sync_a[STAGES-2:0], 1'b1};
    assign rst_a = ~sync_a[STAGES-1];

    always_ff @(posedge clk_b or negedge arst_n)
        if (!arst_n) sync_b <= '0;
        else         sync_b <= {sync_b[STAGES-2:0], sync_a[STAGES-1]};
    assign rst_b = ~sync_b[STAGES-1];
endmodule
