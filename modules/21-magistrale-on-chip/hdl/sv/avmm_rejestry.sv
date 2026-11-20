// Slave Avalon-MM (21.02) nad rejestry_rdzen: adresy słów, bez waitrequest, stałe opóźnienie odczytu
// 1 takt (readLatency = 1), sygnał response (00 OKAY, 10 SLAVEERROR) razem z readdata.
`default_nettype none

module avmm_rejestry #(
    parameter [31:0] ID = 32'h2102_0001
) (
    input  logic        clk,
    input  logic        rst,
    input  logic [3:0]  address,
    input  logic        read,
    input  logic        write,
    input  logic [31:0] writedata,
    input  logic [3:0]  byteenable,
    output logic  [31:0] readdata,
    output logic  [1:0]  response,
    output logic [31:0] ster,
    input  logic [31:0] stan,
    input  logic [7:0]  zdarz,
    output logic        irq
);
    logic [31:0] odc_dane;
    logic        odc_blad;

    /* verilator lint_off PINCONNECTEMPTY */
    rejestry_rdzen #(.ID(ID)) u_rdzen (
        .clk(clk), .rst(rst),
        .zap(write), .zap_adr(address), .zap_dane(writedata), .zap_str(byteenable), .zap_blad(),
        .odc_adr(address), .odc_dane(odc_dane), .odc_blad(odc_blad),
        .ster(ster), .stan(stan), .zdarz(zdarz), .irq(irq));
    /* verilator lint_on PINCONNECTEMPTY */

    always_ff @(posedge clk) begin
        if (read) begin
            readdata <= odc_dane;
            response <= odc_blad ? 2'b10 : 2'b00;
        end
    end
endmodule

`default_nettype wire
