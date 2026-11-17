// Układy do strukturalnej analizy CDC (15.07): cdc_lint.py i OpenSTA.
//   cdc_dobry — wszystkie przejścia clk_a -> clk_b poprawne: synchronizator poziomu, impuls (toggle),
//               słowo z potwierdzeniem, licznik w kodzie Graya, asynchroniczne FIFO;
//   cdc_zly   — cztery typowe błędy: jeden przerzutnik zamiast dwóch, logika przed synchronizatorem,
//               licznik binarny synchronizowany bit po bicie, słowo przechwycone bez synchronizacji.
`default_nettype none

module cdc_dobry (
    input  wire       clk_a,
    input  wire       rst_a,
    input  wire       clk_b,
    input  wire       rst_b,
    input  wire       lvl_a,
    input  wire       pulse_a,
    input  wire [7:0] word_a,
    input  wire       send_a,
    input  wire       inc_a,
    input  wire       wr_a,
    input  wire       rd_b,
    output wire       lvl_b,
    output wire       pulse_b,
    output wire [7:0] word_b,
    output wire       word_valid_b,
    output wire [3:0] count_b,
    output reg  [7:0] fifo_b,
    output wire       empty_b
);
    // poziom: rejestr w domenie A, potem synchronizator w B
    reg lvl_r = 1'b0;
    always @(posedge clk_a) lvl_r <= lvl_a;
    sync_bit u_lvl (.clk(clk_b), .d(lvl_r), .q(lvl_b));

    wire busy_p;
    sync_pulse u_pulse (.clk_src(clk_a), .rst_src(rst_a), .src_pulse(pulse_a), .busy(busy_p),
                        .clk_dst(clk_b), .rst_dst(rst_b), .dst_pulse(pulse_b));

    wire ready_w;
    cdc_handshake u_word (.clk_src(clk_a), .rst_src(rst_a), .send(send_a), .src_data(word_a), .ready(ready_w),
                          .clk_dst(clk_b), .rst_dst(rst_b), .dst_valid(word_valid_b), .dst_data(word_b));

    wire [3:0] count_a;
    gray_cdc u_gray (.clk_src(clk_a), .rst_src(rst_a), .inc(inc_a), .src_count(count_a),
                     .clk_dst(clk_b), .dst_count(count_b));

    wire       full_a;
    wire [7:0] rd_data_b;
    async_fifo #(.W(8), .AW(3)) u_fifo (.wr_clk(clk_a), .wr_rst(rst_a), .wr_en(wr_a), .wr_data(word_a),
                                        .wr_full(full_a), .rd_clk(clk_b), .rd_rst(rst_b), .rd_en(rd_b),
                                        .rd_data(rd_data_b), .rd_empty(empty_b));
    always @(posedge clk_b) if (rd_b && !empty_b) fifo_b <= rd_data_b;
endmodule

module cdc_zly (
    input  wire       clk_a,
    input  wire       clk_b,
    input  wire       x_a,
    input  wire       y_a,
    input  wire [7:0] word_a,
    output reg        jeden_b,
    output reg        logika_b,
    output wire [3:0] bin_b,
    output reg  [7:0] word_b
);
    reg x_r = 1'b0, y_r = 1'b0;
    reg [3:0] bin_r = 4'd0;
    reg [7:0] word_r = 8'd0;
    always @(posedge clk_a) begin
        x_r    <= x_a;
        y_r    <= y_a;
        bin_r  <= bin_r + 4'd1;
        word_r <= word_a;
    end

    // błąd 1: jeden przerzutnik, wyjście od razu do logiki
    always @(posedge clk_b) jeden_b <= x_r;

    // błąd 2: logika (AND) przed synchronizatorem — może wytworzyć szpilkę, której nie było w żadnym sygnale
    reg l1 = 1'b0;
    always @(posedge clk_b) begin
        l1       <= x_r & y_r;
        logika_b <= l1;
    end

    // błąd 3: licznik binarny synchronizowany bit po bicie
    sync_bit #(.W(4)) u_bin (.clk(clk_b), .d(bin_r), .q(bin_b));

    // błąd 4: słowo z domeny A użyte w logice domeny B bez żadnego sterowania
    always @(posedge clk_b) word_b <= word_r + 8'd1;
endmodule

`default_nettype wire
