// Konwerter szerokości AXI4-Stream 8 -> 32 bity (21.01): bajty składane od najmłodszego (pierwszy bajt
// w bitach 7:0), TKEEP oznacza ważne bajty, TLAST w środku słowa kończy słowo niepełne.
`default_nettype none

module axis_8na32 (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  s_data,
    input  wire        s_last,
    input  wire        s_valid,
    output wire        s_ready,
    output reg  [31:0] m_data,
    output reg  [3:0]  m_keep,
    output reg         m_last,
    output reg         m_valid,
    input  wire        m_ready
);
    reg  [31:0] zb;                                  // bajty bieżącego słowa
    reg  [3:0]  zk;
    reg  [1:0]  i;
    wire [31:0] nd;
    wire [3:0]  nk;
    wire        wej = s_valid && s_ready;

    assign s_ready = !m_valid || m_ready;            // przyjmuj, gdy wyjście może przyjąć ewentualne słowo

    genvar k;
    generate
        for (k = 0; k < 4; k = k + 1) begin : g_bajt
            assign nd[k*8 +: 8] = (i == k) ? s_data : zb[k*8 +: 8];
            assign nk[k]        = (i == k) | zk[k];
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            m_valid <= 1'b0;
            i       <= 2'd0;
            zb      <= 32'd0;
            zk      <= 4'd0;
        end else begin
            if (m_valid && m_ready) m_valid <= 1'b0;
            if (wej) begin
                if (i == 2'd3 || s_last) begin       // słowo pełne albo koniec pakietu
                    m_data  <= nd;
                    m_keep  <= nk;
                    m_last  <= s_last;
                    m_valid <= 1'b1;
                    i       <= 2'd0;
                    zb      <= 32'd0;
                    zk      <= 4'd0;
                end else begin
                    zb <= nd;
                    zk <= nk;
                    i  <= i + 1'b1;
                end
            end
        end
    end
endmodule

`default_nettype wire
