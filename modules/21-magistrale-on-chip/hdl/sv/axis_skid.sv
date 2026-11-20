// Bufor poślizgowy (skid buffer) AXI4-Stream (21.01): pełna przepustowość, wszystkie wyjścia
// z przerzutników — także s_ready, więc rozcina ścieżkę kombinacyjną ready w długim potoku.
// Gdy wyjście stoi (m_valid && !m_ready), przyjęty słowo trafia do bufora, a s_ready opada w następnym takcie.
`default_nettype none

module axis_skid #(
    parameter integer W = 8
) (
    input  logic         clk,
    input  logic         rst,
    input  logic [W-1:0] s_data,
    input  logic         s_last,
    input  logic         s_valid,
    output logic         s_ready,
    output logic  [W-1:0] m_data,
    output logic          m_last,
    output logic          m_valid,
    input  logic         m_ready
);
    logic [W:0] bufor;
    logic       pelny;

    assign s_ready = !pelny;

    always_ff @(posedge clk) begin
        if (rst) begin
            m_valid <= 1'b0;
            pelny   <= 1'b0;
        end else if (!m_valid || m_ready) begin             // rejestr wyjściowy wolny albo właśnie oddany
            if (pelny) begin
                {m_last, m_data} <= bufor;
                m_valid          <= 1'b1;
                pelny            <= 1'b0;
            end else begin
                {m_last, m_data} <= {s_last, s_data};
                m_valid          <= s_valid;
            end
        end else if (s_valid && !pelny) begin               // wyjście stoi, s_ready = 1: słowo do bufora
            bufor <= {s_last, s_data};
            pelny <= 1'b1;
        end
    end
endmodule

`default_nettype wire
