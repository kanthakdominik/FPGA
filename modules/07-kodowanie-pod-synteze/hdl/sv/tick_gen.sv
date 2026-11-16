// Generator impulsów zezwolenia: tick = 1 przez jeden takt co DIV taktów zegara. Zamiast dzielenia zegara.
module tick_gen #(
    parameter int DIV = 10                     // okres w taktach, co najmniej 2
) (
    input  logic clk,
    input  logic rst,
    output logic tick = 1'b0
);
    localparam int CW = $clog2(DIV);
    localparam logic [CW-1:0] LAST = CW'(DIV - 1);

    logic [CW-1:0] cnt = '0;

    always_ff @(posedge clk) begin
        if (rst) begin
            cnt  <= '0;
            tick <= 1'b0;
        end else begin
            tick <= (cnt == LAST);
            cnt  <= (cnt == LAST) ? '0 : cnt + CW'(1);
        end
    end
endmodule
