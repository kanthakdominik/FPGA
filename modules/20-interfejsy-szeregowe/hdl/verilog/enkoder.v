// Dekoder enkodera kwadraturowego (20.04): wejścia A, B przez synchronizator i filtr cyfrowy (stan musi
// być stały przez FILTR taktów — drgania styków i zakłócenia krótsze od filtra są ignorowane), potem
// dekodowanie ×4: każda zmiana A albo B to krok ±1 zależnie od kolejności (A wyprzedza B — w przód).
// Zmiana obu sygnałów naraz jest niedozwolona (zgubiony krok) — liczona w bledy.
`default_nettype none

module enkoder #(
    parameter W     = 16,
    parameter FILTR = 8
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         a,
    input  wire         b,
    output reg  [W-1:0] pozycja = {W{1'b0}},
    output reg          kierunek = 1'b0,          // 1 — w przód
    output reg  [7:0]   bledy = 8'd0
);
    localparam FW = $clog2(FILTR + 1);
    localparam [FW-1:0] F = FILTR;

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] s_a = 2'b00, s_b = 2'b00;
    always @(posedge clk) begin
        s_a <= {s_a[0], a};
        s_b <= {s_b[0], b};
    end

    // filtr: nowy stan {A, B} przyjmowany, gdy był stały przez FILTR taktów
    reg [1:0]    kandydat = 2'b00, stan = 2'b00, stan_d = 2'b00;
    reg [FW-1:0] stabil = {FW{1'b0}};
    always @(posedge clk) begin
        if ({s_a[1], s_b[1]} != kandydat) begin
            kandydat <= {s_a[1], s_b[1]};
            stabil   <= {FW{1'b0}};
        end else if (stabil != F) begin
            stabil <= stabil + 1'b1;
        end else
            stan <= kandydat;
        stan_d <= stan;
    end

    // dekodowanie ×4: kod Graya 00 -> 10 -> 11 -> 01 -> 00 (A wyprzedza B) = w przód
    wire [3:0] przejscie = {stan_d, stan};
    always @(posedge clk) begin
        if (rst) begin
            pozycja <= {W{1'b0}};
            bledy   <= 8'd0;
        end else case (przejscie)
            4'b0010, 4'b1011, 4'b1101, 4'b0100: begin pozycja <= pozycja + 1'b1; kierunek <= 1'b1; end
            4'b0001, 4'b0111, 4'b1110, 4'b1000: begin pozycja <= pozycja - 1'b1; kierunek <= 1'b0; end
            4'b0011, 4'b1100, 4'b0110, 4'b1001: if (bledy != 8'hFF) bledy <= bledy + 1'b1;
            default: ;                                 // bez zmiany
        endcase
    end
endmodule

`default_nettype wire
