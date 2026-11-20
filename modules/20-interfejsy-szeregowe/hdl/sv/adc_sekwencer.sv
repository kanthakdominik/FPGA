// Sekwencer dla rdzenia ADC MAX 10 w konfiguracji „ADC Control Core Only” (20.06). Interfejs rozkazów
// Avalon-ST (ready latency 0): kanał wystawiony z command_valid, przyjęty, gdy command_ready = 1.
// Interfejs odpowiedzi bez przeciwciśnienia: response_valid przez jeden takt z kanałem i 12-bitową próbką.
// Sekwencer obiega listę LICZBA kanałów (KANALY: po 5 bitów, kanał 0 w najmłodszych bitach; 17 — termodioda),
// zapamiętuje ostatnią próbkę każdego kanału i podaje ją dalej (nowy, kanal, dane).
`default_nettype none

module adc_sekwencer #(
    parameter       LICZBA = 2,
    parameter [39:0] KANALY = {30'd0, 5'd17, 5'd1}        // {…, kanał 1, kanał 0} (do 8 kanałów)
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic                 wlacz,
    // do rdzenia ADC
    output logic                  command_valid = 1'b0,
    output logic  [4:0]           command_channel = 5'd0,
    output logic                 command_startofpacket,
    output logic                 command_endofpacket,
    input  logic                 command_ready,
    // z rdzenia ADC
    input  logic                 response_valid,
    input  logic [4:0]           response_channel,
    input  logic [11:0]          response_data,
    // wyniki
    output logic  [LICZBA*12-1:0] wyniki = {LICZBA*12{1'b0}},   // próbka kanału i w bitach [12i+11:12i]
    output logic                  nowy = 1'b0,
    output logic  [4:0]           kanal = 5'd0,
    output logic  [11:0]          dane = 12'd0
);
    localparam IW = (LICZBA > 1) ? $clog2(LICZBA) : 1;
    /* verilator lint_off WIDTHTRUNC */
    localparam [IW-1:0] OST = LICZBA - 1;
    /* verilator lint_on WIDTHTRUNC */

    assign command_startofpacket = 1'b0;               // w rdzeniu „Control Core Only” nieużywane
    assign command_endofpacket   = 1'b0;

    logic  [IW-1:0] idx = {IW{1'b0}};
    logic [IW-1:0] nast;
    assign nast = (idx == OST) ? {IW{1'b0}} : idx + 1'b1;
    integer i;

    always_ff @(posedge clk) begin
        nowy <= 1'b0;
        if (rst) begin
            command_valid <= 1'b0;
            idx           <= {IW{1'b0}};
        end else begin
            command_valid   <= wlacz;
            command_channel <= KANALY[idx*5 +: 5];
            if (command_valid && command_ready) begin    // rozkaz przyjęty: następny kanał
                idx             <= nast;
                command_channel <= KANALY[nast*5 +: 5];
            end
            if (response_valid) begin
                nowy  <= 1'b1;
                kanal <= response_channel;
                dane  <= response_data;
                for (i = 0; i < LICZBA; i = i + 1)
                    if (KANALY[i*5 +: 5] == response_channel)
                        wyniki[i*12 +: 12] <= response_data;
            end
        end
    end
endmodule

`default_nettype wire
