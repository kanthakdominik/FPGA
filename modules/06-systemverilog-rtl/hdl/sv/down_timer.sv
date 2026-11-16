// Timer odliczający w dół z automatycznym przeładowaniem: impuls tick co (period + 1) taktów zezwolenia.
// Styl dwóch bloków: always_comb liczy wartości następne, always_ff tylko je zapamiętuje.
module down_timer #(
    parameter int W = 16
) (
    input  logic         clk,
    input  logic         rst,                      // synchroniczny
    input  logic         en,                       // takt odliczania (np. z prescalera)
    input  logic         load,                     // natychmiastowe załadowanie period
    input  logic [W-1:0] period,
    output logic [W-1:0] count,
    output logic         tick                      // 1 takt, gdy licznik przechodzi przez zero
);
    logic [W-1:0] count_next;
    logic         tick_next;

    always_comb begin
        count_next = count;                        // wartości domyślne: brak zatrzasków
        tick_next  = 1'b0;
        if (load)
            count_next = period;
        else if (en) begin
            if (count == '0) begin
                count_next = period;               // przeładowanie
                tick_next  = 1'b1;
            end else
                count_next = count - 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            count <= '0;
            tick  <= 1'b0;
        end else begin
            count <= count_next;
            tick  <= tick_next;
        end
    end
endmodule
