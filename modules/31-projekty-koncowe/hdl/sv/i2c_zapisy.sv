// Zapis tablicy rejestrów przez I2C (25.01): uogólnienie adv7513_konfig z 24.02 — tablica jako parametr
// TAB (N wpisów po 16 bitów {rejestr, wartość}, wpis 0 w najstarszych bitach), adres urządzenia ADRES.
// Seria po resecie, na żądanie (start) i cyklicznie co OKRES taktów (0 — wyłączone). Wpis: START, adres + zapis,
// rejestr, wartość, STOP; NACK przerywa serię (blad). Wpis o rejestrze 0xFF i wartości n — przerwa n·1024 ćwiartek
// okresu SCL (czas na reset/rozruch układu, np. kodeka). Linie z otwartym drenem: scl_o / sda_o = 0 — ściągnij.
`default_nettype none

module i2c_zapisy #(
    parameter integer F_CLK  = 25000000,
    parameter integer F_I2C  = 100000,
    parameter integer OKRES  = 0,               // takty między seriami (0 — tylko po resecie i na start)
    parameter [6:0]   ADRES  = 7'h18,
    parameter integer N      = 2,
    parameter [16*N-1:0] TAB = {16'h00_00, 16'h01_01}
) (
    input  logic clk,
    input  logic rst,
    input  logic start,
    output logic  zajety,
    output logic  gotowe,                         // ostatnia seria zakończona bez błędu
    output logic  blad,
    output logic  scl_o,
    output logic  sda_o,
    input  logic sda_i
);
    localparam integer DZ = F_CLK / (4 * F_I2C);    // takty na ćwierć okresu SCL
    /* verilator lint_off WIDTHTRUNC */
    localparam [7:0]  OST = N - 1;
    localparam [15:0] DZ1 = DZ - 1;
    /* verilator lint_on WIDTHTRUNC */

    /* verilator lint_off WIDTHEXPAND */
    function [15:0] tab(input [7:0] i);
        tab = TAB[16 * (N - 1 - i) +: 16];
    endfunction
    /* verilator lint_on WIDTHEXPAND */

    localparam [2:0] S_BEZCZ = 3'd0, S_START = 3'd1, S_BIT = 3'd2, S_STOP = 3'd3, S_PRZERWA = 3'd4;

    logic  [2:0]  stan;
    logic  [1:0]  faza;
    logic  [15:0] lt;
    logic  [7:0]  idx;
    logic  [17:0] pz;                              // licznik przerwy (wpis 0xFF)
    logic  [4:0]  b;                               // numer bitu ramki 26..0
    logic  [26:0] ramka;
    logic  [31:0] lo;
    logic         nack, start_w;
    logic        tik;
    assign tik = (lt == 16'd0);
    logic [15:0] wpis;
    assign wpis = tab(idx);
    logic        ack_poz;
    assign ack_poz = (b == 5'd18) || (b == 5'd9) || (b == 5'd0);

    always_ff @(posedge clk) begin
        if (rst) begin
            stan    <= S_BEZCZ;
            faza    <= 2'd0;
            lt      <= 16'd0;
            idx     <= 8'd0;
            pz      <= 18'd0;
            b       <= 5'd0;
            ramka   <= 27'd0;
            lo      <= 32'd0;
            nack    <= 1'b0;
            start_w <= 1'b1;                     // seria po resecie
            zajety  <= 1'b0;
            gotowe  <= 1'b0;
            blad    <= 1'b0;
            scl_o   <= 1'b1;
            sda_o   <= 1'b1;
        end else begin
            if (start) start_w <= 1'b1;
            if (OKRES > 0 && stan == S_BEZCZ) begin
                /* verilator lint_off WIDTHEXPAND */
                if (lo >= OKRES - 1) begin lo <= 32'd0; start_w <= 1'b1; end
                /* verilator lint_on WIDTHEXPAND */
                else lo <= lo + 1'b1;
            end
            lt <= tik ? DZ1 : lt - 1'b1;
            if (tik) begin
                faza <= faza + 1'b1;
                case (stan)
                    S_BEZCZ: begin
                        faza <= 2'd0;
                        if (start_w) begin
                            start_w <= 1'b0;
                            zajety  <= 1'b1;
                            idx     <= 8'd0;
                            nack    <= 1'b0;
                            stan    <= S_START;
                        end
                    end
                    S_START:                                     // SDA opada przy SCL = 1
                        case (faza)
                            2'd0: begin
                                sda_o <= 1'b1; scl_o <= 1'b1;
                                ramka <= {ADRES, 1'b0, 1'b1, wpis[15:8], 1'b1, wpis[7:0], 1'b1};
                                if (wpis[15:8] == 8'hFF) begin    // wpis-przerwa: bez transakcji
                                    pz   <= {wpis[7:0], 10'd0};
                                    faza <= 2'd0;
                                    stan <= S_PRZERWA;
                                end
                            end
                            2'd1: sda_o <= 1'b0;
                            2'd2: ;                                  // t_HD;STA ≥ 4 µs: dwie ćwiartki
                            default: begin scl_o <= 1'b0; b <= 5'd26; stan <= S_BIT; end
                        endcase
                    S_BIT:
                        case (faza)
                            2'd0: sda_o <= ramka[b];                 // zmiana danych przy SCL = 0
                            2'd1: scl_o <= 1'b1;
                            2'd2: if (ack_poz && sda_i) nack <= 1'b1; // potwierdzenie: odbiornik ściąga SDA
                            default: begin
                                scl_o <= 1'b0;
                                if (b == 5'd0) stan <= S_STOP;
                                else b <= b - 1'b1;
                            end
                        endcase
                    S_STOP:                                      // SDA rośnie przy SCL = 1
                        case (faza)
                            2'd0: sda_o <= 1'b0;
                            2'd1: scl_o <= 1'b1;
                            2'd2: ;                                  // t_SU;STO ≥ 4 µs
                            default: begin sda_o <= 1'b1; stan <= S_PRZERWA; end
                        endcase
                    default:                                     // czas wolnej magistrali przed kolejnym START
                        if (pz != 18'd0) begin
                            pz   <= pz - 1'b1;
                            faza <= 2'd0;
                        end else if (faza == 2'd3) begin
                            if (nack || idx == OST) begin
                                zajety <= 1'b0;
                                gotowe <= !nack;
                                blad   <= nack;
                                stan   <= S_BEZCZ;
                            end else begin
                                idx  <= idx + 1'b1;
                                stan <= S_START;
                            end
                        end
                endcase
            end
        end
    end
endmodule

`default_nettype wire
