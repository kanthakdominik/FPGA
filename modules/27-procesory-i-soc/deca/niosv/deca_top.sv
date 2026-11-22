// DECA — Nios V (27.02, 27.03): system Platform Designer system_niosv (Nios V/m, 64 KB pamięci, JTAG UART,
// PIO na LED[6:0], peryferium pwm_avl na LED[7]) generowany z system.tcl (make system). Program w C:
// software/main.c (BSP i aplikacja: README.md). KEY[0] — reset systemu.
// Bez wygenerowanego systemu kompiluje się tylko wariant symulacyjny (DECA_SYMULACJA) z samym pwm_avl.
`default_nettype none
`ifdef __ICARUS__
`define DECA_SYMULACJA
`endif
`ifdef VERILATOR
`define DECA_SYMULACJA
`endif

module deca_top (
    input  logic       MAX10_CLK1_50,
    input  logic [1:0] KEY,                     // 0 = wciśnięty
    output logic [7:0] LED                      // 0 = świeci
);
    logic clk;
    assign clk = MAX10_CLK1_50;

    logic [1:0] rs = 2'b00;                      // reset: asynchroniczne wejście, synchroniczne zwolnienie
    always_ff @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    logic rst_n;
    assign rst_n = rs[1];

    logic [6:0] led;
    logic       pwm;

`ifdef DECA_SYMULACJA
    /* verilator lint_off PINCONNECTEMPTY */
    pwm_avl u_pwm (.clk(clk), .rst(!rst_n), .address(2'd0), .read(1'b0), .write(1'b0), .writedata(32'd0),
        .readdata(), .irq(), .pwm(pwm));
    /* verilator lint_on PINCONNECTEMPTY */
    assign led = 7'd0;
`else
    system_niosv u_sys (
        .clk_clk       (clk),
        .reset_reset_n (rst_n),
        .led_export    (led),
        .pwm_pwm       (pwm)
    );
`endif

    assign LED = ~{pwm, led};
endmodule

`default_nettype wire
