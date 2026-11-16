// Arbiter karuzelowy dla 4 zgłoszeń — Verilog: casez zamiast unique case.
`default_nettype none

module rr_arbiter (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] req,
    output reg  [3:0] grant,
    output reg  [1:0] grant_idx,
    output wire       grant_valid
);
    reg [1:0] last = 2'd3;
    integer   k;
    reg [1:0] idx;

    always @* begin
        grant = 4'b0000;
        for (k = 1; k <= 4; k = k + 1) begin
            idx = last + k;                        // 2 bity: dodawanie modulo 4
            if (req[idx] && grant == 4'b0000)
                grant[idx] = 1'b1;
        end
    end

    assign grant_valid = |grant;

    always @* begin
        casez (grant)                              // grant jest w kodzie 1 z n albo zerem
            4'b???1: grant_idx = 2'd0;
            4'b??10: grant_idx = 2'd1;
            4'b?100: grant_idx = 2'd2;
            4'b1000: grant_idx = 2'd3;
            default: grant_idx = 2'd0;
        endcase
    end

    always @(posedge clk) begin
        if (rst)              last <= 2'd3;
        else if (grant_valid) last <= grant_idx;
    end
endmodule

`default_nettype wire
