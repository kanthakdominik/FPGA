// Pakowanie strumienia bajtów w słowa 32-bitowe (pierwszy bajt w bitach [7:0]) z handshake valid/ready
// po obu stronach. Pełna przepustowość: bajt w każdym takcie, dopóki odbiorca słów nadąża.
// Reguły: dane przesyłane, gdy valid = 1 i ready = 1; m_valid i m_data nie zmieniają się, dopóki
// słowo nie zostanie odebrane. s_ready zależy kombinacyjnie od m_ready (tylko przy czwartym bajcie).
module pack4 (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  s_data,
    input  logic        s_valid,
    output logic        s_ready,
    output logic [31:0] m_data,
    output logic        m_valid = 1'b0,
    input  logic        m_ready
);
    logic [1:0]      cnt = '0;                 // liczba bajtów zebranych w acc
    logic [2:0][7:0] acc;
    logic            m_free, s_fire;

    assign m_free  = !m_valid || m_ready;      // rejestr wyjściowy wolny albo zwalniany w tym takcie
    assign s_ready = (cnt != 2'd3) || m_free;  // czwarty bajt tylko, gdy jest miejsce na słowo
    assign s_fire  = s_valid && s_ready;

    always_ff @(posedge clk) begin
        if (rst) begin
            cnt     <= '0;
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
                    acc[cnt] <= s_data;
                end
            end
        end
    end
endmodule
