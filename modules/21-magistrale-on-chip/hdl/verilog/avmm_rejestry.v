// Slave Avalon-MM (21.02) nad rejestry_rdzen: adresy słów, bez waitrequest, stałe opóźnienie odczytu
// 1 takt (readLatency = 1), sygnał response (00 OKAY, 10 SLAVEERROR) razem z readdata.
`default_nettype none

module avmm_rejestry #(
    parameter [31:0] ID = 32'h2102_0001
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  address,
    input  wire        read,
    input  wire        write,
    input  wire [31:0] writedata,
    input  wire [3:0]  byteenable,
    output reg  [31:0] readdata,
    output reg  [1:0]  response,
    output wire [31:0] ster,
    input  wire [31:0] stan,
    input  wire [7:0]  zdarz,
    output wire        irq
);
    wire [31:0] odc_dane;
    wire        odc_blad;

    /* verilator lint_off PINCONNECTEMPTY */
    rejestry_rdzen #(.ID(ID)) u_rdzen (
        .clk(clk), .rst(rst),
        .zap(write), .zap_adr(address), .zap_dane(writedata), .zap_str(byteenable), .zap_blad(),
        .odc_adr(address), .odc_dane(odc_dane), .odc_blad(odc_blad),
        .ster(ster), .stan(stan), .zdarz(zdarz), .irq(irq));
    /* verilator lint_on PINCONNECTEMPTY */

    always @(posedge clk) begin
        if (read) begin
            readdata <= odc_dane;
            response <= odc_blad ? 2'b10 : 2'b00;
        end
    end
endmodule

`default_nettype wire
