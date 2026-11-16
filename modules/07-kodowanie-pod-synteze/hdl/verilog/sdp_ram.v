// Pamięć RAM prosta dwuportowa (jeden port zapisu, jeden odczytu), jeden zegar, odczyt synchroniczny.
// Odczyt spod adresu zapisywanego w tym samym takcie daje stare dane (przypisania nieblokujące).
`default_nettype none

module sdp_ram #(
    parameter W  = 8,
    parameter AW = 5                           // 2**AW słów
) (
    input  wire          clk,
    input  wire          we,
    input  wire [AW-1:0] waddr,
    input  wire [W-1:0]  wdata,
    input  wire [AW-1:0] raddr,
    output reg  [W-1:0]  rdata
);
    reg [W-1:0] mem [0:(1<<AW)-1];

    always @(posedge clk) begin
        if (we)
            mem[waddr] <= wdata;
        rdata <= mem[raddr];                   // rejestr na wyjściu — warunek użycia bloku M9K
    end
endmodule

`default_nettype wire
