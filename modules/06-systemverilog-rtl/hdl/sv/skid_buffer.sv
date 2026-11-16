// Rejestr potokowy strumienia valid/ready z buforem „skid”: wszystkie wyjścia (także ready) z rejestrów,
// pełna przepustowość — jedno słowo na takt. Porty jako interfejsy z modportami.
module skid_buffer #(
    parameter int W = 8
) (
    input logic      clk,
    input logic      rst,
    stream_if.sink   s,                            // wejście: odbieramy od nadawcy
    stream_if.source m                             // wyjście: nadajemy do odbiorcy
);
    logic [W-1:0] main_data, skid_data;
    logic         main_valid, skid_valid;

    assign s.ready = ~skid_valid;                  // przyjmujemy, dopóki bufor skid jest pusty
    assign m.valid = main_valid;
    assign m.data  = main_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            main_valid <= 1'b0;
            skid_valid <= 1'b0;
        end else if (m.ready || !main_valid) begin // rejestr główny może przyjąć nowe słowo
            if (skid_valid) begin
                main_data  <= skid_data;           // najpierw słowo czekające w buforze
                main_valid <= 1'b1;
                skid_valid <= 1'b0;
            end else begin
                main_data  <= s.data;
                main_valid <= s.valid;
            end
        end else if (s.valid && s.ready) begin     // wyjście zablokowane, a słowo już przyjęte
            skid_data  <= s.data;
            skid_valid <= 1'b1;
        end
    end
endmodule
