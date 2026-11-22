// Projekt 3 (31.03): syntezator sterowany przez MIDI albo UART. uart_rx (BAUD: 31 250 dla MIDI) -> midi_parser
// -> syntezator -> i2s_master (wyjście do kodeka; fs = f_clk / 256, przy 12,5 MHz 48,83 kHz, ten sam sygnał
// w obu kanałach). Port probka/nowa — do obserwacji (testbench, wskaźnik poziomu).
`default_nettype none

module projekt_syntezator #(
    parameter integer  CLK_HZ = 12_500_000,
    parameter integer  BAUD   = 31_250,
    parameter [16:0]   A_KROK = 17'd268,
    parameter [16:0]   D_KROK = 17'd5,
    parameter [16:0]   S_POZ  = 17'd39321,
    parameter [16:0]   R_KROK = 17'd4
) (
    input  logic               clk,
    input  logic               rst,
    input  logic               rx,
    output logic               bclk,
    output logic               wclk,
    output logic               dout,
    output logic signed [23:0] probka,
    output logic               nowa,
    output logic [3:0]         aktywne,
    output logic               blad_ramki
);
    logic [7:0] rx_dane;
    logic       rx_wazne, ev_on, ev_off, ev_wsz, ev_prog, ramka;
    logic [6:0] nuta, vel;
    logic [1:0] prog;

    /* verilator lint_off PINCONNECTEMPTY */
    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_rx (.clk(clk), .rst(rst), .rx(rx), .dane(rx_dane), .wazne(rx_wazne),
        .blad_ramki(blad_ramki), .blad_parz());
    /* verilator lint_on PINCONNECTEMPTY */
    midi_parser u_midi (.clk(clk), .rst(rst), .dane(rx_dane), .wazne(rx_wazne), .ev_on(ev_on), .ev_off(ev_off),
        .ev_wszystkie(ev_wsz), .ev_prog(ev_prog), .nuta(nuta), .vel(vel), .prog(prog));
    syntezator #(.A_KROK(A_KROK), .D_KROK(D_KROK), .S_POZ(S_POZ), .R_KROK(R_KROK)) u_synt (.clk(clk), .rst(rst),
        .ramka(ramka), .ev_on(ev_on), .ev_off(ev_off), .ev_wszystkie(ev_wsz), .ev_prog(ev_prog), .nuta(nuta),
        .vel(vel), .prog(prog), .probka(probka), .nowa(nowa), .aktywne(aktywne));
    /* verilator lint_off PINCONNECTEMPTY */
    i2s_master u_i2s (.clk(clk), .rst(rst), .tx_l(probka), .tx_p(probka), .rx_l(), .rx_p(), .ramka(ramka),
        .bclk(bclk), .wclk(wclk), .dout(dout), .din(1'b0));
    /* verilator lint_on PINCONNECTEMPTY */
endmodule

`default_nettype wire
