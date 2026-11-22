// Zadanie 10: slave AXI4-Lite z czterema rejestrami 32-bitowymi (adresy 0x0, 0x4, 0x8, 0xC), zapis z maską
// bajtów. Kanały adresu i danych zapisu są niezależne — mogą przyjść w dowolnej kolejności albo razem, więc każdy
// ma własny rejestr „przyjęty”; zapis i odpowiedź B, gdy są oba. Następny zapis dopiero po odebraniu odpowiedzi
// (bready). Odczyt: dane w takcie po przyjęciu adresu, trzymane do rready. Odpowiedzi zawsze OKAY.
`default_nettype none

module axil_regs (
    input  wire        clk,
    input  wire        rst,
    // zapis
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [3:0]  awaddr,          // bity 1:0 — wyrównanie do słowa, nieużywane
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire        awvalid,
    output wire        awready,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    input  wire        wvalid,
    output wire        wready,
    output wire [1:0]  bresp,
    output reg         bvalid = 1'b0,
    input  wire        bready,
    // odczyt
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [3:0]  araddr,
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire        arvalid,
    output wire        arready,
    output reg  [31:0] rdata = 32'd0,
    output wire [1:0]  rresp,
    output reg         rvalid = 1'b0,
    input  wire        rready,
    // rejestry dla reszty układu
    output wire [31:0] reg0,
    output wire [31:0] reg1,
    output wire [31:0] reg2,
    output wire [31:0] reg3
);
    reg [31:0] r0 = 32'd0;
    reg [31:0] r1 = 32'd0;
    reg [31:0] r2 = 32'd0;
    reg [31:0] r3 = 32'd0;

    reg        aw_full = 1'b0;
    reg [1:0]  aw_idx = 2'd0;
    reg        w_full = 1'b0;
    reg [31:0] w_data = 32'd0;
    reg [3:0]  w_strb = 4'd0;

    assign awready = !aw_full && !bvalid;
    assign wready  = !w_full && !bvalid;
    assign bresp   = 2'b00;
    assign arready = !rvalid;
    assign rresp   = 2'b00;

    function [31:0] merge(input [31:0] old, input [31:0] nw, input [3:0] strb);
        integer b;
        begin
            merge = old;
            for (b = 0; b < 4; b = b + 1)
                if (strb[b]) merge[8 * b +: 8] = nw[8 * b +: 8];
        end
    endfunction

    always @(posedge clk)
        if (rst) begin
            aw_full <= 1'b0; w_full <= 1'b0; bvalid <= 1'b0;
            r0 <= 32'd0; r1 <= 32'd0; r2 <= 32'd0; r3 <= 32'd0;
        end else begin
            if (awvalid && awready) begin aw_full <= 1'b1; aw_idx <= awaddr[3:2]; end
            if (wvalid && wready)   begin w_full <= 1'b1; w_data <= wdata; w_strb <= wstrb; end
            if (aw_full && w_full) begin
                case (aw_idx)
                    2'd0: r0 <= merge(r0, w_data, w_strb);
                    2'd1: r1 <= merge(r1, w_data, w_strb);
                    2'd2: r2 <= merge(r2, w_data, w_strb);
                    default: r3 <= merge(r3, w_data, w_strb);
                endcase
                aw_full <= 1'b0;
                w_full  <= 1'b0;
                bvalid  <= 1'b1;
            end
            if (bvalid && bready) bvalid <= 1'b0;
        end

    always @(posedge clk)
        if (rst)
            rvalid <= 1'b0;
        else if (arvalid && arready) begin
            case (araddr[3:2])
                2'd0: rdata <= r0;
                2'd1: rdata <= r1;
                2'd2: rdata <= r2;
                default: rdata <= r3;
            endcase
            rvalid <= 1'b1;
        end else if (rvalid && rready)
            rvalid <= 1'b0;

    assign reg0 = r0;
    assign reg1 = r1;
    assign reg2 = r2;
    assign reg3 = r3;
endmodule

`default_nettype wire
