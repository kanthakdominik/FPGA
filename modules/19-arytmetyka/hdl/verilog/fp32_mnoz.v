// Mnożenie liczb zmiennoprzecinkowych IEEE 754 binary32 (19.05), potok 2 takty.
//   Zaokrąglenie do najbliższej, połówka do parzystej (tryb domyślny IEEE 754).
//   Liczby zdenormalizowane: na wejściu traktowane jak zero (DAZ), wynik poniżej najmniejszej liczby
//   normalnej zerowany ze znakiem (FTZ) — flaga niedomiar. Wynik za duży: nieskończoność, flaga nadmiar.
//   NaN na wejściu albo 0 × nieskończoność: kanoniczny NaN 0x7FC00000.
// Stopień 1: rozpakowanie, mnożenie mantys 24 × 24 (cztery bloki 18 × 18), suma wykładników.
// Stopień 2: normalizacja (przesunięcie o 0 albo 1 bit), zaokrąglenie, kontrola zakresu, spakowanie.
`default_nettype none

module fp32_mnoz (
    input  wire        clk,
    input  wire        in_valid,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg         out_valid = 1'b0,
    output reg  [31:0] p,
    output reg         nadmiar,
    output reg         niedomiar
);
    // ---- stopień 1
    wire        sa = a[31], sb = b[31];
    wire [7:0]  ea = a[30:23], eb = b[30:23];
    wire [22:0] fa = a[22:0],  fb = b[22:0];
    wire        zero_a = (ea == 8'd0), zero_b = (eb == 8'd0);
    wire        max_a  = (ea == 8'hFF), max_b = (eb == 8'hFF);
    wire        inf_a  = max_a && (fa == 23'd0), inf_b = max_b && (fb == 23'd0);
    wire        nan_a  = max_a && (fa != 23'd0), nan_b = max_b && (fb != 23'd0);

    reg         s1, nan1, inf1, zero1, v1 = 1'b0;
    reg  [47:0] m1;
    reg  [9:0]  e1;                                    // wykładnik ze znakiem, z obciążeniem 127

    always @(posedge clk) begin
        v1    <= in_valid;
        s1    <= sa ^ sb;
        nan1  <= nan_a || nan_b || (inf_a && zero_b) || (zero_a && inf_b);
        inf1  <= inf_a || inf_b;
        zero1 <= zero_a || zero_b;
        /* verilator lint_off WIDTHEXPAND */
        m1    <= {1'b1, fa} * {1'b1, fb};             // jedynka ukryta; zdenormalizowane i tak dają zero
        /* verilator lint_on WIDTHEXPAND */
        e1    <= {2'b00, ea} + {2'b00, eb} - 10'd127;
    end

    // ---- stopień 2
    wire        gora  = m1[47];                         // iloczyn w [2, 4): przesunięcie o bit w prawo
    wire [23:0] mant  = gora ? m1[47:24] : m1[46:23];
    wire        g     = gora ? m1[23] : m1[22];         // bit zaokrąglenia
    wire        st    = gora ? (|m1[22:0]) : (|m1[21:0]); // bit „sticky”: cokolwiek dalej
    wire        w_gore = g && (st || mant[0]);          // połówka do parzystej
    wire [24:0] mr    = {1'b0, mant} + {24'd0, w_gore};
    /* verilator lint_off UNUSEDSIGNAL */
    wire [23:0] mant2 = mr[24] ? mr[24:1] : mr[23:0];   // zaokrąglenie przeniesione do 2,0; bit 23 = ukryta 1
    /* verilator lint_on UNUSEDSIGNAL */
    wire [9:0]  e2    = e1 + {9'd0, gora} + {9'd0, mr[24]};
    wire        za_duzy = !e2[9] && (e2[8:0] >= 9'd255);
    wire        za_maly = e2[9] || (e2 == 10'd0);

    always @(posedge clk) begin
        out_valid <= v1;
        nadmiar   <= 1'b0;
        niedomiar <= 1'b0;
        if (nan1)
            p <= 32'h7FC00000;
        else if (inf1)
            p <= {s1, 8'hFF, 23'd0};
        else if (zero1)
            p <= {s1, 31'd0};
        else if (za_duzy) begin
            p       <= {s1, 8'hFF, 23'd0};
            nadmiar <= 1'b1;
        end else if (za_maly) begin
            p         <= {s1, 31'd0};
            niedomiar <= 1'b1;
        end else
            p <= {s1, e2[7:0], mant2[22:0]};
    end
endmodule

`default_nettype wire
