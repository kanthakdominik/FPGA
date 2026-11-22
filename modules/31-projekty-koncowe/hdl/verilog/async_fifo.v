// Asynchroniczna kolejka FIFO (15.05) — wskaźniki w kodzie Graya, architektura C. Cummingsa (SNUG 2002).
// Zapis w domenie wr_clk, odczyt w domenie rd_clk, głębokość 2^AW, odczyt z wyprzedzeniem (rd_data ważne,
// gdy !rd_empty). Wskaźniki mają AW+1 bitów; do drugiej domeny przechodzą tylko ich wersje Graya
// (rejestry wr_gray, rd_gray) przez synchronizatory wektorowe.
//   rd_empty: rd_gray == zsynchronizowany wr_gray            (dokładne przy odczycie, pesymistyczne przy zapisie)
//   wr_full : wr_gray == ~2 najstarsze bity zsynchr. rd_gray  (dokładne przy zapisie, pesymistyczne przy odczycie)
// Opóźnienie flag jest zawsze "bezpieczne": kolejka może wyglądać na pełną/pustą dłużej, nigdy krócej.
`default_nettype none

module async_fifo #(
    parameter W      = 8,
    parameter AW     = 4,                      // głębokość 2^AW
    parameter STAGES = 2
) (
    input  wire         wr_clk,
    input  wire         wr_rst,
    input  wire         wr_en,
    input  wire [W-1:0] wr_data,
    output reg          wr_full,
    input  wire         rd_clk,
    input  wire         rd_rst,
    input  wire         rd_en,
    output wire [W-1:0] rd_data,
    output reg          rd_empty
);
    localparam DEPTH = 1 << AW;

    reg [W-1:0] mem [0:DEPTH-1];

    reg  [AW:0] wr_bin  = {(AW+1){1'b0}}, wr_gray = {(AW+1){1'b0}};
    reg  [AW:0] rd_bin  = {(AW+1){1'b0}}, rd_gray = {(AW+1){1'b0}};
    wire [AW:0] rd_gray_w;                      // rd_gray zsynchronizowany do wr_clk
    wire [AW:0] wr_gray_r;                      // wr_gray zsynchronizowany do rd_clk

    // ---------------- domena zapisu ----------------
    wire [AW:0] wr_bin_n  = wr_bin + {{AW{1'b0}}, (wr_en && !wr_full)};
    wire [AW:0] wr_gray_n = wr_bin_n ^ (wr_bin_n >> 1);

    always @(posedge wr_clk) begin
        if (wr_en && !wr_full) mem[wr_bin[AW-1:0]] <= wr_data;
        if (wr_rst) begin
            wr_bin  <= {(AW+1){1'b0}};
            wr_gray <= {(AW+1){1'b0}};
            wr_full <= 1'b0;
        end else begin
            wr_bin  <= wr_bin_n;
            wr_gray <= wr_gray_n;
            // pełna: wskaźnik zapisu wyprzedza odczyt o całe okrążenie — w Grayu: dwa najstarsze bity odwrócone
            wr_full <= (wr_gray_n == {~rd_gray_w[AW:AW-1], rd_gray_w[AW-2:0]});
        end
    end

    sync_bit #(.STAGES(STAGES), .W(AW + 1)) u_sync_rd (.clk(wr_clk), .d(rd_gray), .q(rd_gray_w));

    // ---------------- domena odczytu ----------------
    wire [AW:0] rd_bin_n  = rd_bin + {{AW{1'b0}}, (rd_en && !rd_empty)};
    wire [AW:0] rd_gray_n = rd_bin_n ^ (rd_bin_n >> 1);

    always @(posedge rd_clk) begin
        if (rd_rst) begin
            rd_bin   <= {(AW+1){1'b0}};
            rd_gray  <= {(AW+1){1'b0}};
            rd_empty <= 1'b1;
        end else begin
            rd_bin   <= rd_bin_n;
            rd_gray  <= rd_gray_n;
            rd_empty <= (rd_gray_n == wr_gray_r);
        end
    end

    sync_bit #(.STAGES(STAGES), .W(AW + 1)) u_sync_wr (.clk(rd_clk), .d(wr_gray), .q(wr_gray_r));

    // odczyt asynchroniczny z pamięci (pamięć rozproszona); dla bloku RAM — rejestr wyjściowy i takt opóźnienia
    assign rd_data = mem[rd_bin[AW-1:0]];
endmodule

`default_nettype wire
