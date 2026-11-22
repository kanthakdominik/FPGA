// Projekt 6 (31.06): mikrokontroler na własnym rdzeniu RV32I (rv_potok z 27.07). Pamięć programu i danych
// SLOWA słów (dwa porty, zapis z maską bajtów), peryferia pod 0x1000_0000:
//   +00 GPIO     W: LED, R: wejścia            +04 LICZNIK   R: takty od resetu
//   +08 PORÓWNANIE RW: flaga, gdy LICZNIK == PORÓWNANIE    +0C FLAGA R: bit 0, zapis 1 kasuje
//   +10 UART DANE  W: bajt do nadania (gdy nadajnik wolny), R: odebrany bajt (odczyt zdejmuje)
//   +14 UART STATUS R: bit 0 nadajnik wolny, bit 1 jest bajt, bit 2 przepełnienie (zapis 1 do bitu 2 kasuje)
//   +18 TOHOST   W: koniec (symulacja)          +100 pwm_avl (STER, OKRES, WYPELN, STATUS)
// Odczyt rejestrów w takcie po żądaniu (jak RAM), wybór źródła w stopniu zapisu wyniku.
`default_nettype none

module rv_mcu #(
    parameter integer SLOWA  = 1024,
    parameter         PLIK   = "",
    parameter integer CLK_HZ = 50_000_000,
    parameter integer BAUD   = 115_200
) (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] wej,
    output logic  [31:0] led = 32'd0,
    input  logic        uart_rx,
    output logic        uart_tx,
    output logic        pwm_wy,
    output logic         koniec = 1'b0,
    output logic        wycofana
);
    localparam integer AW = $clog2(SLOWA);

    /* verilator lint_off UNUSEDSIGNAL */
    logic [31:0] i_adr, d_adr;
    /* verilator lint_on UNUSEDSIGNAL */
    logic [31:0] d_wdane, d_rdane;
    logic [3:0]  d_wstrb;
    logic        d_odczyt;
    logic  [31:0] i_dane = 32'd0;
    logic  [31:0] d_ram = 32'd0;
    logic  [31:0] io_rd = 32'd0;
    rv_potok u_cpu (.clk(clk), .rst(rst), .i_adr(i_adr), .i_dane(i_dane), .d_adr(d_adr), .d_wdane(d_wdane),
        .d_wstrb(d_wstrb), .d_odczyt(d_odczyt), .d_rdane(d_rdane), .wycofana(wycofana));

    // ---------------------------------------------------------------- pamięć
    logic [31:0] pam [0:SLOWA-1];
`ifndef YOSYS
    initial $readmemh(PLIK, pam);
`endif
    logic [AW-1:0] ia;
    assign ia = i_adr[AW+1:2];
    logic [AW-1:0] da;
    assign da = d_adr[AW+1:2];
    logic ram_sel;
    assign ram_sel = d_adr[31:28] == 4'h0;
    logic io_sel;
    assign io_sel = d_adr[31:28] == 4'h1;
    logic pwm_sel;
    assign pwm_sel = io_sel && d_adr[8];
    logic sys_sel;
    assign sys_sel = io_sel && !d_adr[8];
    logic zapis;
    assign zapis = d_wstrb != 4'd0;
    always_ff @(posedge clk) i_dane <= pam[ia];
    always_ff @(posedge clk) begin
        if (ram_sel) begin
            if (d_wstrb[0]) pam[da][7:0]   <= d_wdane[7:0];
            if (d_wstrb[1]) pam[da][15:8]  <= d_wdane[15:8];
            if (d_wstrb[2]) pam[da][23:16] <= d_wdane[23:16];
            if (d_wstrb[3]) pam[da][31:24] <= d_wdane[31:24];
        end
        d_ram <= pam[da];
    end

    // ---------------------------------------------------------------- UART
    logic [7:0] rx_dane;
    logic       rx_wazne, tx_gotowy;
    logic        tx_start = 1'b0;
    logic        tx_start_d = 1'b0;
    logic  [7:0] tx_bajt = 8'd0;
    logic  [7:0] rx_bufor = 8'd0;
    logic        rx_jest = 1'b0;
    logic        rx_przep = 1'b0;
    /* verilator lint_off PINCONNECTEMPTY */
    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_rx (.clk(clk), .rst(rst), .rx(uart_rx), .dane(rx_dane),
        .wazne(rx_wazne), .blad_ramki(), .blad_parz());
    /* verilator lint_on PINCONNECTEMPTY */
    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_tx (.clk(clk), .rst(rst), .start(tx_start), .dane(tx_bajt),
        .gotowy(tx_gotowy), .tx(uart_tx));
    // „wolny” dla programu: nadajnik gotowy i żaden zapis nie czeka na start
    logic tx_wolny;
    assign tx_wolny = tx_gotowy && !tx_start && !tx_start_d;

    // ---------------------------------------------------------------- licznik, GPIO, rejestry
    logic [31:0] licznik = 32'd0;
    logic [31:0] porown = 32'hFFFFFFFF;
    logic        flaga = 1'b0;
    always_ff @(posedge clk) begin
        koniec     <= 1'b0;
        tx_start   <= 1'b0;
        tx_start_d <= tx_start;
        if (rst) begin
            led <= 32'd0; licznik <= 32'd0; porown <= 32'hFFFFFFFF; flaga <= 1'b0;
            rx_jest <= 1'b0; rx_przep <= 1'b0;
        end else begin
            licznik <= licznik + 32'd1;
            if (licznik == porown) flaga <= 1'b1;
            if (rx_wazne) begin
                if (rx_jest) rx_przep <= 1'b1;
                rx_bufor <= rx_dane;
                rx_jest  <= 1'b1;
            end
            if (sys_sel && zapis)
                case (d_adr[7:2])
                    6'd0: led <= d_wdane;
                    6'd2: porown <= d_wdane;
                    6'd3: if (d_wdane[0]) flaga <= 1'b0;
                    6'd4: if (tx_wolny) begin tx_bajt <= d_wdane[7:0]; tx_start <= 1'b1; end
                    6'd5: if (d_wdane[2]) rx_przep <= 1'b0;
                    6'd6: koniec <= 1'b1;
                    default: ;
                endcase
            if (sys_sel && d_odczyt && d_adr[7:2] == 6'd4 && !rx_wazne) rx_jest <= 1'b0;
        end
        if (d_odczyt)
            case (d_adr[7:2])
                6'd0:    io_rd <= wej;
                6'd1:    io_rd <= licznik;
                6'd2:    io_rd <= porown;
                6'd3:    io_rd <= {31'd0, flaga};
                6'd4:    io_rd <= {24'd0, rx_bufor};
                6'd5:    io_rd <= {29'd0, rx_przep, rx_jest, tx_wolny};
                default: io_rd <= 32'd0;
            endcase
    end

    // ---------------------------------------------------------------- PWM
    logic [31:0] pwm_rd;
    /* verilator lint_off PINCONNECTEMPTY */
    pwm_avl u_pwm (.clk(clk), .rst(rst), .address(d_adr[3:2]), .read(d_odczyt && pwm_sel),
        .write(pwm_sel && zapis), .writedata(d_wdane), .readdata(pwm_rd), .irq(), .pwm(pwm_wy));
    /* verilator lint_on PINCONNECTEMPTY */

    logic ram_w = 1'b0;
    logic pwm_w = 1'b0;
    always_ff @(posedge clk) begin
        ram_w <= ram_sel;
        pwm_w <= pwm_sel;
    end
    assign d_rdane = ram_w ? d_ram : pwm_w ? pwm_rd : io_rd;
endmodule

`default_nettype wire
