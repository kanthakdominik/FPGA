// Kolejka FIFO synchroniczna z odczytem „z wyprzedzeniem” (rd_data = najstarszy element, gdy !empty).
// Zapis: wr_en && !full; odczyt (zdjęcie elementu): rd_en && !empty; oba w jednym takcie dozwolone.
// Wskaźniki o jeden bit szersze niż adres: równe — pusta; różne tylko najstarszym bitem — pełna.
// Właściwości formalne w bloku `ifdef FORMAL` (13.04): granice i spójność count/full/empty, zmiany count,
// kolejność danych — dowolny wybrany element (anyseq) wychodzi nienaruszony po wszystkich starszych.
// Z -D BEZ_NIEZMIENNIKOW wyłączone są niezmienniki pomocnicze: BMC przechodzi, indukcja nie.
module fifo_sync #(
    parameter int W  = 8,
    parameter int AW = 3                          // głębokość 2^AW
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          wr_en,
    input  logic [W-1:0]  wr_data,
    output logic          full,
    input  logic          rd_en,
    output logic [W-1:0]  rd_data,
    output logic          empty,
    output logic [AW:0]   count
);
    localparam int DEPTH = 1 << AW;

    logic [W-1:0] mem [0:DEPTH-1];
    logic [AW:0]  wr_ptr, rd_ptr;

    wire do_wr = wr_en && !full;
    wire do_rd = rd_en && !empty;

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            if (do_wr) wr_ptr <= wr_ptr + 1'b1;
            if (do_rd) rd_ptr <= rd_ptr + 1'b1;
        end
        if (do_wr) mem[wr_ptr[AW-1:0]] <= wr_data;
    end

    assign rd_data = mem[rd_ptr[AW-1:0]];
    assign count   = wr_ptr - rd_ptr;
    assign empty   = (wr_ptr == rd_ptr);
    assign full    = (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]) && (wr_ptr[AW] != rd_ptr[AW]);

`ifdef FORMAL
    // ---- otoczenie: reset w pierwszym takcie ----
    logic f_past_valid = 1'b0;
    always_ff @(posedge clk) f_past_valid <= 1'b1;
    always_comb if (!f_past_valid) assume (rst);

    // ---- stan wewnętrzny i wyjścia ----
    always_comb if (f_past_valid) begin
`ifndef BEZ_NIEZMIENNIKOW
        assert (count <= DEPTH);                   // niezmiennik: bez niego indukcja zawodzi (13.04)
`endif
        assert (full  == (count == DEPTH));
        assert (empty == (count == 0));
    end

    always_ff @(posedge clk) if (f_past_valid && !$past(rst)) begin
        if ($past(do_wr) && !$past(do_rd))      assert (count == $past(count) + 1'b1);
        else if (!$past(do_wr) && $past(do_rd)) assert (count == $past(count) - 1'b1);
        else                                    assert (count == $past(count));
    end

    always_ff @(posedge clk) if (f_past_valid && $past(rst)) assert (empty && !full);

    // ---- kolejność danych: śledzony jeden, dowolnie wybrany element ----
    (* anyseq *) logic f_pick;                     // solver wybiera, który zapis śledzić
    logic          f_track = 1'b0;                 // element w kolejce
    logic [AW:0]   f_addr;                         // wskaźnik, pod którym zapisano
    logic [W-1:0]  f_val;                          // jego wartość

    always_ff @(posedge clk) begin
        if (rst) begin
            f_track <= 1'b0;
        end else if (!f_track && do_wr && f_pick) begin
            f_track <= 1'b1;
            f_addr  <= wr_ptr;
            f_val   <= wr_data;
        end else if (f_track && do_rd && rd_ptr == f_addr) begin
            f_track <= 1'b0;                       // śledzony element właśnie wyszedł
        end
    end

    // element czeka między rd_ptr a wr_ptr i nie zmienia się w pamięci
    wire [AW:0] f_dist = f_addr - rd_ptr;          // ile starszych elementów przed nim
`ifndef BEZ_NIEZMIENNIKOW
    always_comb if (f_past_valid && f_track && !rst) begin
        assert (f_dist < count);                   // niezmiennik pomocniczy
        assert (mem[f_addr[AW-1:0]] == f_val);     // niezmiennik pomocniczy
    end
`endif
    // właściwość docelowa: gdy śledzony element wychodzi, ma wartość zapisaną
    always_comb if (f_past_valid && f_track && !rst && do_rd && rd_ptr == f_addr) assert (rd_data == f_val);

    // ---- osiągalność ----
    logic f_was_full = 1'b0;
    always_ff @(posedge clk)                       // bez zerowania resetem solver „oszukuje”:
        if (rst)       f_was_full <= 1'b0;         // pełna -> reset -> pusta w 2 taktach (13.04)
        else if (full) f_was_full <= 1'b1;
    always_ff @(posedge clk) if (f_past_valid && !rst) begin
        cover (full);
        cover (f_was_full && empty);               // od pełnej z powrotem do pustej
        cover (wr_en && do_rd && full);            // zapis odrzucony przy pełnej, odczyt w tym samym takcie
        cover (f_track && do_rd && rd_ptr == f_addr && count == DEPTH);   // śledzony element wychodzi z pełnej
    end
`endif
endmodule
