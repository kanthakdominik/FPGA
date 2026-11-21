// Plik wygenerowany przez model/dsp_model.py — nie edytować ręcznie.
// Współczynniki obrotu FFT 64 (26.05): W_k = cos(2πk/64) - j·sin(2πk/64), k = 0..31, Q1.15 (32767).
`default_nettype none

module tw_tab (
    input  wire  [4:0]  k,
    output reg  [15:0] wr,
    output reg  [15:0] wi
);
    always @(*)
        case (k)
            5'd0: begin wr = 16'h7FFF; wi = 16'h0000; end
            5'd1: begin wr = 16'h7F61; wi = 16'hF374; end
            5'd2: begin wr = 16'h7D89; wi = 16'hE707; end
            5'd3: begin wr = 16'h7A7C; wi = 16'hDAD8; end
            5'd4: begin wr = 16'h7641; wi = 16'hCF05; end
            5'd5: begin wr = 16'h70E2; wi = 16'hC3AA; end
            5'd6: begin wr = 16'h6A6D; wi = 16'hB8E4; end
            5'd7: begin wr = 16'h62F1; wi = 16'hAECD; end
            5'd8: begin wr = 16'h5A82; wi = 16'hA57E; end
            5'd9: begin wr = 16'h5133; wi = 16'h9D0F; end
            5'd10: begin wr = 16'h471C; wi = 16'h9593; end
            5'd11: begin wr = 16'h3C56; wi = 16'h8F1E; end
            5'd12: begin wr = 16'h30FB; wi = 16'h89BF; end
            5'd13: begin wr = 16'h2528; wi = 16'h8584; end
            5'd14: begin wr = 16'h18F9; wi = 16'h8277; end
            5'd15: begin wr = 16'h0C8C; wi = 16'h809F; end
            5'd16: begin wr = 16'h0000; wi = 16'h8001; end
            5'd17: begin wr = 16'hF374; wi = 16'h809F; end
            5'd18: begin wr = 16'hE707; wi = 16'h8277; end
            5'd19: begin wr = 16'hDAD8; wi = 16'h8584; end
            5'd20: begin wr = 16'hCF05; wi = 16'h89BF; end
            5'd21: begin wr = 16'hC3AA; wi = 16'h8F1E; end
            5'd22: begin wr = 16'hB8E4; wi = 16'h9593; end
            5'd23: begin wr = 16'hAECD; wi = 16'h9D0F; end
            5'd24: begin wr = 16'hA57E; wi = 16'hA57E; end
            5'd25: begin wr = 16'h9D0F; wi = 16'hAECD; end
            5'd26: begin wr = 16'h9593; wi = 16'hB8E4; end
            5'd27: begin wr = 16'h8F1E; wi = 16'hC3AA; end
            5'd28: begin wr = 16'h89BF; wi = 16'hCF05; end
            5'd29: begin wr = 16'h8584; wi = 16'hDAD8; end
            5'd30: begin wr = 16'h8277; wi = 16'hE707; end
            5'd31: begin wr = 16'h809F; wi = 16'hF374; end
            default: begin wr = 16'h0000; wi = 16'h0000; end
        endcase
endmodule

`default_nettype wire
