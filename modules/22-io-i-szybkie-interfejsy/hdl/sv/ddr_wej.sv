// Rejestr wejściowy DDR — model behawioralny (22.02): bit próbkowany zboczem narastającym (pierwszy)
// i opadającym (drugi), oba wyprowadzone razem przy następnym zboczu narastającym.
// W układzie: ALTDDIO_IN (MAX 10), IDDR (AMD), IDDRX1F (Lattice).
`default_nettype none

module ddr_wej (
    input  logic clk,
    input  logic d,
    output logic  q_h = 1'b0,                   // bit spróbkowany zboczem narastającym
    output logic  q_l = 1'b0                    // bit spróbkowany następnym zboczem opadającym
);
    logic r = 1'b0, f = 1'b0;
    always_ff @(posedge clk) r <= d;
    always @(negedge clk) f <= d;
    always_ff @(posedge clk) begin
        q_h <= r;
        q_l <= f;
    end
endmodule

`default_nettype wire
