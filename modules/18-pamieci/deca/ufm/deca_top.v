// Moduł nadrzędny DECA — Verilog. Licznik naciśnięć zapamiętany w pamięci flash użytkownika (18.05):
//   po starcie: odczyt słowa 0 z UFM (0xFFFFFFFF = skasowane -> licznik 0) i wyświetlenie na LED[6:0],
//   KEY[1]: kasowanie strony, zapis licznika + 1 pod adres 0, odczyt kontrolny,
//   KEY[1] przy SW[0] w górze: tylko kasowanie strony (licznik wraca do 0),
//   LED[7]: błąd (status rdzenia: ws/es = 0 albo odczyt kontrolny niezgodny) — świeci do resetu.
// Wartość przetrwa wyłączenie zasilania, gdy projekt jest zapisany w pamięci konfiguracji (make flash).
// Rdzeń On-Chip Flash generuje się w Quartusie jako ufm_flash (instrukcja: README.md w tym katalogu);
// FLASH_AW musi być równe szerokości portu avmm_data_addr wygenerowanego rdzenia.
// W symulatorach (Icarus, Verilator) zamiast rdzenia jest zaślepka.
`default_nettype none

`ifdef __ICARUS__
`define DECA_SYMULACJA
`endif
`ifdef VERILATOR
`define DECA_SYMULACJA
`endif

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,
    input  wire [1:0] SW,
    output wire [7:0] LED                      // 0 = świeci
);
    localparam FLASH_AW = 17;
    wire clk = MAX10_CLK1_50;

    reg [1:0] rs = 2'b00;
    always @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    wire rst = ~rs[1];

    // przycisk i przełącznik: synchronizacja, filtr drgań (próbkowanie co ok. 5 ms), zbocze naciśnięcia
    reg  [2:0]  k_s = 3'b111;
    reg  [1:0]  sw_s = 2'b00;
    reg  [17:0] dz = 18'd0;
    reg         k_f = 1'b1, k_f_d = 1'b1;
    always @(posedge clk) begin
        k_s  <= {k_s[1:0], KEY[1]};
        sw_s <= {sw_s[0], SW[0]};
        dz   <= dz + 18'd1;
        if (dz == 18'd0) k_f <= k_s[2];
        k_f_d <= k_f;
    end
    wire nacisniecie = k_f_d && !k_f;

    // ---- sterownik UFM ----
    reg         start = 1'b0;
    reg  [1:0]  op = 2'd0;
    reg  [31:0] wdata = 32'd0;
    wire        busy, done, ok;
    wire [31:0] rdata;
    wire        csr_addr, csr_read, csr_write, data_read, data_write, waitreq, rdvalid;
    wire [31:0] csr_wd, csr_rd, data_wd, data_rd;
    wire [FLASH_AW-1:0] data_addr;
    wire [3:0]  burst;
    ufm_sterownik #(.AW(FLASH_AW), .SEKTOR(1), .CZEKAJ(4)) u_ster (
        .clk(clk), .rst(rst), .start(start), .op(op), .addr({FLASH_AW{1'b0}}), .wdata(wdata),
        .busy(busy), .done(done), .ok(ok), .rdata(rdata),
        .csr_addr(csr_addr), .csr_read(csr_read), .csr_write(csr_write), .csr_writedata(csr_wd),
        .csr_readdata(csr_rd), .data_addr(data_addr), .data_read(data_read), .data_write(data_write),
        .data_writedata(data_wd), .data_burstcount(burst), .data_waitrequest(waitreq),
        .data_readdatavalid(rdvalid), .data_readdata(data_rd));

`ifdef DECA_SYMULACJA
    assign csr_rd  = 32'd0;
    assign waitreq = 1'b0;
    assign rdvalid = data_read;
    assign data_rd = 32'hFFFF_FFFF;
`else
    ufm_flash u_flash (
        .clock                   (clk),
        .reset_n                 (~rst),
        .avmm_csr_addr           (csr_addr),
        .avmm_csr_read           (csr_read),
        .avmm_csr_writedata      (csr_wd),
        .avmm_csr_write          (csr_write),
        .avmm_csr_readdata       (csr_rd),
        .avmm_data_addr          (data_addr),
        .avmm_data_read          (data_read),
        .avmm_data_writedata     (data_wd),
        .avmm_data_write         (data_write),
        .avmm_data_readdata      (data_rd),
        .avmm_data_waitrequest   (waitreq),
        .avmm_data_readdatavalid (rdvalid),
        .avmm_data_burstcount    (burst)
    );
`endif

    // ---- sekwencja: odczyt po starcie; naciśnięcie -> kasowanie, zapis, odczyt kontrolny ----
    localparam [2:0] T_START = 3'd0, T_ODCZYT = 3'd1, T_CZEKAJ = 3'd2, T_KASUJ = 3'd3, T_ZAPIS = 3'd4,
                     T_KONTROLA = 3'd5;
    reg [2:0]  t = T_START;
    reg [31:0] licznik = 32'd0;
    reg        blad = 1'b0;
    always @(posedge clk) begin
        start <= 1'b0;
        if (rst) begin
            t    <= T_START;
            blad <= 1'b0;
        end else case (t)
            T_START: begin                               // odczyt zapamiętanej wartości
                op <= 2'd0; start <= 1'b1; t <= T_ODCZYT;
            end
            T_ODCZYT:
                if (done) begin
                    licznik <= (rdata == 32'hFFFF_FFFF) ? 32'd0 : rdata;
                    if (!ok) blad <= 1'b1;
                    t <= T_CZEKAJ;
                end
            T_CZEKAJ:
                if (nacisniecie && !busy) begin
                    wdata <= sw_s[1] ? 32'hFFFF_FFFF : licznik + 32'd1;
                    op <= 2'd2; start <= 1'b1; t <= T_KASUJ;
                end
            T_KASUJ:
                if (done) begin
                    if (!ok) blad <= 1'b1;
                    if (sw_s[1]) begin
                        op <= 2'd0; start <= 1'b1; t <= T_ODCZYT;
                    end else begin
                        op <= 2'd1; start <= 1'b1; t <= T_ZAPIS;
                    end
                end
            T_ZAPIS:
                if (done) begin
                    if (!ok) blad <= 1'b1;
                    op <= 2'd0; start <= 1'b1; t <= T_KONTROLA;
                end
            default:                                     // T_KONTROLA
                if (done) begin
                    if (!ok || rdata != wdata) blad <= 1'b1;
                    licznik <= rdata;
                    t <= T_CZEKAJ;
                end
        endcase
    end

    assign LED = ~{blad, licznik[6:0]};
endmodule

`default_nettype wire
