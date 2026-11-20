// Dekoder adresu Wishbone (21.04): jeden master, dwa slave'y w trybie potokowym z opóźnieniem odpowiedzi
// 1 takt. Adres słowa 10 bitów: 0x000–0x1FF -> slave 0 (pamięć), 0x200–0x20F -> slave 1 (rejestry),
// reszta -> ERR z dekodera. Odpowiedzi wracają w kolejności żądań, bo obaj slave'y mają to samo opóźnienie.
`default_nettype none

module wb_dekoder (
    input  logic        clk,
    input  logic        rst,
    // master
    input  logic        m_cyc,
    input  logic        m_stb,
    input  logic        m_we,
    input  logic [9:0]  m_adr,
    input  logic [31:0] m_dat_i,
    input  logic [3:0]  m_sel,
    output logic [31:0] m_dat_o,
    output logic        m_ack,
    output logic        m_err,
    output logic        m_stall,
    // slave 0
    output logic        s0_stb,
    output logic [8:0]  s0_adr,
    input  logic [31:0] s0_dat_o,
    input  logic        s0_ack,
    input  logic        s0_stall,
    // slave 1
    output logic        s1_stb,
    output logic [3:0]  s1_adr,
    input  logic [31:0] s1_dat_o,
    input  logic        s1_ack,
    input  logic        s1_err,
    input  logic        s1_stall,
    // wspólne do slave'ów
    output logic        s_cyc,
    output logic        s_we,
    output logic [31:0] s_dat_i,
    output logic [3:0]  s_sel
);
    logic w0;
    assign w0 = !m_adr[9];
    logic w1;
    assign w1 = (m_adr[9:4] == 6'b100000);
    logic  err_d;

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

    always_ff @(posedge clk) begin
        if (rst || !m_cyc) err_d <= 1'b0;
        else               err_d <= m_stb && !w0 && !w1;          // brak slave'a pod adresem
    end
endmodule

`default_nettype wire
