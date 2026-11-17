// Blok rejestrów z interfejsem AXI4-Lite (podrzędny, dane 32 bity) — układ weryfikowany w module 11.
// Kanały zapisu (AW, W) przyjmowane niezależnie, w dowolnej kolejności; zapis wykonywany, gdy oba są
// w buforach, a odpowiedź B wolna. Odczyt: AR przyjmowany, gdy kanał R wolny; dane rejestrowane.
// Jedna transakcja w toku na kierunek. Odpowiedź OKAY (00) albo SLVERR (10) dla adresu spoza mapy.
//
//   adres  nazwa    dostęp  pola
//   0x00   ID       RO      32'h414C_5531 ("ALU1")
//   0x04   CTRL     RW      [2:0] OP (kod operacji jak alu_hs z modułu 10), [8] IRQ_EN
//   0x08   OPA      RW      [7:0]
//   0x0C   OPB      RW      [7:0]
//   0x10   RESULT   RO      [7:0] RES, [8] CARRY, [9] ZERO, [10] ERR — liczone z OPA, OPB, OP
//   0x14   STATUS   W1C     [0] ERR — ustawiany zapisem CTRL z OP = 7, kasowany zapisem 1
//   0x18   SCRATCH  RW      [31:0] — z obsługą WSTRB (pozostałe rejestry RW: bajty 0 i 1)
//   0x1C   —                poza mapą: SLVERR, odczyt 0
//   irq = STATUS.ERR & CTRL.IRQ_EN
//
// Parametr BUG wstrzykuje błąd do ćwiczeń weryfikacji (0 = układ poprawny):
//   1 — SCRATCH ignoruje WSTRB (zapisuje wszystkie bajty),
//   2 — dowolny zapis STATUS kasuje ERR (bez sprawdzania bitu danych).
module axil_regs #(
    parameter int BUG = 0
) (
    input  logic        clk,
    input  logic        rst,
    // zapis: adres
    input  logic        s_awvalid,
    output logic        s_awready,
    /* verilator lint_off UNUSEDSIGNAL */          // bity [1:0] adresu: wyrównanie do słowa
    input  logic [4:0]  s_awaddr,
    /* verilator lint_on UNUSEDSIGNAL */
    // zapis: dane
    input  logic        s_wvalid,
    output logic        s_wready,
    input  logic [31:0] s_wdata,
    input  logic [3:0]  s_wstrb,
    // zapis: odpowiedź
    output logic        s_bvalid,
    input  logic        s_bready,
    output logic [1:0]  s_bresp,
    // odczyt: adres
    input  logic        s_arvalid,
    output logic        s_arready,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [4:0]  s_araddr,
    /* verilator lint_on UNUSEDSIGNAL */
    // odczyt: dane
    output logic        s_rvalid,
    input  logic        s_rready,
    output logic [31:0] s_rdata,
    output logic [1:0]  s_rresp,
    output logic        irq
);
    localparam logic [31:0] ID_VALUE = 32'h414C_5531;
    localparam logic [1:0]  OKAY = 2'b00, SLVERR = 2'b10;

    // rejestry
    logic [2:0]  op;
    logic        irq_en;
    logic [7:0]  opa, opb;
    logic        st_err;
    logic [31:0] scratch;

    // wynik ALU (jak alu_hs z modułu 10, bez handshake)
    logic [7:0]  res;
    logic        carry, err;
    always_comb begin
        res   = '0;
        carry = 1'b0;
        err   = 1'b0;
        unique case (op)
            3'd0: {carry, res} = {1'b0, opa} + {1'b0, opb};
            3'd1: {carry, res} = {1'b0, opa} - {1'b0, opb};
            3'd2: res = opa & opb;
            3'd3: res = opa | opb;
            3'd4: res = opa ^ opb;
            3'd5: res = opa << opb[2:0];
            3'd6: res = opa >> opb[2:0];
            3'd7: err = 1'b1;
        endcase
    end
    wire [31:0] result = {21'd0, err, (res == 8'd0), carry, res};

    // ---- zapis ----
    logic        aw_full, w_full;
    logic [2:0]  aw_idx;
    logic [31:0] w_data;
    logic [3:0]  w_strb;

    assign s_awready = !aw_full;
    assign s_wready  = !w_full;
    wire do_write = aw_full && w_full && !s_bvalid;

    function automatic logic [31:0] merge(logic [31:0] old, logic [31:0] data, logic [3:0] strb);
        for (int i = 0; i < 4; i++)
            if (strb[i]) old[8*i +: 8] = data[8*i +: 8];
        return old;
    endfunction

    /* verilator lint_off UNUSEDSIGNAL */          // używane tylko bity pól CTRL
    logic [31:0] ctrl_new;
    /* verilator lint_on UNUSEDSIGNAL */
    assign ctrl_new = merge({23'd0, irq_en, 5'd0, op}, w_data, w_strb);

    always_ff @(posedge clk) begin
        if (rst) begin
            aw_full  <= 1'b0;
            w_full   <= 1'b0;
            s_bvalid <= 1'b0;
            s_bresp  <= OKAY;
            op       <= '0;
            irq_en   <= 1'b0;
            opa      <= '0;
            opb      <= '0;
            st_err   <= 1'b0;
            scratch  <= '0;
        end else begin
            if (s_awvalid && s_awready) begin
                aw_full <= 1'b1;
                aw_idx  <= s_awaddr[4:2];
            end
            if (s_wvalid && s_wready) begin
                w_full <= 1'b1;
                w_data <= s_wdata;
                w_strb <= s_wstrb;
            end
            if (do_write) begin
                aw_full  <= 1'b0;
                w_full   <= 1'b0;
                s_bvalid <= 1'b1;
                s_bresp  <= (aw_idx == 3'd7) ? SLVERR : OKAY;
                unique case (aw_idx)
                    3'd1: begin
                        op     <= ctrl_new[2:0];
                        irq_en <= ctrl_new[8];
                        if (ctrl_new[2:0] == 3'd7) st_err <= 1'b1;
                    end
                    3'd2: opa <= 8'(merge({24'd0, opa}, w_data, w_strb));
                    3'd3: opb <= 8'(merge({24'd0, opb}, w_data, w_strb));
                    3'd5: if (BUG == 2 || (w_strb[0] && w_data[0])) st_err <= 1'b0;
                    3'd6: scratch <= (BUG == 1) ? w_data : merge(scratch, w_data, w_strb);
                    default: ;                                  // ID, RESULT: tylko odczyt; 0x1C: SLVERR
                endcase
            end else if (s_bvalid && s_bready) begin
                s_bvalid <= 1'b0;
            end
        end
    end

    // ---- odczyt ----
    assign s_arready = !s_rvalid;

    always_ff @(posedge clk) begin
        if (rst) begin
            s_rvalid <= 1'b0;
            s_rdata  <= '0;
            s_rresp  <= OKAY;
        end else if (s_arvalid && s_arready) begin
            s_rvalid <= 1'b1;
            s_rresp  <= (s_araddr[4:2] == 3'd7) ? SLVERR : OKAY;
            unique case (s_araddr[4:2])
                3'd0:    s_rdata <= ID_VALUE;
                3'd1:    s_rdata <= {23'd0, irq_en, 5'd0, op};
                3'd2:    s_rdata <= {24'd0, opa};
                3'd3:    s_rdata <= {24'd0, opb};
                3'd4:    s_rdata <= result;
                3'd5:    s_rdata <= {31'd0, st_err};
                3'd6:    s_rdata <= scratch;
                3'd7:    s_rdata <= '0;
            endcase
        end else if (s_rvalid && s_rready) begin
            s_rvalid <= 1'b0;
        end
    end

    assign irq = st_err && irq_en;
endmodule
