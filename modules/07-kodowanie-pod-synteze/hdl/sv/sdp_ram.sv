// Pamięć RAM prosta dwuportowa (jeden port zapisu, jeden odczytu), jeden zegar, odczyt synchroniczny.
// Odczyt spod adresu zapisywanego w tym samym takcie daje stare dane (przypisania nieblokujące).
module sdp_ram #(
    parameter int W  = 8,
    parameter int AW = 5                       // 2**AW słów
) (
    input  logic          clk,
    input  logic          we,
    input  logic [AW-1:0] waddr,
    input  logic [W-1:0]  wdata,
    input  logic [AW-1:0] raddr,
    output logic [W-1:0]  rdata
);
    logic [W-1:0] mem [2**AW];

    always_ff @(posedge clk) begin
        if (we)
            mem[waddr] <= wdata;
        rdata <= mem[raddr];                   // rejestr na wyjściu — warunek użycia bloku M9K
    end
endmodule
