// DECA — projekt 6 (31.06): mikrokontroler rv_mcu (własny rdzeń RV32I rv_potok) z programem mcu.S
// (mcu_deca.hex / mcu_deca.mif z program/zloz.py), zegar 50 MHz bez PLL.
//   GPIO0_D[0] — UART TX, GPIO0_D[1] — UART RX (przejściówka USB-UART 3,3 V, 115 200 b/s 8N1): powitanie,
//   echo z zamianą liter na wielkie, 'q' kończy program. LED[6:0] — licznik zmieniany co 0,25 s
//   (licznik sprzętowy i porównanie), LED[7] — PWM 10 % przy 1 kHz. KEY[0] — reset.
`default_nettype none

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,
    input  wire [1:0] SW,
    output wire [7:0] LED,
    inout  wire [1:0] GPIO0_D
);
    wire clk = MAX10_CLK1_50;
    reg [1:0] rs = 2'b11;
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [3:0] s1 = 4'hF;
    reg [3:0] s2 = 4'hF;
    always @(posedge clk) begin
        rs <= {rs[0], ~KEY[0]};
        s1 <= {SW, KEY};
        s2 <= s1;
    end

    wire [31:0] led;
    wire        tx, pwm_wy;
    /* verilator lint_off PINCONNECTEMPTY */
    rv_mcu #(.SLOWA(1024), .PLIK("mcu_deca.hex"), .CLK_HZ(50_000_000), .BAUD(115_200)) u_mcu (.clk(clk),
        .rst(rs[1]), .wej({28'd0, s2}), .led(led), .uart_rx(GPIO0_D[1]), .uart_tx(tx), .pwm_wy(pwm_wy),
        .koniec(), .wycofana());
    /* verilator lint_on PINCONNECTEMPTY */
    assign GPIO0_D[0] = tx;
    assign GPIO0_D[1] = 1'bz;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [31:0] led_w = led;
    /* verilator lint_on UNUSEDSIGNAL */
    assign LED = ~{pwm_wy, led_w[6:0]};
endmodule

`default_nettype wire
