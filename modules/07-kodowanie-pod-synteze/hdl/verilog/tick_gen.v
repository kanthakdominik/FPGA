// Generator impulsów zezwolenia: tick = 1 przez jeden takt co DIV taktów zegara. Zamiast dzielenia zegara.
`default_nettype none

module tick_gen #(
    parameter DIV = 10                         // okres w taktach, co najmniej 2
) (
    input  wire clk,
    input  wire rst,
    output reg  tick = 1'b0
);
    localparam CW = $clog2(DIV);
    localparam [CW-1:0] LAST = DIV - 1;
    localparam [CW-1:0] ONE  = 1;

    reg [CW-1:0] cnt = {CW{1'b0}};

    always @(posedge clk) begin
        if (rst) begin
            cnt  <= {CW{1'b0}};
            tick <= 1'b0;
        end else begin
            tick <= (cnt == LAST);
            cnt  <= (cnt == LAST) ? {CW{1'b0}} : cnt + ONE;
        end
    end
endmodule

`default_nettype wire
