// Licznik przesyłany między domenami w kodzie Graya (15.04): w domenie źródłowej licznik binarny
// i jego kod Graya gray_r (rejestr — bez logiki między nim a synchronizatorem); w domenie docelowej
// synchronizator wektorowy i konwersja z powrotem na binarny. Ponieważ kolejne wartości Graya różnią się
// jednym bitem, odczyt w trakcie zmiany daje starą albo nową wartość — nigdy przypadkową.
module gray_cdc #(
    parameter int W      = 4,
    parameter int STAGES = 2
) (
    input  logic         clk_src,
    input  logic         rst_src,
    input  logic         inc,
    output logic [W-1:0] src_count,
    input  logic         clk_dst,
    output logic [W-1:0] dst_count
);
    function automatic logic [W-1:0] bin2gray(input logic [W-1:0] b);
        return b ^ (b >> 1);
    endfunction

    function automatic logic [W-1:0] gray2bin(input logic [W-1:0] g);
        logic [W-1:0] b;
        b[W-1] = g[W-1];
        for (int i = W - 2; i >= 0; i--) b[i] = b[i+1] ^ g[i];
        return b;
    endfunction

    logic [W-1:0] gray_r = '0, gray_dst, next;
    assign next = src_count + 1'b1;

    always_ff @(posedge clk_src)
        if (rst_src) begin
            src_count <= '0;
            gray_r    <= '0;
        end else if (inc) begin
            src_count <= next;
            gray_r    <= bin2gray(next);
        end

    sync_bit #(.STAGES(STAGES), .W(W)) u_sync (.clk(clk_dst), .d(gray_r), .q(gray_dst));
    assign dst_count = gray2bin(gray_dst);
endmodule
