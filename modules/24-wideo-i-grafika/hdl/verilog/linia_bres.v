// Rysowanie odcinka algorytmem Bresenhama (24.03), wersja ogólna (wszystkie oktanty) z błędem
// e = dx + dy (dy ujemne): jeden punkt na takt, tylko dodawania i porównania. Współrzędne 0..4095.
// start (przy gotowy = 1) przyjmuje końce (x0, y0) -> (x1, y1); punkty wychodzą na (px, py) z pwazny;
// dalej = 0 wstrzymuje generowanie (odbiorca zajęty). koniec — razem z ostatnim punktem.
`default_nettype none

module linia_bres (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [11:0] x0,
    input  wire [11:0] y0,
    input  wire [11:0] x1,
    input  wire [11:0] y1,
    input  wire        dalej,
    output reg         gotowy,
    output reg  [11:0] px,
    output reg  [11:0] py,
    output reg         pwazny,
    output reg         koniec
);
    reg  signed [13:0] dx, dy, e;                   // dx ≥ 0, dy ≤ 0
    reg         [11:0] xk, yk;
    reg                sx, sy;                      // 1: krok ujemny
    reg                praca;

    // następny punkt i błąd (kombinacyjnie z bieżącego stanu)
    wire signed [13:0] e2   = e + e;
    wire               krok_x = (e2 >= dy);
    wire               krok_y = (e2 <= dx);
    wire        [11:0] nx = krok_x ? (sx ? px - 1'b1 : px + 1'b1) : px;
    wire        [11:0] ny = krok_y ? (sy ? py - 1'b1 : py + 1'b1) : py;
    wire signed [13:0] ne = e + (krok_x ? dy : 14'sd0) + (krok_y ? dx : 14'sd0);
    wire               ost = (px == xk) && (py == yk);

    always @(posedge clk) begin
        if (rst) begin
            gotowy <= 1'b1;
            praca  <= 1'b0;
            pwazny <= 1'b0;
            koniec <= 1'b0;
            px <= 12'd0; py <= 12'd0; xk <= 12'd0; yk <= 12'd0;
            dx <= 14'sd0; dy <= 14'sd0; e <= 14'sd0; sx <= 1'b0; sy <= 1'b0;
        end else if (!praca) begin
            pwazny <= 1'b0;
            koniec <= 1'b0;
            if (start) begin
                px <= x0; py <= y0; xk <= x1; yk <= y1;
                sx <= (x1 < x0);
                sy <= (y1 < y0);
                dx <= (x1 >= x0) ? $signed({2'b00, x1 - x0}) : $signed({2'b00, x0 - x1});
                dy <= (y1 >= y0) ? -$signed({2'b00, y1 - y0}) : -$signed({2'b00, y0 - y1});
                e  <= ((x1 >= x0) ? $signed({2'b00, x1 - x0}) : $signed({2'b00, x0 - x1}))
                    - ((y1 >= y0) ? $signed({2'b00, y1 - y0}) : $signed({2'b00, y0 - y1}));
                praca  <= 1'b1;
                gotowy <= 1'b0;
                pwazny <= 1'b1;                     // pierwszy punkt: (x0, y0)
                koniec <= (x0 == x1) && (y0 == y1);
            end
        end else if (dalej) begin
            if (ost) begin                          // ostatni punkt właśnie przyjęty
                praca  <= 1'b0;
                gotowy <= 1'b1;
                pwazny <= 1'b0;
                koniec <= 1'b0;
            end else begin
                px <= nx; py <= ny; e <= ne;
                pwazny <= 1'b1;
                koniec <= (nx == xk) && (ny == yk);
            end
        end
    end
endmodule

`default_nettype wire
