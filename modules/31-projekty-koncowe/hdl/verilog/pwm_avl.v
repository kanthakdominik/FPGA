// Peryferium PWM ze slave'em Avalon-MM (27.03): cztery rejestry 32-bitowe (adresy słów), odczyt z opóźnieniem
// 1 takt (readLatency = 1), bez waitrequest i byteenable (tylko dostęp 32-bitowy), przerwanie poziomem.
//   0 STER    (RW)  bit 0 WL — włączenie, bit 1 PRZ — zezwolenie na przerwanie
//   1 OKRES   (RW)  długość okresu w taktach (≥ 2)
//   2 WYPELN  (RW)  liczba taktów stanu wysokiego w okresie (0 — zawsze 0, ≥ OKRES — zawsze 1)
//   3 STATUS  (R/W1C) bit 0 KONIEC — koniec okresu (zapis 1 kasuje), bit 1 — bieżący stan wyjścia
// Nowe OKRES i WYPELN działają od początku następnego okresu (rejestry cienia — bez zakłóceń w trakcie okresu);
// przy wyłączonym PWM — od razu. irq = KONIEC & PRZ.
`default_nettype none

module pwm_avl (
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  address,
    input  wire        read,
    input  wire        write,
    input  wire [31:0] writedata,
    output reg  [31:0] readdata,
    output wire        irq,
    output reg         pwm
);
    reg  [1:0]  ster;
    reg  [31:0] okres_n, wyp_n;          // zapisane przez procesor
    reg  [31:0] okres, wyp;              // obowiązujące w bieżącym okresie
    reg  [31:0] licznik;
    reg         koniec;

    wire        wl = ster[0];
    wire        ostatni = (licznik + 32'd1 >= okres);
    wire        kasuj = write && address == 2'd3 && writedata[0];

    always @(posedge clk) begin
        if (rst) begin
            ster <= 2'd0; okres_n <= 32'd0; wyp_n <= 32'd0; okres <= 32'd0; wyp <= 32'd0;
            licznik <= 32'd0; koniec <= 1'b0; pwm <= 1'b0;
        end else begin
            if (write)
                case (address)
                    2'd0: ster    <= writedata[1:0];
                    2'd1: okres_n <= writedata;
                    2'd2: wyp_n   <= writedata;
                    default: ;
                endcase
            if (!wl) begin
                licznik <= 32'd0;
                okres   <= okres_n;
                wyp     <= wyp_n;
                if (kasuj) koniec <= 1'b0;
            end else if (ostatni) begin
                licznik <= 32'd0;
                okres   <= okres_n;
                wyp     <= wyp_n;
                koniec  <= 1'b1;                          // ustawienie ma pierwszeństwo przed kasowaniem
            end else begin
                licznik <= licznik + 32'd1;
                if (kasuj) koniec <= 1'b0;
            end
            pwm <= wl && (licznik < wyp);
        end
    end

    always @(posedge clk)
        if (read)
            case (address)
                2'd0:    readdata <= {30'd0, ster};
                2'd1:    readdata <= okres_n;
                2'd2:    readdata <= wyp_n;
                default: readdata <= {30'd0, pwm, koniec};
            endcase

    assign irq = koniec && ster[1];
endmodule

`default_nettype wire
