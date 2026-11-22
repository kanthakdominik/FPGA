// DECA — własny SoC RISC-V (27.07): rv_soc z rdzeniem potokowym rv_potok, 8 KB pamięci (bloki M9K) z programem
// deca.S (deca_prog.hex, składany przez program/rvasm.py), rejestry systemowe i pwm_avl. Zegar 50 MHz, bez PLL.
//   LED[6:0] — rejestr LED programu (licznik albo biegnące światło), LED[7] — wyjście PWM („oddychanie”);
//   SW[0] — tryb, SW[1] — stop, KEY[1] — zerowanie licznika, KEY[0] — reset procesora.
`default_nettype none

module deca_top (
    input  logic       MAX10_CLK1_50,
    input  logic [1:0] KEY,                     // 0 = wciśnięty
    input  logic [1:0] SW,
    output logic [7:0] LED                      // 0 = świeci
);
    logic clk;
    assign clk = MAX10_CLK1_50;

    logic [1:0] rs = 2'b11;                      // reset: synchronizacja KEY[0]
    always_ff @(posedge clk) rs <= {rs[0], ~KEY[0]};

    logic [3:0] s1 = 4'hF;                       // synchronizacja wejść programu
    logic [3:0] s2 = 4'hF;
    always_ff @(posedge clk) begin
        s1 <= {SW, KEY};
        s2 <= s1;
    end

    logic [31:0] led;
    logic        pwm_wy;
    /* verilator lint_off PINCONNECTEMPTY */
    rv_soc #(.SLOWA(2048), .PLIK("deca_prog.hex")) u_soc (
        .clk(clk), .rst(rs[1]), .wej({28'd0, s2}), .led(led), .pwm_wy(pwm_wy), .pwm_irq(),
        .koniec(), .znak(), .znak_wazny(), .wycofana(), .mon_adr(), .mon_dane(), .mon_strb());
    /* verilator lint_on PINCONNECTEMPTY */

    assign LED = ~{pwm_wy, led[6:0]};
endmodule

`default_nettype wire
