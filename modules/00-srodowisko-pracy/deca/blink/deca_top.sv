// Moduł nadrzędny dla płytki DECA — SystemVerilog.
// LED[0] miga z częstotliwością 1 Hz, LED[1] z 4 Hz. KEY[0] (wciśnięty = 0) zeruje liczniki.
// Diody DECA świecą przy stanie niskim, więc wyjścia są odwrócone.
module deca_top (
    input  logic       MAX10_CLK1_50,   // 50 MHz, pin M8
    input  logic [1:0] KEY,             // przyciski, wciśnięty = 0
    output logic [7:0] LED              // diody, 0 = świeci
);
    // synchronizacja przycisku z zegarem (moduł 15)
    logic [1:0] key0_sync = 2'b11;
    always_ff @(posedge MAX10_CLK1_50)
        key0_sync <= {key0_sync[0], KEY[0]};

    logic rst;
    assign rst = ~key0_sync[1];

    logic blink_1hz, blink_4hz;

    blink #(.CLK_HZ(50_000_000), .BLINK_HZ(1)) u_blink_1hz (
        .clk(MAX10_CLK1_50), .rst, .led(blink_1hz)
    );

    blink #(.CLK_HZ(50_000_000), .BLINK_HZ(4)) u_blink_4hz (
        .clk(MAX10_CLK1_50), .rst, .led(blink_4hz)
    );

    // 1 = świeci w naszej logice, 0 = świeci na płytce
    assign LED = ~{6'b000000, blink_4hz, blink_1hz};
endmodule
