// Arbiter round-robin N masterów do jednego slave'a Avalon-MM (23.04): przydział po każdym przyjętym
// transferze, zaczynając od mastera za ostatnio obsłużonym; odczyty potokowe — kolejka numerów masterów
// kieruje readdatavalid do właściwego mastera (odpowiedzi slave'a w kolejności rozkazów).
`default_nettype none

module arbiter_rr #(
    parameter integer N  = 3,
    parameter integer AW = 12,
    parameter integer KOL = 8                     // maks. odczytów w toku
) (
    input  logic            clk,
    input  logic            rst,
    // mastery (spakowane)
    input  logic [N*AW-1:0] m_adr,
    input  logic [N-1:0]    m_read,
    input  logic [N-1:0]    m_write,
    input  logic [N*32-1:0] m_wdata,
    output logic  [N-1:0]    m_wait,
    output logic [N-1:0]    m_rvalid,
    output logic [31:0]     m_rdata,
    // slave
    output logic [AW-1:0]   s_adr,
    output logic            s_read,
    output logic            s_write,
    output logic [31:0]     s_wdata,
    input  logic            s_wait,
    input  logic            s_rvalid,
    input  logic [31:0]     s_rdata
);
    localparam integer IW = (N > 1) ? $clog2(N) : 1;
    localparam integer KW = $clog2(KOL);

    logic  [IW-1:0] ost, wyb;
    logic           znal;
    logic  [IW-1:0] kol [0:KOL-1];
    logic  [KW-1:0] wz, wo;
    logic  [KW:0]   ile;
    logic          pelna;
    assign pelna = (ile == KOL);
    /* verilator lint_off UNUSEDSIGNAL */  // i < N — używane tylko młodsze bity
    integer       k, i;
    /* verilator lint_on UNUSEDSIGNAL */

    // wybór: pierwszy zgłaszający się master po ostatnio obsłużonym
    always_comb begin
        wyb  = ost;
        znal = 1'b0;
        for (k = 1; k <= N; k = k + 1) begin
            /* verilator lint_off WIDTHEXPAND */  // ost rozszerzane do 32 bitów — celowo
            i = (ost + k) % N;
            /* verilator lint_on WIDTHEXPAND */
            if (!znal && (m_read[i] || m_write[i])) begin
                /* verilator lint_off WIDTHTRUNC */
                wyb = i;
                /* verilator lint_on WIDTHTRUNC */
                znal = 1'b1;
            end
        end
    end

    assign s_adr   = m_adr[wyb*AW +: AW];
    assign s_wdata = m_wdata[wyb*32 +: 32];
    assign s_read  = znal && m_read[wyb] && !pelna;
    assign s_write = znal && m_write[wyb];
    logic   przyj;
    assign przyj = (s_read || s_write) && !s_wait;

    always_comb begin
        m_wait = {N{1'b1}};
        if (przyj) m_wait[wyb] = 1'b0;            // tylko wybrany master z przyjętym transferem
    end

    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : g_rv
            /* verilator lint_off WIDTHTRUNC */
            localparam [IW-1:0] GI = g;
            /* verilator lint_on WIDTHTRUNC */
            assign m_rvalid[g] = s_rvalid && (kol[wo] == GI);
        end
    endgenerate
    assign m_rdata = s_rdata;

    always_ff @(posedge clk) begin
        if (rst) begin
            ost <= {IW{1'b0}};
            wz  <= {KW{1'b0}};
            wo  <= {KW{1'b0}};
            ile <= {(KW+1){1'b0}};
        end else begin
            if (przyj) ost <= wyb;
            if (przyj && s_read) begin
                kol[wz] <= wyb;
                wz      <= wz + 1'b1;
            end
            if (s_rvalid) wo <= wo + 1'b1;
            ile <= ile + {{KW{1'b0}}, przyj && s_read} - {{KW{1'b0}}, s_rvalid};
        end
    end
endmodule

`default_nettype wire
