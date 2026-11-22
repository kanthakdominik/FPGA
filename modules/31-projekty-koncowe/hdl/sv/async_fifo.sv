// Asynchroniczna kolejka FIFO (15.05) — wskaźniki w kodzie Graya, architektura C. Cummingsa (SNUG 2002).
// Zapis w domenie wr_clk, odczyt w domenie rd_clk, głębokość 2^AW, odczyt z wyprzedzeniem (rd_data ważne,
// gdy !rd_empty). Wskaźniki mają AW+1 bitów; do drugiej domeny przechodzą tylko ich wersje Graya
// (rejestry wr_gray, rd_gray) przez synchronizatory wektorowe.
//   rd_empty: rd_gray == zsynchronizowany wr_gray            (dokładne przy odczycie, pesymistyczne przy zapisie)
//   wr_full : wr_gray == ~2 najstarsze bity zsynchr. rd_gray  (dokładne przy zapisie, pesymistyczne przy odczycie)
// Opóźnienie flag jest zawsze "bezpieczne": kolejka może wyglądać na pełną/pustą dłużej, nigdy krócej.
module async_fifo #(
    parameter int W      = 8,
    parameter int AW     = 4,                  // głębokość 2^AW
    parameter int STAGES = 2
) (
    input  logic         wr_clk,
    input  logic         wr_rst,
    input  logic         wr_en,
    input  logic [W-1:0] wr_data,
    output logic         wr_full,
    input  logic         rd_clk,
    input  logic         rd_rst,
    input  logic         rd_en,
    output logic [W-1:0] rd_data,
    output logic         rd_empty
);
    localparam int DEPTH = 1 << AW;

    logic [W-1:0] mem [DEPTH];
    logic [AW:0]  wr_bin = '0, wr_gray = '0, rd_bin = '0, rd_gray = '0;
    logic [AW:0]  rd_gray_w, wr_gray_r;         // wskaźnik drugiej domeny po synchronizacji
    logic [AW:0]  wr_bin_n, wr_gray_n, rd_bin_n, rd_gray_n;

    // ---------------- domena zapisu ----------------
    assign wr_bin_n  = wr_bin + (AW + 1)'(wr_en && !wr_full);
    assign wr_gray_n = wr_bin_n ^ (wr_bin_n >> 1);

    always_ff @(posedge wr_clk) begin
        if (wr_en && !wr_full) mem[wr_bin[AW-1:0]] <= wr_data;
        if (wr_rst) begin
            wr_bin  <= '0;
            wr_gray <= '0;
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
    assign rd_bin_n  = rd_bin + (AW + 1)'(rd_en && !rd_empty);
    assign rd_gray_n = rd_bin_n ^ (rd_bin_n >> 1);

    always_ff @(posedge rd_clk) begin
        if (rd_rst) begin
            rd_bin   <= '0;
            rd_gray  <= '0;
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
