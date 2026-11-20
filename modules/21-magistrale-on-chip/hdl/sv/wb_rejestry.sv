// Slave Wishbone B4, tryb potokowy (21.04), nad rejestry_rdzen: STALL = 0, odpowiedź ACK albo ERR
// (adres spoza mapy) w takcie po żądaniu; jedno żądanie na takt.
`default_nettype none

module wb_rejestry #(
    parameter [31:0] ID = 32'h2102_0001
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        cyc,
    input  logic        stb,
    input  logic        we,
    input  logic [3:0]  adr,                       // adres słowa
    input  logic [31:0] dat_i,
    input  logic [3:0]  sel,
    output logic  [31:0] dat_o,
    output logic         ack,
    output logic         err,
    output logic        stall,
    output logic [31:0] ster,
    input  logic [31:0] stan,
    input  logic [7:0]  zdarz,
    output logic        irq
);
    logic        zad;
    assign zad = cyc && stb;
    logic [31:0] odc_dane;
    logic        odc_blad;

    assign stall = 1'b0;

    /* verilator lint_off PINCONNECTEMPTY */
    rejestry_rdzen #(.ID(ID)) u_rdzen (
        .clk(clk), .rst(rst),
        .zap(zad && we), .zap_adr(adr), .zap_dane(dat_i), .zap_str(sel), .zap_blad(),
        .odc_adr(adr), .odc_dane(odc_dane), .odc_blad(odc_blad),
        .ster(ster), .stan(stan), .zdarz(zdarz), .irq(irq));
    /* verilator lint_on PINCONNECTEMPTY */

    always_ff @(posedge clk) begin
        if (rst || !cyc) begin                    // koniec cyklu kasuje odpowiedzi w drodze
            ack <= 1'b0;
            err <= 1'b0;
        end else begin
            ack   <= zad && !odc_blad;
            err   <= zad && odc_blad;
            dat_o <= odc_dane;
        end
    end
endmodule

`default_nettype wire
