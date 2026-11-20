// Rejestr wyjściowy DDR — model behawioralny (22.02): dane d_h i d_l pobrane zboczem narastającym,
// na wyjściu d_h w stanie wysokim zegara i d_l w stanie niskim (dwa bity na okres).
// W układzie to blok I/O (MAX 10: ALTDDIO_OUT / GPIO Lite, AMD: ODDR, Lattice: ODDRX1F) — multiplekser
// sterowany zegarem w logice dawałby szpilki i niekontrolowany przekos; ten model służy symulacji.
`default_nettype none

module ddr_wyj (
    input  logic clk,
    input  logic d_h,                          // bit w połowie wysokiej (pierwszy)
    input  logic d_l,                          // bit w połowie niskiej (drugi)
    output logic q
);
    logic h = 1'b0, l = 1'b0, l_n = 1'b0;
    always_ff @(posedge clk) begin
        h <= d_h;
        l <= d_l;
    end
    always @(negedge clk) l_n <= l;           // bit drugi przejmuje wyjście przy zboczu opadającym
    assign q = clk ? h : l_n;
endmodule

`default_nettype wire
