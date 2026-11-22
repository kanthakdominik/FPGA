// Zadanie 11: skid buffer — stopień potoku z handshakiem valid/ready (jak AXI4-Stream), który ma rejestrowane
// zarówno wyjście danych, jak i s_ready (brak ścieżki kombinacyjnej m_ready -> s_ready), a mimo to przenosi
// słowo w każdym takcie. Gdy odbiorca zatrzyma się w chwili, w której przyjęliśmy słowo, trafia ono do
// rejestru „poślizgu” (skid), a s_ready spada dopiero w następnym takcie.
`default_nettype none

module skid_buffer #(
    parameter integer W = 8
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         s_valid,
    output logic         s_ready,
    input  logic [W-1:0] s_data,
    output logic          m_valid = 1'b0,
    input  logic         m_ready,
    output logic  [W-1:0] m_data = {W{1'b0}}
);
    logic         skid_v = 1'b0;
    logic [W-1:0] skid_d = {W{1'b0}};

    assign s_ready = !skid_v;               // rejestr: zależy tylko od stanu

    always_ff @(posedge clk)
        if (rst) begin
            m_valid <= 1'b0;
            skid_v  <= 1'b0;
        end else if (m_ready || !m_valid) begin
            // wyjście wolne albo właśnie oddaje słowo
            if (skid_v) begin
                m_data  <= skid_d;
                m_valid <= 1'b1;
                skid_v  <= 1'b0;
            end else begin
                m_data  <= s_data;
                m_valid <= s_valid;
            end
        end else if (s_valid && s_ready) begin
            // wyjście stoi, a słowo zostało przyjęte — do rejestru poślizgu
            skid_d <= s_data;
            skid_v <= 1'b1;
        end
endmodule

`default_nettype wire
