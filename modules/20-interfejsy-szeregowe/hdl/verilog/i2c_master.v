// I²C master z interfejsem rozkazów (20.03): START (także powtórzony), STOP, ZAPIS bajtu z odczytem ACK,
// ODCZYT bajtu z wysłaniem ACK/NACK. Linie open-drain: wyjścia *_oe = 1 ściągają linię do zera,
// 0 — zwalniają (jedynkę daje rezystor podciągający). Wejścia scl_i, sda_i przez synchronizatory.
// Bit trwa 4 fazy po DIV taktów (SCL = f_clk / (4·DIV)): dwie z SCL niskim (zmiana SDA w połowie stanu
// niskiego, z dala od zboczy SCL), dwie z SCL wysokim (próbkowanie SDA na końcu trzeciej). Rozciąganie zegara: po zwolnieniu SCL master
// czeka, aż linia rzeczywiście będzie wysoka, i dopiero wtedy odmierza czas stanu wysokiego.
// Arbitraż: master nadający 1, który odczyta 0, przegrywa — zwalnia linie i zgłasza utrata.
`default_nettype none

module i2c_master #(
    parameter DIV = 125                       // 50 MHz / (4·125) = 100 kHz
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] rozkaz,                 // 1 START, 2 STOP, 3 ZAPIS, 4 ODCZYT
    input  wire       wykonaj,                // przy gotowy = 1
    input  wire [7:0] wdane,
    input  wire       nack_wy,                // ODCZYT: 1 — wyślij NACK (ostatni bajt)
    output wire       gotowy,
    output reg        wykonane = 1'b0,        // impuls po zakończeniu rozkazu
    output reg  [7:0] rdane,
    output reg        nack_we,                // ZAPIS: 1 — slave nie potwierdził
    output reg        utrata = 1'b0,          // przegrany arbitraż (lepkie do rst)
    input  wire       scl_i,
    output reg        scl_oe = 1'b0,
    input  wire       sda_i,
    output reg        sda_oe = 1'b0
);
    localparam K_START = 3'd1, K_STOP = 3'd2, K_ZAPIS = 3'd3, K_ODCZYT = 3'd4;
    localparam CW = $clog2(DIV + 1);
    localparam [CW-1:0] DIV_1 = DIV - 1;

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] s_scl = 2'b11, s_sda = 2'b11;
    always @(posedge clk) begin
        s_scl <= {s_scl[0], scl_i};
        s_sda <= {s_sda[0], sda_i};
    end
    wire scl = s_scl[1];
    wire sda = s_sda[1];

    reg [2:0]    kom = 3'd0;                  // wykonywany rozkaz (0 — brak)
    reg [1:0]    faza;
    reg [CW-1:0] t;
    reg          czeka_scl;                   // faza 2: czekanie na wysoki SCL (rozciąganie)
    reg [3:0]    nbit;
    reg [7:0]    sr;
    reg          nack_r;

    assign gotowy = (kom == 3'd0);

    // stan SDA w bicie nbit rozkazu ZAPIS/ODCZYT: 1 — zwolnij
    wire bit_wy = (kom == K_ZAPIS)  ? ((nbit == 4'd8) ? 1'b1 : sr[7]) :
                                      ((nbit == 4'd8) ? nack_r : 1'b1);

    always @(posedge clk) begin
        wykonane <= 1'b0;
        if (rst) begin
            kom    <= 3'd0;
            scl_oe <= 1'b0;
            sda_oe <= 1'b0;
            utrata <= 1'b0;
        end else if (kom == 3'd0) begin
            if (wykonaj && rozkaz != 3'd0) begin
                kom       <= rozkaz;
                faza      <= 2'd0;
                t         <= DIV_1;
                czeka_scl <= 1'b0;
                nbit      <= 4'd0;
                sr        <= wdane;
                nack_r    <= nack_wy;
                // START zwalnia SDA, STOP ściąga SDA (SCL jest niski); bajt ustawi SDA pod koniec fazy 0
                if (rozkaz == K_START)      sda_oe <= 1'b0;
                else if (rozkaz == K_STOP)  sda_oe <= 1'b1;
            end
        end else if (czeka_scl) begin
            if (scl) czeka_scl <= 1'b0;           // SCL naprawdę wysoki — od teraz liczy się czas
        end else if (t != 0) begin
            t <= t - 1'b1;
        end else begin
            t    <= DIV_1;
            faza <= faza + 1'b1;
            case (faza)
                2'd0: if (kom == K_START || kom == K_STOP) begin   // START/STOP: zwolnij SCL
                          scl_oe    <= 1'b0;
                          czeka_scl <= 1'b1;
                      end else
                          sda_oe <= !bit_wy;                        // bit: zmiana SDA w środku stanu niskiego SCL
                2'd1: if (kom == K_START)      sda_oe <= 1'b1;      // warunek START: SDA w dół przy wysokim SCL
                      else if (kom == K_STOP)  sda_oe <= 1'b0;      // warunek STOP: SDA w górę przy wysokim SCL
                      else begin
                          scl_oe    <= 1'b0;                        // bit: zwolnij SCL
                          czeka_scl <= 1'b1;
                      end
                2'd2: if (kom == K_START) scl_oe <= 1'b1;           // START: SCL w dół — magistrala zajęta
                      else if (kom == K_ZAPIS || kom == K_ODCZYT) begin
                          // próbkowanie w środku stanu wysokiego SCL
                          if (nbit == 4'd8) begin
                              if (kom == K_ZAPIS) nack_we <= sda;
                          end else begin
                              if (kom == K_ODCZYT) sr <= {sr[6:0], sda};
                              if (kom == K_ZAPIS && sda_oe == 1'b0 && !sda) begin
                                  utrata   <= 1'b1;                 // nadawaliśmy 1, a na linii 0
                                  scl_oe   <= 1'b0;
                                  sda_oe   <= 1'b0;
                                  kom      <= 3'd0;
                                  wykonane <= 1'b1;
                              end
                          end
                      end
                default: begin                                      // faza 3: koniec rozkazu albo bitu
                    if (kom == K_START || kom == K_STOP) begin
                        kom      <= 3'd0;
                        wykonane <= 1'b1;
                    end else begin
                        scl_oe <= 1'b1;                             // SCL w dół
                        if (nbit == 4'd8) begin
                            if (kom == K_ODCZYT) rdane <= sr;
                            kom      <= 3'd0;                       // SCL trzymany nisko do następnego rozkazu
                            wykonane <= 1'b1;
                        end else begin
                            nbit <= nbit + 1'b1;
                            if (kom == K_ZAPIS) sr <= {sr[6:0], 1'b0};
                        end
                    end
                end
            endcase
        end
    end

endmodule

`default_nettype wire
