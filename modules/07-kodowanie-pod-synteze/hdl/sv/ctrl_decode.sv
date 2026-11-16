// Dekoder sterowania bez zatrzasków: wartości domyślne na początku always_comb.
// op: 000 NOP, 001 READ, 010 WRITE, 011 RMW, 1xx — niedozwolony (err). Przy busy operacje czekają.
module ctrl_decode (
    input  logic [2:0] op,
    input  logic       valid,
    input  logic       busy,
    output logic       rd_en,
    output logic       wr_en,
    output logic [1:0] sel,
    output logic       err
);
    always_comb begin
        rd_en = 1'b0;                          // wartości domyślne: każde wyjście jest przypisane
        wr_en = 1'b0;                          // w każdej ścieżce przez blok
        sel   = 2'd0;
        err   = 1'b0;
        if (valid) begin
            case (op) inside
                3'b001:  if (!busy) begin rd_en = 1'b1; sel = 2'd1; end
                3'b010:  if (!busy) begin wr_en = 1'b1; sel = 2'd2; end
                3'b011:  if (!busy) begin rd_en = 1'b1; wr_en = 1'b1; sel = 2'd3; end
                3'b1??:  err = 1'b1;
                default: ;                     // 000: NOP
            endcase
        end
    end
endmodule
