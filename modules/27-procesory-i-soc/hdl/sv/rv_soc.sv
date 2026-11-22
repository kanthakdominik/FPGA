// Mały SoC (27.03, 27.07): rdzeń rv_potok, wspólna pamięć programu i danych (SLOWA słów 32-bitowych, dwa porty:
// instrukcje i dane, odczyt synchroniczny, zapis z maską bajtów — blok pamięci dwuportowej), rejestry
// systemowe i peryferium pwm_avl na magistrali Avalon-MM. Mapa adresów:
//   0x0000_0000  RAM            0x1000_0000  LED (zapis) / wej (odczyt)    0x1000_0004  licznik taktów
//   0x1000_0008  TOHOST (zapis -> koniec)     0x1000_000C  KONSOLA (zapis znaku)   0x1000_0010  licznik instrukcji
//   0x1000_0100  pwm_avl: STER, OKRES, WYPELN, STATUS
// Rejestry systemowe tylko 32-bitowo. Zawartość RAM z pliku PLIK ($readmemh).
// mon_* — kopia zapisów rdzenia dla testbenchu.
`default_nettype none

module rv_soc #(
    parameter integer SLOWA = 256,
    parameter         PLIK  = ""
) (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] wej,
    output logic  [31:0] led,
    output logic        pwm_wy,
    output logic        pwm_irq,
    output logic         koniec,
    output logic  [7:0]  znak,
    output logic         znak_wazny,
    output logic        wycofana,
    output logic [31:0] mon_adr,
    output logic [31:0] mon_dane,
    output logic [3:0]  mon_strb
);
    localparam integer AW = $clog2(SLOWA);

    /* verilator lint_off UNUSEDSIGNAL */                    // i_adr: tylko bity adresu słowa w pamięci
    logic [31:0] i_adr, i_dane_w, d_adr, d_wdane, d_rdane;
    /* verilator lint_on UNUSEDSIGNAL */
    logic [3:0]  d_wstrb;
    logic        d_odczyt;
    logic  [31:0] i_dane, d_ram, io_rd;
    assign i_dane_w = i_dane;
    rv_potok u_cpu (.clk(clk), .rst(rst), .i_adr(i_adr), .i_dane(i_dane_w), .d_adr(d_adr), .d_wdane(d_wdane),
        .d_wstrb(d_wstrb), .d_odczyt(d_odczyt), .d_rdane(d_rdane), .wycofana(wycofana));

    // ---------------------------------------------------------------- pamięć
    logic [31:0] pam [0:SLOWA-1];
`ifndef YOSYS
    initial $readmemh(PLIK, pam);              // Yosys (synteza ogólna w CI) — bez pliku
`endif
    /* verilator lint_off UNUSEDSIGNAL */
    logic [AW-1:0] ia;
    assign ia = i_adr[AW+1:2];             // adresy powyżej rozmiaru pamięci się powtarzają
    logic [AW-1:0] da;
    assign da = d_adr[AW+1:2];
    /* verilator lint_on UNUSEDSIGNAL */
    logic ram_sel;
    assign ram_sel = d_adr[31:28] == 4'h0;
    logic io_sel;
    assign io_sel = d_adr[31:28] == 4'h1;
    logic pwm_sel;
    assign pwm_sel = io_sel && d_adr[8];
    logic sys_sel;
    assign sys_sel = io_sel && !d_adr[8];

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

    // ---------------------------------------------------------------- rejestry systemowe
    logic [31:0] takty, instr;
    always_ff @(posedge clk) begin
        koniec <= 1'b0;
        znak_wazny <= 1'b0;
        if (rst) begin
            led <= 32'd0; takty <= 32'd0; instr <= 32'd0; znak <= 8'd0;
        end else begin
            takty <= takty + 32'd1;
            if (wycofana) instr <= instr + 32'd1;
            if (sys_sel && d_wstrb != 4'd0)
                case (d_adr[7:2])
                    6'd0: led <= d_wdane;
                    6'd2: koniec <= 1'b1;
                    6'd3: begin znak <= d_wdane[7:0]; znak_wazny <= 1'b1; end
                    default: ;
                endcase
        end
        if (d_odczyt)
            case (d_adr[7:2])
                6'd0:    io_rd <= wej;
                6'd1:    io_rd <= takty;
                6'd4:    io_rd <= instr;
                default: io_rd <= 32'd0;
            endcase
    end

    // ---------------------------------------------------------------- PWM (Avalon-MM, readLatency 1)
    logic [31:0] pwm_rd;
    pwm_avl u_pwm (.clk(clk), .rst(rst), .address(d_adr[3:2]), .read(d_odczyt && pwm_sel),
        .write(pwm_sel && d_wstrb != 4'd0), .writedata(d_wdane), .readdata(pwm_rd), .irq(pwm_irq), .pwm(pwm_wy));

    // ---------------------------------------------------------------- odczyt w stopniu WB: wybór źródła takt później
    logic ram_w, pwm_w;
    always_ff @(posedge clk) begin
        ram_w <= ram_sel;
        pwm_w <= pwm_sel;
    end
    assign d_rdane = ram_w ? d_ram : pwm_w ? pwm_rd : io_rd;

    assign mon_adr  = d_adr;
    assign mon_dane = d_wdane;
    assign mon_strb = d_wstrb;
endmodule

`default_nettype wire
