// Rejestr wejściowy DDR — model behawioralny (22.02): bit próbkowany zboczem narastającym (pierwszy)
// i opadającym (drugi), oba wyprowadzone razem przy następnym zboczu narastającym.
// W układzie: ALTDDIO_IN (MAX 10), IDDR (AMD), IDDRX1F (Lattice).
`default_nettype none

module ddr_wej (
    input  wire clk,
    input  wire d,
    output reg  q_h = 1'b0,                   // bit spróbkowany zboczem narastającym
    output reg  q_l = 1'b0                    // bit spróbkowany następnym zboczem opadającym
);
    reg r = 1'b0, f = 1'b0;
    always @(posedge clk) r <= d;
    always @(negedge clk) f <= d;
    always @(posedge clk) begin
        q_h <= r;
        q_l <= f;
    end
endmodule

`default_nettype wire
