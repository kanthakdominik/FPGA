// Moduł nadrzędny DECA — Verilog. Rejestry kursu (21.02) w systemie Platform Designer (21.06):
// JTAG to Avalon Master Bridge -> avmm_rejestry. Odczyt i zapis rejestrów z komputera przez USB-Blaster
// płytki skryptem System Console (konsola.tcl) — bez dodatkowego sprzętu.
//   LED[6:0] — STER[6:0], LED[7] — irq;  STAN = {SW, KEY} (bity 3:0);  zdarzenie 0 — naciśnięcie KEY[1].
//   KEY[0] — reset systemu.
// System system_rej generuje się z system.tcl (make system, README.md); bez niego kompiluje się tylko
// wariant symulacyjny (DECA_SYMULACJA) z samym rdzeniem rejestrów.
`default_nettype none
`ifdef __ICARUS__
`define DECA_SYMULACJA
`endif
`ifdef VERILATOR
`define DECA_SYMULACJA
`endif

module deca_top (
    input  logic       MAX10_CLK1_50,
    input  logic [1:0] KEY,
    input  logic [1:0] SW,
    output logic [7:0] LED                      // 0 = świeci
);
    logic clk;
    assign clk = MAX10_CLK1_50;

    logic [1:0] rs = 2'b00;                      // reset: asynchroniczne wejście, synchroniczne zwolnienie
    always_ff @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    logic rst_n;
    assign rst_n = rs[1];

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [3:0] s_we = 4'hF;
    logic [3:0] s_we2 = 4'hF;
    always_ff @(posedge clk) begin
        s_we  <= {SW, KEY};
        s_we2 <= s_we;
    end
    // naciśnięcie KEY[1] (bez filtra drgań: kilka impulsów to nadal ustawiony bit W1C)
    logic nacisk;
    assign nacisk = s_we2[1] && !s_we[1];

    logic [31:0] ster;
    logic        irq;
    logic [31:0] stan;
    assign stan = {28'd0, s_we};
    logic [7:0]  zdarz;
    assign zdarz = {7'd0, nacisk};

`ifdef DECA_SYMULACJA
    /* verilator lint_off PINCONNECTEMPTY */
    avmm_rejestry u_rej (.clk(clk), .rst(!rst_n), .address(4'd0), .read(1'b0), .write(1'b0), .writedata(32'd0),
        .byteenable(4'd0), .readdata(), .response(), .ster(ster), .stan(stan), .zdarz(zdarz), .irq(irq));
    /* verilator lint_on PINCONNECTEMPTY */
`else
    system_rej u_sys (
        .clk_clk       (clk),
        .reset_reset_n (rst_n),
        .uklad_ster    (ster),
        .uklad_stan    (stan),
        .uklad_zdarz   (zdarz),
        .uklad_irq     (irq)
    );
`endif

    assign LED = ~{irq, ster[6:0]};
endmodule

`default_nettype wire
