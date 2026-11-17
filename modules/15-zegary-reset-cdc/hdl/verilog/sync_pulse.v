// Synchronizator impulsu przez przełącznik (toggle), 15.03: impuls src_pulse (1 takt clk_src) zmienia stan
// przerzutnika tgl; poziom tgl przechodzi przez sync_bit, a zmiana stanu w domenie docelowej daje impuls
// dst_pulse (1 takt clk_dst). Kolejny impuls wolno podać dopiero, gdy poprzedni dotarł: busy = 1 przez czas
// przejścia tam i z powrotem (potwierdzenie zsynchronizowane z powrotem do clk_src).
`default_nettype none

module sync_pulse #(
    parameter STAGES = 2
) (
    input  wire clk_src,
    input  wire rst_src,
    input  wire src_pulse,                     // ignorowany, gdy busy
    output wire busy,
    input  wire clk_dst,
    input  wire rst_dst,
    output reg  dst_pulse
);
    // domena źródłowa: przełącznik
    reg tgl = 1'b0;
    always @(posedge clk_src)
        if (rst_src)                tgl <= 1'b0;
        else if (src_pulse && !busy) tgl <= ~tgl;

    // domena docelowa: synchronizacja i wykrycie zmiany
    wire tgl_dst;
    reg  tgl_dst_d = 1'b0;
    sync_bit #(.STAGES(STAGES)) u_sync_dst (.clk(clk_dst), .d(tgl), .q(tgl_dst));
    always @(posedge clk_dst) begin
        if (rst_dst) begin
            tgl_dst_d <= 1'b0;
            dst_pulse <= 1'b0;
        end else begin
            tgl_dst_d <= tgl_dst;
            dst_pulse <= tgl_dst ^ tgl_dst_d;
        end
    end

    // potwierdzenie: stan odebrany w domenie docelowej wraca do źródłowej
    wire ack_src;
    sync_bit #(.STAGES(STAGES)) u_sync_ack (.clk(clk_src), .d(tgl_dst_d), .q(ack_src));
    assign busy = (tgl != ack_src);
endmodule

`default_nettype wire
