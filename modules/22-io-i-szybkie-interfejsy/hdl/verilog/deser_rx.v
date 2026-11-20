// Deserializator 1:N z przesunięciem granicy słowa (bitslip) (22.03): bity wsuwane co takt zegara bitowego,
// słowo co N taktów; impuls bitslip opóźnia granicę słowa o jeden bit (licznik pomija jeden krok).
`default_nettype none

module deser_rx #(
    parameter integer N = 8
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         d,
    input  wire         bitslip,
    output reg  [N-1:0] slowo,
    output reg          wazne
);
    localparam integer CW = $clog2(N);
    /* verilator lint_off WIDTHTRUNC */
    localparam [CW-1:0] OST = N - 1;
    /* verilator lint_on WIDTHTRUNC */
    /* verilator lint_off UNUSEDSIGNAL */
    reg [N-1:0]  sr;                              // najstarszy bit wypada (słowo bierze bity N-2:0 i d)
    /* verilator lint_on UNUSEDSIGNAL */
    reg [CW-1:0] licz;
    reg          wstrzymaj;

    always @(posedge clk) begin
        wazne <= 1'b0;
        if (rst) begin
            licz      <= {CW{1'b0}};
            wstrzymaj <= 1'b0;
        end else begin
            sr <= {sr[N-2:0], d};
            if (bitslip) wstrzymaj <= 1'b1;
            if (wstrzymaj) begin
                wstrzymaj <= 1'b0;                     // jeden krok licznika pominięty: granica o bit dalej
            end else begin
                licz <= (licz == OST) ? {CW{1'b0}} : licz + 1'b1;
                if (licz == OST) begin
                    slowo <= {sr[N-2:0], d};
                    wazne <= 1'b1;
                end
            end
        end
    end
endmodule

`default_nettype wire
