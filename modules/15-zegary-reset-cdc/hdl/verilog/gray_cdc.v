// Licznik przesyłany między domenami w kodzie Graya (15.04): w domenie źródłowej licznik binarny bin
// i jego kod Graya gray_r (rejestr — bez logiki między nim a synchronizatorem); w domenie docelowej
// synchronizator wektorowy i konwersja z powrotem na binarny. Ponieważ kolejne wartości Graya różnią się
// jednym bitem, odczyt w trakcie zmiany daje starą albo nową wartość — nigdy przypadkową.
`default_nettype none

module gray_cdc #(
    parameter W      = 4,
    parameter STAGES = 2
) (
    input  wire         clk_src,
    input  wire         rst_src,
    input  wire         inc,
    output reg  [W-1:0] src_count,
    input  wire         clk_dst,
    output wire [W-1:0] dst_count
);
    // domena źródłowa
    reg [W-1:0] gray_r = {W{1'b0}};
    wire [W-1:0] next = src_count + {{(W-1){1'b0}}, 1'b1};
    always @(posedge clk_src)
        if (rst_src) begin
            src_count <= {W{1'b0}};
            gray_r    <= {W{1'b0}};
        end else if (inc) begin
            src_count <= next;
            gray_r    <= next ^ (next >> 1);   // bin -> Gray
        end

    // domena docelowa
    wire [W-1:0] gray_dst;
    sync_bit #(.STAGES(STAGES), .W(W)) u_sync (.clk(clk_dst), .d(gray_r), .q(gray_dst));

    // Gray -> bin: b[i] = XOR bitów Graya od najstarszego do i
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : g_bin
            assign dst_count[i] = ^(gray_dst >> i);
        end
    endgenerate
endmodule

`default_nettype wire
