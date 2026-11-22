// Akwizycja oscyloskopu (31.02), domena zegara ADC. Próbki (co DZIEL-ta) trafiają cyklicznie do jednego z dwóch
// banków pamięci po N próbek (8 najstarszych bitów). Przebieg zrzutu:
//   S_PRZED  — zebranie PRZED próbek historii (żeby przed wyzwoleniem było co pokazać),
//   S_CZEKA  — uzbrojony: wyzwolenie na zboczu narastającym (poprzednia < poziom <= bieżąca) albo, w trybie
//              auto, po AUTO próbkach bez wyzwolenia,
//   S_PO     — N - PRZED - 1 próbek po wyzwoleniu,
//   S_GOTOWE — bank i adres początku czekają na odbiór przez domenę obrazu (przełącznik gotowy/potw z
//              synchronizatorami), potem następny zrzut do drugiego banku.
`default_nettype none

module zrzut #(
    parameter integer AW    = 9,             // N = 2^AW próbek w banku
    parameter integer PRZED = 64,
    parameter integer AUTO  = 4096
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          we,                // nowa próbka
    input  logic [11:0]   probka,
    input  logic [11:0]   poziom,
    input  logic [7:0]    dziel,             // 0 i 1 — każda próbka
    input  logic          tryb_auto,
    // zapis do pamięci (bank, adres)
    output logic           ram_we = 1'b0,
    output logic  [AW:0]   ram_adr = {(AW+1){1'b0}},
    output logic  [7:0]    ram_dane = 8'd0,
    // przekazanie gotowego zrzutu
    output logic           bank_gotowy = 1'b0,
    output logic  [AW-1:0] poczatek = {AW{1'b0}},
    output logic           wyzwolony = 1'b0,    // 1 — z wyzwolenia, 0 — z trybu auto
    output logic           gotowy_t = 1'b0,     // przełącznik: zmiana = nowy zrzut
    input  logic          potw_t,              // przełącznik potwierdzenia z domeny obrazu (asynchroniczny)
    output logic          zajety
);
    localparam [1:0] S_PRZED = 2'd0, S_CZEKA = 2'd1, S_PO = 2'd2, S_GOTOWE = 2'd3;
    /* verilator lint_off WIDTHTRUNC */
    localparam [AW-1:0] PRZED_W = PRZED;
    localparam [AW-1:0] PO_W    = (1 << AW) - PRZED - 1;
    localparam [15:0]   AUTO_W  = AUTO;
    /* verilator lint_on WIDTHTRUNC */

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0] s_potw = 2'b00;
    always_ff @(posedge clk) s_potw <= {s_potw[0], potw_t};

    logic  [1:0]    stan = S_PRZED;
    logic           bank = 1'b0;
    logic  [AW-1:0] wp = {AW{1'b0}};
    logic  [AW-1:0] licz = {AW{1'b0}};
    logic  [15:0]   czekanie = 16'd0;
    logic  [7:0]    fd = 8'd0;
    logic  [11:0]   poprz = 12'd0;
    logic          bierz;
    assign bierz = we && (fd == 8'd0);
    logic          zbocze;
    assign zbocze = (poprz < poziom) && (probka >= poziom);
    assign zajety = (stan != S_GOTOWE);

    always_ff @(posedge clk) begin
        ram_we <= 1'b0;
        if (rst) begin
            stan <= S_PRZED; bank <= 1'b0; wp <= {AW{1'b0}}; licz <= {AW{1'b0}}; fd <= 8'd0;
            czekanie <= 16'd0; gotowy_t <= 1'b0;
        end else begin
            if (we) fd <= (fd + 8'd1 >= dziel) ? 8'd0 : fd + 8'd1;
            if (bierz && stan != S_GOTOWE) begin
                ram_we   <= 1'b1;
                ram_adr  <= {bank, wp};
                ram_dane <= probka[11:4];
                wp       <= wp + 1'b1;
                poprz    <= probka;
            end
            case (stan)
                S_PRZED:
                    if (bierz) begin
                        licz <= licz + 1'b1;
                        if (licz == PRZED_W - 1'b1) begin
                            stan <= S_CZEKA;
                            czekanie <= 16'd0;
                        end
                    end
                S_CZEKA:
                    if (bierz) begin
                        czekanie <= czekanie + 16'd1;
                        if (zbocze || (tryb_auto && czekanie == AUTO_W)) begin
                            poczatek  <= wp - PRZED_W;
                            wyzwolony <= zbocze;
                            licz      <= {AW{1'b0}};
                            stan      <= S_PO;
                        end
                    end
                S_PO:
                    if (bierz) begin
                        licz <= licz + 1'b1;
                        if (licz == PO_W - 1'b1) begin
                            bank_gotowy <= bank;
                            gotowy_t    <= ~gotowy_t;
                            stan        <= S_GOTOWE;
                        end
                    end
                default:                                    // S_GOTOWE: czekanie na potwierdzenie
                    if (s_potw[1] == gotowy_t) begin
                        bank <= ~bank;
                        licz <= {AW{1'b0}};
                        stan <= S_PRZED;
                    end
            endcase
        end
    end
endmodule

`default_nettype wire
