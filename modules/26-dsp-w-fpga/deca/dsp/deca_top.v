// DECA — generator i filtr (moduł 26, 26.01 i 26.03): NCO -> filtr FIR (31 współczynników, fc ≈ 4,9 kHz)
// -> dwa przetworniki sigma-delta na złączu GPIO0 (3,3 V). Zegar 50 MHz, próbki co 1024 takty: fs = 48 828 Hz.
//   GPIO0_D[0] — sygnał po filtrze, GPIO0_D[1] — sygnał przed filtrem (każde przez filtr RC, np. 1 kΩ + 10 nF,
//   do oscyloskopu albo przez kondensator 10 µF do wzmacniacza/słuchawek).
//   SW[0] = 0 — stała częstotliwość, KEY[1] wybiera kolejną z 8 (250 Hz ... 8 kHz), dioda LED[k] pokazuje numer;
//   SW[0] = 1 — przemiatanie 100 Hz -> 12 kHz w ok. 2 s, diody jako linijka częstotliwości.
//   SW[1] = 1 — fala prostokątna zamiast sinusa (filtr usuwa harmoniczne powyżej ~5 kHz). KEY[0] — reset.
`default_nettype none

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,                     // 0 = wciśnięty
    input  wire [1:0] SW,                      // 0 = w dół
    output reg  [7:0] LED = 8'hFF,             // 0 = świeci
    output wire [1:0] GPIO0_D
);
    wire clk = MAX10_CLK1_50;
    localparam [16*31-1:0] WSP = 496'h00000027005B008B00810000FEF1FD9FFCC0FD48000005110BC3129317AB198E17AB12930BC305110000FD48FCC0FD9FFEF100000081008B005B00270000;      // h_30 ... h_0 (Q1.15, symetryczne)
    localparam [31:0] F_MIN = 32'd8796093;     // 100 Hz
    localparam [31:0] F_MAX = 32'd1055531163;  // 12 kHz
    localparam [31:0] KROK  = 32'd10718;       // (F_MAX - F_MIN) / 97 656 próbek ≈ 2 s

    function [31:0] f_tab(input [2:0] i);
        case (i)
            3'd0: f_tab = 32'd21990233;     // 250 Hz
            3'd1: f_tab = 32'd43980465;     // 500 Hz
            3'd2: f_tab = 32'd87960930;     // 1 kHz
            3'd3: f_tab = 32'd175921860;    // 2 kHz
            3'd4: f_tab = 32'd263882791;    // 3 kHz
            3'd5: f_tab = 32'd351843721;    // 4 kHz
            3'd6: f_tab = 32'd527765581;    // 6 kHz
            default: f_tab = 32'd703687442; // 8 kHz
        endcase
    endfunction

    // reset i przyciski (synchronizacja, KEY[1] próbkowany co 1 ms — bez drgań styków)
    reg [1:0] rs = 2'b11;
    always @(posedge clk) rs <= {rs[0], ~KEY[0]};
    wire rst = rs[1];
    reg [15:0] ms = 16'd0;
    reg [1:0]  k1 = 2'b11;
    reg        nacisk = 1'b0;
    always @(posedge clk) begin
        nacisk <= 1'b0;
        ms <= (ms == 16'd49999) ? 16'd0 : ms + 1'b1;
        if (ms == 16'd0) begin
            k1 <= {k1[0], KEY[1]};
            if (k1[0] == 1'b0 && k1[1] == 1'b1) nacisk <= 1'b1;
        end
    end

    // takt próbek fs = 50 MHz / 1024 i słowo częstotliwości
    reg  [9:0]  dz = 10'd0;
    reg         we = 1'b0;
    reg  [2:0]  idx = 3'd2;
    reg  [31:0] f_sw = F_MIN;
    always @(posedge clk) begin
        dz <= dz + 1'b1;
        we <= (dz == 10'd0);
        if (rst) begin
            idx <= 3'd2; f_sw <= F_MIN;
        end else begin
            if (nacisk) idx <= idx + 1'b1;
            if (we) f_sw <= (f_sw >= F_MAX) ? F_MIN : f_sw + KROK;
        end
    end
    wire [31:0] ftw = SW[0] ? f_sw : f_tab(idx);

    // NCO -> (sinus albo prostokąt, połowa amplitudy) -> FIR
    wire signed [15:0] s, c;
    wire               sv;
    nco u_nco (.clk(clk), .rst(rst), .we(we), .ftw(ftw), .sin_o(s), .cos_o(c), .wazne(sv));
    wire signed [15:0] x_we = SW[1] ? (s[15] ? -16'sd16000 : 16'sd16000) : {s[15], s[15:1]};
    reg  signed [15:0] surowy = 16'sd0;
    always @(posedge clk) if (sv) surowy <= x_we;
    wire signed [15:0] y;
    wire               yv;
    fir_transp #(.N(31)) u_fir (.clk(clk), .rst(rst), .we(sv), .x(x_we), .wsp(WSP), .y(y), .y_wazne(yv));

    sd_dac u_d0 (.clk(clk), .rst(rst), .x(y),      .q(GPIO0_D[0]));
    sd_dac u_d1 (.clk(clk), .rst(rst), .x(surowy), .q(GPIO0_D[1]));

    // diody: numer częstotliwości albo linijka (górne bity słowa przy przemiataniu)
    always @(posedge clk)
        if (SW[0]) LED <= ~(8'hFF >> (3'd7 - f_sw[29:27]));
        else       LED <= ~(8'd1 << idx);
endmodule

`default_nettype wire
