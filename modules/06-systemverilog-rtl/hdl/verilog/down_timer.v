// Timer odliczający w dół z automatycznym przeładowaniem — styl dwóch bloków w Verilogu-2001.
`default_nettype none

module down_timer #(
    parameter integer W = 16
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         en,
    input  wire         load,
    input  wire [W-1:0] period,
    output reg  [W-1:0] count,
    output reg          tick
);
    reg [W-1:0] count_next;
    reg         tick_next;

    always @* begin
        count_next = count;
        tick_next  = 1'b0;
        if (load)
            count_next = period;
        else if (en) begin
            if (count == {W{1'b0}}) begin
                count_next = period;
                tick_next  = 1'b1;
            end else
                count_next = count - 1'b1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            count <= {W{1'b0}};
            tick  <= 1'b0;
        end else begin
            count <= count_next;
            tick  <= tick_next;
        end
    end
endmodule

`default_nettype wire
