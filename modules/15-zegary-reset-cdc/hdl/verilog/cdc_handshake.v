// Przesyłanie słowa między domenami z potwierdzeniem (protokół dwufazowy, 15.04).
// Źródło: send = 1 (gdy ready) zapisuje słowo do data_r i zmienia req. Słowo NIE jest synchronizowane —
// jest stałe, dopóki trwa transakcja; synchronizowany jest tylko req (sync_bit). Cel: zmiana req ->
// zapis data_r do dst_data i impuls dst_valid, potem ack = req wraca do źródła. ready = (req == ack_src).
// Ścieżka data_r -> dst_data jest więc wielotaktowa (zasada MCP): w SDC set_max_delay / set_false_path.
`default_nettype none

module cdc_handshake #(
    parameter W      = 8,
    parameter STAGES = 2
) (
    input  wire         clk_src,
    input  wire         rst_src,
    input  wire         send,                  // ignorowane, gdy !ready
    input  wire [W-1:0] src_data,
    output wire         ready,
    input  wire         clk_dst,
    input  wire         rst_dst,
    output reg          dst_valid,
    output reg  [W-1:0] dst_data
);
    // domena źródłowa
    reg         req = 1'b0;
    reg [W-1:0] data_r = {W{1'b0}};
    wire        ack_src;
    always @(posedge clk_src)
        if (rst_src) begin
            req <= 1'b0;
        end else if (send && ready) begin
            data_r <= src_data;
            req    <= ~req;
        end
    assign ready = (req == ack_src);

    // domena docelowa
    wire req_dst;
    reg  ack = 1'b0;
    sync_bit #(.STAGES(STAGES)) u_sync_req (.clk(clk_dst), .d(req), .q(req_dst));
    always @(posedge clk_dst) begin
        dst_valid <= 1'b0;
        if (rst_dst) begin
            ack <= 1'b0;
        end else if (req_dst != ack) begin
            dst_data  <= data_r;               // data_r stałe od co najmniej STAGES taktów clk_dst
            dst_valid <= 1'b1;
            ack       <= req_dst;
        end
    end

    sync_bit #(.STAGES(STAGES)) u_sync_ack (.clk(clk_src), .d(ack), .q(ack_src));
endmodule

`default_nettype wire
