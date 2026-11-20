// Moduł nadrzędny DECA — Verilog. Czujniki płytki (20.02, 20.03, 20.05):
//   LIS2DH12 (akcelerometr, SPI tryb 3), LM71 (temperatura przy układzie FPGA, SPI 3-przewodowe),
//   HDC1000 (wilgotność i temperatura otoczenia, I²C, adres 0x40).
// Diody (SW[1:0]): 00 — „poziomica”: świeci dioda odpowiadająca przyspieszeniu w osi X (przechyl płytkę),
//   01 — temperatura LM71 w °C (binarnie), 10 — wilgotność HDC1000 w %, 11 — stan: LED[0] WHO_AM_I = 0x33,
//   LED[1] odczyty LIS2DH12 trwają, LED[2] odczyty HDC1000 trwają, LED[7:4] liczba odpowiedzi NACK (mod 16).
// Telemetria UART 115 200 8N1 na GPIO0_D[0] co 0,5 s, szesnastkowo:
//   "A xxxx yyyy zzzz T tttt H tttt wwww" + CR LF (akcelerometr X Y Z, LM71, HDC1000 temperatura i wilgotność).
// KEY[0] — reset.
`default_nettype none

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,
    input  wire [1:0] SW,
    output wire [7:0] LED,                     // 0 = świeci
    // akcelerometr
    output wire       G_SENSOR_SCLK,
    output wire       G_SENSOR_SDI,
    input  wire       G_SENSOR_SDO,
    output wire       G_SENSOR_CS_n,
    input  wire       G_SENSOR_INT1,
    input  wire       G_SENSOR_INT2,
    // LM71
    output wire       TEMP_SC,
    inout  wire       TEMP_SIO,
    output wire       TEMP_CS_n,
    // HDC1000
    inout  wire       RH_TEMP_I2C_SCL,
    inout  wire       RH_TEMP_I2C_SDA,
    input  wire       RH_TEMP_DRDY_n,
    // telemetria
    inout  wire [0:0] GPIO0_D
);
    wire clk = MAX10_CLK1_50;

    reg [1:0] rs = 2'b00;
    always @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    wire rst = ~rs[1];

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] s_sw = 2'b00;
    always @(posedge clk) s_sw <= SW;

    // ---- czujniki
    wire [15:0] ax, ay, az;
    wire [7:0]  who;
    wire        a_nowe, id_ok;
    akcel_lis2dh12 #(.DIV(13), .CZEKAJ(250_000), .OKRES(2_500_000)) u_akc (.clk(clk), .rst(rst),
        .sclk(G_SENSOR_SCLK), .mosi(G_SENSOR_SDI), .miso(G_SENSOR_SDO), .cs_n(G_SENSOR_CS_n), .x(ax), .y(ay),
        .z(az), .nowe(a_nowe), .who_am_i(who), .id_ok(id_ok));

    wire [13:0] lm_t;
    wire [8:0]  lm_c;
    wire        lm_nowe;
    temp_lm71 #(.DIV(25), .OKRES(25_000_000)) u_lm (.clk(clk), .rst(rst), .sc(TEMP_SC), .sio(TEMP_SIO),
        .cs_n(TEMP_CS_n), .temp(lm_t), .temp_c(lm_c), .nowe(lm_nowe));
    assign TEMP_SIO = 1'bz;                    // tylko odczyt

    wire        scl_oe, sda_oe, h_nowe;
    wire [15:0] h_t, h_w;
    wire [8:0]  h_c;
    wire [6:0]  h_proc;
    wire [7:0]  h_nacki;
    hdc1000 #(.ADR(7'h40), .DIV(125), .CZEKAJ(1_000_000), .OKRES(25_000_000)) u_hdc (.clk(clk), .rst(rst),
        .scl_i(RH_TEMP_I2C_SCL), .scl_oe(scl_oe), .sda_i(RH_TEMP_I2C_SDA), .sda_oe(sda_oe), .temp_sur(h_t),
        .wilg_sur(h_w), .temp_c(h_c), .wilg_proc(h_proc), .nowe(h_nowe), .nacki(h_nacki));
    assign RH_TEMP_I2C_SCL = scl_oe ? 1'b0 : 1'bz;  // open-drain: tylko zero albo wysoka impedancja
    assign RH_TEMP_I2C_SDA = sda_oe ? 1'b0 : 1'bz;

    // ---- wskaźniki aktywności (impuls nowe -> dioda świeci przez ok. 0,17 s)
    reg [22:0] a_akt = 23'd0, h_akt = 23'd0;
    always @(posedge clk) begin
        a_akt <= a_nowe ? {23{1'b1}} : (a_akt != 0) ? a_akt - 1'b1 : 23'd0;
        h_akt <= h_nowe ? {23{1'b1}} : (h_akt != 0) ? h_akt - 1'b1 : 23'd0;
    end

    // ---- diody
    wire [2:0] poz  = ax[15:13] ^ 3'b100;      // −2 g … +2 g -> 0 … 7
    reg  [7:0] diody;
    always @(*) case (s_sw)
        2'b00:   diody = 8'd1 << poz;
        2'b01:   diody = lm_c[7:0];
        2'b10:   diody = {1'b0, h_proc};
        default: diody = {h_nacki[3:0], 1'b0, h_akt != 0, a_akt != 0, id_ok};
    endcase
    assign LED = ~diody;

    // ---- telemetria
    wire       tx, gotowy;
    reg        start = 1'b0;
    reg  [7:0] znak = 8'd0;
    uart_tx #(.CLK_HZ(50_000_000), .BAUD(115_200)) u_tx (.clk(clk), .rst(rst), .start(start), .dane(znak),
        .gotowy(gotowy), .tx(tx));
    assign GPIO0_D[0] = tx;

    function [7:0] hex(input [3:0] n);
        hex = (n < 4'd10) ? 8'd48 + {4'd0, n} : 8'd55 + {4'd0, n};
    endfunction

    reg [95:0] migawka = 96'd0;                 // X Y Z LM71 HDC-T HDC-W w chwili rozpoczęcia linii
    reg [5:0]  zi = 6'd0;
    reg        nadaje = 1'b0;
    reg [24:0] okres = 25'd0;
    // znak nr i linii: pola po 4 cyfry szesnastkowe
    function [7:0] znak_linii(input [5:0] i, input [95:0] m);
        reg [3:0] c;
        begin
            case (i)
                6'd0: znak_linii = "A";  6'd17: znak_linii = "T";  6'd24: znak_linii = "H";
                6'd1, 6'd6, 6'd11, 6'd16, 6'd18, 6'd23, 6'd25, 6'd30: znak_linii = " ";
                6'd35: znak_linii = 8'h0D;
                6'd36: znak_linii = 8'h0A;
                default: begin
                    case (i)
                        6'd2, 6'd3, 6'd4, 6'd5:     c = m[95 - 4 * (i - 2) -: 4];   // X
                        6'd7, 6'd8, 6'd9, 6'd10:    c = m[79 - 4 * (i - 7) -: 4];   // Y
                        6'd12, 6'd13, 6'd14, 6'd15: c = m[63 - 4 * (i - 12) -: 4];  // Z
                        6'd19, 6'd20, 6'd21, 6'd22: c = m[47 - 4 * (i - 19) -: 4];  // LM71
                        6'd26, 6'd27, 6'd28, 6'd29: c = m[31 - 4 * (i - 26) -: 4];  // HDC T
                        default:                    c = m[15 - 4 * (i - 31) -: 4];  // HDC W
                    endcase
                    znak_linii = hex(c);
                end
            endcase
        end
    endfunction

    always @(posedge clk) begin
        start <= 1'b0;
        if (rst) begin
            nadaje <= 1'b0;
            okres  <= 25'd0;
        end else begin
            okres <= (okres == 25'd24_999_999) ? 25'd0 : okres + 1'b1;
            if (okres == 0 && !nadaje) begin
                migawka <= {ax, ay, az, {{2{lm_t[13]}}, lm_t}, h_t, h_w};
                nadaje  <= 1'b1;
                zi      <= 6'd0;
            end else if (nadaje && gotowy && !start) begin
                znak  <= znak_linii(zi, migawka);
                start <= 1'b1;
                zi    <= zi + 1'b1;
                if (zi == 6'd36) nadaje <= 1'b0;
            end
        end
    end
endmodule

`default_nettype wire
