// Pakowanie strumienia bajtów w słowa 32-bitowe (pierwszy bajt w bitach [7:0]) z handshake valid/ready
// po obu stronach. Pełna przepustowość: bajt w każdym takcie, dopóki odbiorca słów nadąża.
// Reguły: dane przesyłane, gdy valid = 1 i ready = 1; m_valid i m_data nie zmieniają się, dopóki
// słowo nie zostanie odebrane. s_ready zależy kombinacyjnie od m_ready (tylko przy czwartym bajcie).
`default_nettype none

module pack4 (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  s_data,
    input  wire        s_valid,
    output wire        s_ready,
    output reg  [31:0] m_data,
    output reg         m_valid = 1'b0,
    input  wire        m_ready
);
    reg [1:0]  cnt = 2'd0;                     // liczba bajtów zebranych w acc
    reg [23:0] acc;
    wire       m_free = !m_valid || m_ready;   // rejestr wyjściowy wolny albo zwalniany w tym takcie
    wire       s_fire = s_valid && s_ready;

    assign s_ready = (cnt != 2'd3) || m_free;  // czwarty bajt tylko, gdy jest miejsce na słowo

    always @(posedge clk) begin
        if (rst) begin
            cnt     <= 2'd0;
            m_valid <= 1'b0;
        end else begin
            if (m_valid && m_ready)
                m_valid <= 1'b0;               // słowo odebrane
            if (s_fire) begin
                cnt <= cnt + 2'd1;
                if (cnt == 2'd3) begin
                    m_data  <= {s_data, acc};
                    m_valid <= 1'b1;           // nadpisuje zerowanie powyżej — nowe słowo
                end else begin
                    acc[{cnt, 3'b000} +: 8] <= s_data;
                end
            end
        end
    end
endmodule

`default_nettype wire
