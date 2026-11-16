// Dekoder sterowania bez zatrzasków: wartości domyślne na początku bloku kombinacyjnego.
// op: 000 NOP, 001 READ, 010 WRITE, 011 RMW, 1xx — niedozwolony (err). Przy busy operacje czekają.
`default_nettype none

module ctrl_decode (
    input  wire [2:0] op,
    input  wire       valid,
    input  wire       busy,
    output reg        rd_en,
    output reg        wr_en,
    output reg  [1:0] sel,
    output reg        err
);
    always @* begin
        rd_en = 1'b0;                          // wartości domyślne: każde wyjście jest przypisane
        wr_en = 1'b0;                          // w każdej ścieżce przez blok
        sel   = 2'd0;
        err   = 1'b0;
        if (valid) begin
            case (op)
                3'b001: if (!busy) begin rd_en = 1'b1; sel = 2'd1; end
                3'b010: if (!busy) begin wr_en = 1'b1; sel = 2'd2; end
                3'b011: if (!busy) begin rd_en = 1'b1; wr_en = 1'b1; sel = 2'd3; end
                3'b100, 3'b101, 3'b110, 3'b111: err = 1'b1;
                default: ;                     // 000: NOP
            endcase
        end
    end
endmodule

`default_nettype wire
