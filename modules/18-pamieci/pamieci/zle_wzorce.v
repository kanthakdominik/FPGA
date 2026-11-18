// Wzorce, które NIE dają bloku pamięci (18.01) — dla porównania z ram_sp i ram_sdp w eksperymencie
// wnioskowanie.py. Funkcja jak w pamięci 256 × 8, inna struktura sprzętu.
`default_nettype none

// 1. Odczyt asynchroniczny: bloki RAM w FPGA mają odczyt synchroniczny (rejestr na wyjściu lub adresie),
//    więc synteza buduje pamięć rozproszoną w LUT (ECP5: TRELLIS_DPR16X4; MAX 10: logika w LE).
module ram_odczyt_async (
    input  wire       clk,
    input  wire       we,
    input  wire [7:0] addr,
    input  wire [7:0] din,
    output wire [7:0] dout
);
    reg [7:0] mem [0:255];
    always @(posedge clk) if (we) mem[addr] <= din;
    assign dout = mem[addr];
endmodule

// 2. Reset całej zawartości: blok RAM nie umie wyzerować wszystkich słów naraz, więc pamięć zamienia się
//    w 2048 przerzutników z multiplekserami.
module ram_z_resetem (
    input  wire       clk,
    input  wire       rst,
    input  wire       we,
    input  wire [7:0] addr,
    input  wire [7:0] din,
    output reg  [7:0] dout
);
    reg [7:0] mem [0:255];
    integer i;
    always @(posedge clk)
        if (rst) begin
            for (i = 0; i < 256; i = i + 1) mem[i] <= 8'd0;
        end else begin
            if (we) mem[addr] <= din;
            dout <= mem[addr];
        end
endmodule

// 3. Trzy porty odczytu i jeden zapisu w jednym takcie: blok RAM ma najwyżej dwa porty, więc synteza
//    powiela pamięć (każda kopia z tym samym zapisem) albo buduje ją z przerzutników.
module ram_trzy_odczyty (
    input  wire       clk,
    input  wire       we,
    input  wire [7:0] aw,
    input  wire [7:0] din,
    input  wire [7:0] a1,
    input  wire [7:0] a2,
    input  wire [7:0] a3,
    output reg  [7:0] d1,
    output reg  [7:0] d2,
    output reg  [7:0] d3
);
    reg [7:0] mem [0:255];
    always @(posedge clk) begin
        if (we) mem[aw] <= din;
        d1 <= mem[a1];
        d2 <= mem[a2];
        d3 <= mem[a3];
    end
endmodule

`default_nettype wire
