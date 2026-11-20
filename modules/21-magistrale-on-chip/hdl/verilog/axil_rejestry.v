// Slave AXI4-Lite (21.02) nad rejestry_rdzen: kanały AW i W przyjmowane niezależnie (w dowolnej
// kolejności), zapis, gdy oba są zebrane i kanał B wolny; odczyt z rejestrem danych. Wszystkie
// sygnały ready z przerzutników. Adres spoza mapy: SLVERR.
`default_nettype none

module axil_rejestry #(
    parameter [31:0] ID = 32'h2102_0001
) (
    input  wire        clk,
    input  wire        rst,
    // zapis (bity 1:0 adresów nieużywane: dostęp słowami)
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [5:0]  s_awaddr,
    input  wire        s_awvalid,
    output wire        s_awready,
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output wire        s_wready,
    output reg  [1:0]  s_bresp,
    output reg         s_bvalid,
    input  wire        s_bready,
    // odczyt
    input  wire [5:0]  s_araddr,
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire        s_arvalid,
    output wire        s_arready,
    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready,
    // strona układu
    output wire [31:0] ster,
    input  wire [31:0] stan,
    input  wire [7:0]  zdarz,
    output wire        irq
);
    localparam [1:0] OKAY = 2'b00, SLVERR = 2'b10;

    reg        aw_ok, w_ok;
    reg [3:0]  aw_adr;
    reg [31:0] w_dane;
    reg [3:0]  w_str;
    wire       zap = aw_ok && w_ok && (!s_bvalid || s_bready);
    wire       zap_blad, odc_blad;
    wire [31:0] odc_dane;

    assign s_awready = !aw_ok;
    assign s_wready  = !w_ok;
    assign s_arready = !s_rvalid;

    rejestry_rdzen #(.ID(ID)) u_rdzen (
        .clk(clk), .rst(rst),
        .zap(zap), .zap_adr(aw_adr), .zap_dane(w_dane), .zap_str(w_str), .zap_blad(zap_blad),
        .odc_adr(s_araddr[5:2]), .odc_dane(odc_dane), .odc_blad(odc_blad),
        .ster(ster), .stan(stan), .zdarz(zdarz), .irq(irq));

    always @(posedge clk) begin
        if (rst) begin
            aw_ok    <= 1'b0;
            w_ok     <= 1'b0;
            s_bvalid <= 1'b0;
            s_rvalid <= 1'b0;
        end else begin
            if (s_awvalid && s_awready) begin
                aw_ok  <= 1'b1;
                aw_adr <= s_awaddr[5:2];
            end
            if (s_wvalid && s_wready) begin
                w_ok   <= 1'b1;
                w_dane <= s_wdata;
                w_str  <= s_wstrb;
            end
            if (s_bvalid && s_bready) s_bvalid <= 1'b0;
            if (zap) begin                               // adres i dane zebrane, odpowiedź może wyjść
                aw_ok    <= 1'b0;
                w_ok     <= 1'b0;
                s_bvalid <= 1'b1;
                s_bresp  <= zap_blad ? SLVERR : OKAY;
            end
            if (s_rvalid && s_rready) s_rvalid <= 1'b0;
            if (s_arvalid && s_arready) begin
                s_rvalid <= 1'b1;
                s_rdata  <= odc_dane;
                s_rresp  <= odc_blad ? SLVERR : OKAY;
            end
        end
    end
endmodule

`default_nettype wire
