// Zadanie 3: dzielnik zegara przez 3 z wypełnieniem 50 %. Licznik 0, 1, 2 na zboczu narastającym daje p — stan
// wysoki przez 1 okres z 3. Przerzutnik na zboczu opadającym opóźnia p o pół okresu (n). Suma p | n trwa
// 1,5 okresu z 3. Wyjście to bramka OR dwóch przerzutników — w FPGA nie używaj go jako zegara logiki
// (do tego PLL albo sygnał zezwolenia), co najwyżej wyprowadź na pin.
`default_nettype none

module clk_div3 (
    input  logic clk,
    input  logic rst,
    output logic clk_out
);
    logic [1:0] cnt = 2'd0;
    logic       p = 1'b0;
    logic       n = 1'b0;

    always_ff @(posedge clk)
        if (rst) begin
            cnt <= 2'd0;
            p   <= 1'b0;
        end else begin
            cnt <= (cnt == 2'd2) ? 2'd0 : cnt + 2'd1;
            p   <= (cnt == 2'd2);
        end

    always_ff @(negedge clk)
        if (rst) n <= 1'b0;
        else     n <= p;

    assign clk_out = p | n;
endmodule

`default_nettype wire
