// Interpreter komend tekstowych z UART (31.01). Litery bez rozróżniania wielkości, odpowiedź zakończona CR LF:
//   ?        -> hh:mm:ss        bieżący czas
//   Thhmmss  -> OK | ERR        ustawienie zegara (sprawdzane zakresy: hh 00–23, mm i ss 00–59)
//   S, P, R  -> OK              stoper: start, pauza, zerowanie
//   L        -> L mm:ss.cc      okrążenie (zapamiętuje i wysyła bieżący stan stopera)
//   W        -> mm:ss.cc        stan stopera
//   inne     -> ERR             (spacja, CR i LF są pomijane)
// Odpowiedź do 12 znaków czeka w rejestrze przesuwnym i wychodzi bajt po bajcie przez uart_tx. Komenda, która
// przyjdzie w czasie wysyłania, jest wykonywana, ale jej odpowiedź przepada — ustawia lepką flagę pominieto.
`default_nettype none

module komendy (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  rx_dane,
    input  wire        rx_wazne,
    input  wire [23:0] czas,
    input  wire [23:0] stoper,
    output reg         ustaw = 1'b0,
    output reg  [23:0] ustaw_czas = 24'h000000,
    output reg         st_start = 1'b0,
    output reg         st_stop = 1'b0,
    output reg         st_zeruj = 1'b0,
    output reg         st_okr = 1'b0,
    output reg         tx_start = 1'b0,
    output reg  [7:0]  tx_dane = 8'h00,
    input  wire        tx_gotowy,
    output reg         pominieto = 1'b0
);
    localparam [7:0] CR = 8'h0D, LF = 8'h0A;

    function [7:0] znak(input [3:0] c);
        znak = {4'h3, c};
    endfunction

    // odpowiedź: do 12 znaków, najstarszy bajt wychodzi pierwszy
    reg [95:0] bufor = 96'd0;
    reg [3:0]  ile = 4'd0;
    reg        czekaj = 1'b0;                     // takt po start: gotowy jeszcze nie spadło

    reg        w_cyfrach = 1'b0;
    reg [2:0]  nc = 3'd0;
    reg [19:0] cyfry = 20'h00000;

    wire [7:0] duza = (rx_dane >= "a" && rx_dane <= "z") ? (rx_dane & 8'hDF) : rx_dane;
    wire       cyfra = (rx_dane >= "0" && rx_dane <= "9");
    wire [23:0] nowe = {cyfry[19:0], rx_dane[3:0]};
    wire       zakres_ok = (nowe[23:20] < 4'd2 || (nowe[23:20] == 4'd2 && nowe[19:16] <= 4'd3)) &&
                           nowe[15:12] <= 4'd5 && nowe[7:4] <= 4'd5;

    task odpowiedz(input [95:0] tekst, input [3:0] n);
        begin
            if (ile != 4'd0) pominieto <= 1'b1;
            else begin
                bufor <= tekst;
                ile   <= n;
            end
        end
    endtask

    localparam [95:0] T_OK  = {"OK", CR, LF, 64'd0};
    localparam [95:0] T_ERR = {"ERR", CR, LF, 56'd0};

    always @(posedge clk) begin
        ustaw <= 1'b0; st_start <= 1'b0; st_stop <= 1'b0; st_zeruj <= 1'b0; st_okr <= 1'b0;
        tx_start <= 1'b0;
        if (rst) begin
            ile <= 4'd0; czekaj <= 1'b0; w_cyfrach <= 1'b0; nc <= 3'd0; pominieto <= 1'b0;
        end else begin
            // wysyłanie
            czekaj <= tx_start;
            if (ile != 4'd0 && tx_gotowy && !tx_start && !czekaj) begin
                tx_dane  <= bufor[95:88];
                tx_start <= 1'b1;
                bufor    <= {bufor[87:0], 8'd0};
                ile      <= ile - 4'd1;
            end
            // odbiór
            if (rx_wazne) begin
                if (w_cyfrach) begin
                    if (!cyfra) begin
                        w_cyfrach <= 1'b0;
                        odpowiedz(T_ERR, 4'd5);
                    end else begin
                        cyfry <= nowe[19:0];
                        nc    <= nc + 3'd1;
                        if (nc == 3'd5) begin
                            w_cyfrach <= 1'b0;
                            if (zakres_ok) begin
                                ustaw      <= 1'b1;
                                ustaw_czas <= nowe;
                                odpowiedz(T_OK, 4'd4);
                            end else
                                odpowiedz(T_ERR, 4'd5);
                        end
                    end
                end else case (duza)
                    "T": begin w_cyfrach <= 1'b1; nc <= 3'd0; end
                    "?": odpowiedz({znak(czas[23:20]), znak(czas[19:16]), ":", znak(czas[15:12]),
                                    znak(czas[11:8]), ":", znak(czas[7:4]), znak(czas[3:0]), CR, LF, 16'd0}, 4'd10);
                    "S": begin st_start <= 1'b1; odpowiedz(T_OK, 4'd4); end
                    "P": begin st_stop  <= 1'b1; odpowiedz(T_OK, 4'd4); end
                    "R": begin st_zeruj <= 1'b1; odpowiedz(T_OK, 4'd4); end
                    "L": begin
                        st_okr <= 1'b1;
                        odpowiedz({"L ", znak(stoper[23:20]), znak(stoper[19:16]), ":", znak(stoper[15:12]),
                                   znak(stoper[11:8]), ".", znak(stoper[7:4]), znak(stoper[3:0]), CR, LF}, 4'd12);
                    end
                    "W": odpowiedz({znak(stoper[23:20]), znak(stoper[19:16]), ":", znak(stoper[15:12]),
                                    znak(stoper[11:8]), ".", znak(stoper[7:4]), znak(stoper[3:0]), CR, LF, 16'd0},
                                   4'd10);
                    " ", CR, LF: ;
                    default: odpowiedz(T_ERR, 4'd5);
                endcase
            end
        end
    end
endmodule

`default_nettype wire
