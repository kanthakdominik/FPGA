// Reset dwóch domen z kolejnością zwalniania (15.06). arst_n (przycisk, brak synchronizacji PLL) ustawia
// reset w obu domenach natychmiast i asynchronicznie. Zdjęcie: najpierw domena A (po STAGES taktach clk_a),
// potem domena B — dopiero gdy informacja "A pracuje" dotrze do domeny B przez synchronizator
// (np. B jest konsumentem danych z A i nie może startować wcześniej niż producent).
// Każdy reset jest zdejmowany synchronicznie ze swoim zegarem — brak naruszeń recovery/removal.
`default_nettype none

module rst_sekwencer #(
    parameter STAGES = 2
) (
    input  wire arst_n,
    input  wire clk_a,
    output wire rst_a,
    input  wire clk_b,
    output wire rst_b
);
    // domena A: synchronizator resetu (asynchroniczne ustawienie, synchroniczne zdjęcie)
    reg [STAGES-1:0] sync_a = {STAGES{1'b0}};
    always @(posedge clk_a or negedge arst_n)
        if (!arst_n) sync_a <= {STAGES{1'b0}};
        else         sync_a <= {sync_a[STAGES-2:0], 1'b1};
    assign rst_a = ~sync_a[STAGES-1];

    // domena B: wejście łańcucha = "A już pracuje"; ten sam synchronizator resetu
    reg [STAGES-1:0] sync_b = {STAGES{1'b0}};
    always @(posedge clk_b or negedge arst_n)
        if (!arst_n) sync_b <= {STAGES{1'b0}};
        else         sync_b <= {sync_b[STAGES-2:0], sync_a[STAGES-1]};
    assign rst_b = ~sync_b[STAGES-1];
endmodule

`default_nettype wire
