// Licznik kredytów kontroli przepływu. Verilog-2005 nie ma asercji — sprawdzenia w bloku
// wyłączonym z syntezy (makro SYNTHESIS w Yosysie, pragmy translate_off/on w Quartusie).
`default_nettype none

module credit_counter #(
    parameter integer MAX = 8
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     take,
    input  wire                     give,
    output reg  [$clog2(MAX+1)-1:0] credits,
    output wire                     can_take
);
    assign can_take = (credits != 0);

    always @(posedge clk) begin
        if (rst)
            credits <= MAX;
        else if (take && !give)
            credits <= credits - 1'b1;
        else if (give && !take)
            credits <= credits + 1'b1;
    end

`ifndef SYNTHESIS
    // synthesis translate_off
    always @(posedge clk) begin
        if (!rst && take && credits == 0)
            $display("ASERCJA credit_counter: take bez dostepnego kredytu (t=%0t)", $time);
        if (!rst && give && !take && credits == MAX)
            $display("ASERCJA credit_counter: give ponad MAX (t=%0t)", $time);
    end
    // synthesis translate_on
`endif
endmodule

`default_nettype wire
