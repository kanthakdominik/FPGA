// Synchronizator impulsu przez przełącznik (toggle), 15.03: impuls src_pulse (1 takt clk_src) zmienia stan
// przerzutnika tgl; poziom tgl przechodzi przez sync_bit, a zmiana stanu w domenie docelowej daje impuls
// dst_pulse (1 takt clk_dst). Kolejny impuls wolno podać dopiero, gdy poprzedni dotarł: busy = 1 przez czas
// przejścia tam i z powrotem (potwierdzenie zsynchronizowane z powrotem do clk_src).
module sync_pulse #(
    parameter int STAGES = 2
) (
    input  logic clk_src,
    input  logic rst_src,
    input  logic src_pulse,                    // ignorowany, gdy busy
    output logic busy,
    input  logic clk_dst,
    input  logic rst_dst,
    output logic dst_pulse
);
    logic tgl = 1'b0, tgl_dst, tgl_dst_d = 1'b0, ack_src;

    always_ff @(posedge clk_src)
        if (rst_src)                 tgl <= 1'b0;
        else if (src_pulse && !busy) tgl <= ~tgl;

    sync_bit #(.STAGES(STAGES)) u_sync_dst (.clk(clk_dst), .d(tgl), .q(tgl_dst));
    always_ff @(posedge clk_dst)
        if (rst_dst) begin
            tgl_dst_d <= 1'b0;
            dst_pulse <= 1'b0;
        end else begin
            tgl_dst_d <= tgl_dst;
            dst_pulse <= tgl_dst ^ tgl_dst_d;
        end

    sync_bit #(.STAGES(STAGES)) u_sync_ack (.clk(clk_src), .d(tgl_dst_d), .q(ack_src));
    assign busy = (tgl != ack_src);
endmodule
