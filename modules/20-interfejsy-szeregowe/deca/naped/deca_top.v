// Moduł nadrzędny DECA — Verilog. PWM z czasem martwym, serwomechanizm i enkoder (20.04):
//   GPIO0_D[2], GPIO0_D[3] — wyjścia górne i dolne gałęzi mostka (PWM 25 kHz, czas martwy 400 ns),
//   GPIO0_D[4] — sygnał serwa (50 Hz, 1–2 ms), GPIO0_D[5], GPIO0_D[6] — wejścia A, B enkodera
//   (z podciąganiem w układzie; styk enkodera zwiera do masy).
// Nastawa (0…255): SW[0] = 0 — pozycja enkodera, SW[0] = 1 — automatyczny przebieg trójkątny (bez enkodera).
// Nastawa steruje wypełnieniem PWM i pozycją serwa. LED[7] — wyjście górne PWM (jasność = wypełnienie),
// LED[6:0] — nastawa (7 starszych bitów). SW[1] = 1 — LED[6:0] pokazuje licznik błędów enkodera. KEY[0] — reset.
`default_nettype none

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,
    input  wire [1:0] SW,
    output wire [7:0] LED,                     // 0 = świeci
    inout  wire [6:2] GPIO0_D
);
    wire clk = MAX10_CLK1_50;

    reg [1:0] rs = 2'b00;
    always @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    wire rst = ~rs[1];

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] s_sw = 2'b00;
    always @(posedge clk) s_sw <= SW;

    // ---- enkoder
    wire [15:0] pozycja;
    wire        kierunek;
    wire [7:0]  bledy;
    enkoder #(.W(16), .FILTR(250)) u_enk (.clk(clk), .rst(rst), .a(GPIO0_D[5]), .b(GPIO0_D[6]),
        .pozycja(pozycja), .kierunek(kierunek), .bledy(bledy));      // filtr 5 µs
    assign GPIO0_D[5] = 1'bz;
    assign GPIO0_D[6] = 1'bz;

    // ---- przebieg trójkątny (pełny cykl ok. 2,7 s)
    reg [22:0] wolny = 23'd0;
    reg [7:0]  trojkat = 8'd0;
    reg        w_gore = 1'b1;
    always @(posedge clk) begin
        wolny <= wolny + 1'b1;
        if (wolny == 0) begin
            if (w_gore) begin
                if (trojkat == 8'd254) w_gore <= 1'b0;
                trojkat <= trojkat + 1'b1;
            end else begin
                if (trojkat == 8'd1) w_gore <= 1'b1;
                trojkat <= trojkat - 1'b1;
            end
        end
    end

    // pozycja enkodera ×4 na krok — nastawa = pozycja / 4, ograniczona do 0…255
    wire [13:0] krok = pozycja[15:2];
    wire [7:0]  z_enk = pozycja[15] ? 8'd0 : (krok > 14'd255) ? 8'd255 : krok[7:0];
    wire [7:0]  nastawa = s_sw[0] ? trojkat : z_enk;

    // ---- PWM: 50 MHz / (2·1000) = 25 kHz, czas martwy 20 taktów = 400 ns
    wire gora, dol, poczatek;
    /* verilator lint_off PINCONNECTEMPTY */
    pwm_mostek #(.W(10), .OKRES(1000), .MARTWY(20)) u_pwm (.clk(clk), .rst(rst),
        .wyp({nastawa, 2'b00}), .gora(gora), .dol(dol), .poczatek());   // 4·nastawa, powyżej 1000 = 100 %
    /* verilator lint_on PINCONNECTEMPTY */
    assign GPIO0_D[2] = gora;
    assign GPIO0_D[3] = dol;

    // ---- serwo
    wire impuls;
    serwo #(.CLK_HZ(50_000_000)) u_serwo (.clk(clk), .rst(rst), .pozycja(nastawa), .impuls(impuls));
    assign GPIO0_D[4] = impuls;

    assign LED = ~{gora, s_sw[1] ? bledy[6:0] : nastawa[7:1]};
endmodule

`default_nettype wire
