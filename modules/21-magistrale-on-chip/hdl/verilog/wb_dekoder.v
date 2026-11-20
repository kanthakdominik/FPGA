// Dekoder adresu Wishbone (21.04): jeden master, dwa slave'y w trybie potokowym z opóźnieniem odpowiedzi
// 1 takt. Adres słowa 10 bitów: 0x000–0x1FF -> slave 0 (pamięć), 0x200–0x20F -> slave 1 (rejestry),
// reszta -> ERR z dekodera. Odpowiedzi wracają w kolejności żądań, bo obaj slave'y mają to samo opóźnienie.
`default_nettype none

module wb_dekoder (
    input  wire        clk,
    input  wire        rst,
    // master
    input  wire        m_cyc,
    input  wire        m_stb,
    input  wire        m_we,
    input  wire [9:0]  m_adr,
    input  wire [31:0] m_dat_i,
    input  wire [3:0]  m_sel,
    output wire [31:0] m_dat_o,
    output wire        m_ack,
    output wire        m_err,
    output wire        m_stall,
    // slave 0
    output wire        s0_stb,
    output wire [8:0]  s0_adr,
    input  wire [31:0] s0_dat_o,
    input  wire        s0_ack,
    input  wire        s0_stall,
    // slave 1
    output wire        s1_stb,
    output wire [3:0]  s1_adr,
    input  wire [31:0] s1_dat_o,
    input  wire        s1_ack,
    input  wire        s1_err,
    input  wire        s1_stall,
    // wspólne do slave'ów
    output wire        s_cyc,
    output wire        s_we,
    output wire [31:0] s_dat_i,
    output wire [3:0]  s_sel
);
    wire w0  = !m_adr[9];
    wire w1  = (m_adr[9:4] == 6'b100000);
    reg  err_d;

    assign s_cyc   = m_cyc;
    assign s_we    = m_we;
    assign s_dat_i = m_dat_i;
    assign s_sel   = m_sel;
    assign s0_stb  = m_stb && w0;
    assign s1_stb  = m_stb && w1;
    assign s0_adr  = m_adr[8:0];
    assign s1_adr  = m_adr[3:0];
    assign m_stall = w0 ? s0_stall : (w1 ? s1_stall : 1'b0);
    assign m_ack   = s0_ack | s1_ack;
    assign m_err   = s1_err | err_d;
    assign m_dat_o = s1_ack ? s1_dat_o : s0_dat_o;

    always @(posedge clk) begin
        if (rst || !m_cyc) err_d <= 1'b0;
        else               err_d <= m_stb && !w0 && !w1;          // brak slave'a pod adresem
    end
endmodule

`default_nettype wire
