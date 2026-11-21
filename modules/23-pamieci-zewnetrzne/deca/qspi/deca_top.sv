// Moduł nadrzędny DECA — Verilog. Pamięć QSPI flash na płytce (23.03), tylko odczyt (zawartość pamięci nie jest
// zmieniana): po resecie i po naciśnięciu KEY[1] — identyfikator JEDEC (0x9F), 16 bajtów od adresu 0 rozkazem
// READ 0x03 (1-1-1) i te same 16 bajtów rozkazem QUAD OUTPUT READ 0x6B (1-1-4, 8 cykli pustych), porównanie.
// Diody (świecą jedynki): SW = 00 — bajt producenta, 01 — typ, 10 — pojemność, 11 — LED[7] zgodność odczytów
// 1-1-1 i 1-1-4, LED[6] koniec sekwencji, LED[3:0] — najmłodsze bity pierwszego bajtu pamięci.
// SCLK = 50 MHz / 4 = 12,5 MHz. KEY[0] — reset.
`default_nettype none

module deca_top (
    input  logic       MAX10_CLK1_50,
    input  logic [1:0] KEY,
    input  logic [1:0] SW,
    output logic [7:0] LED,                     // 0 = świeci
    output logic       FLASH_DCLK,
    output logic       FLASH_NCSO,
    output logic       FLASH_RESET_n,
    inout  wire  [3:0] FLASH_DATA
);
    logic clk;
    assign clk = MAX10_CLK1_50;
    logic [1:0] rs = 2'b00;
    always_ff @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    logic rst;
    assign rst = !rs[1];

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0] s_sw = 2'b00, s_k = 2'b11;
    always_ff @(posedge clk) begin
        s_sw <= SW;
        s_k  <= {s_k[0], KEY[1]};
    end
    logic k_pop = 1'b1;
    always_ff @(posedge clk) k_pop <= s_k[1];
    logic nacisk;
    assign nacisk = k_pop && !s_k[1];

    // ---- kontroler
    logic        start = 1'b0, z_adresem = 1'b0, quad = 1'b0;
    logic [7:0]  rozkaz = 8'h00;
    logic [3:0]  puste = 4'd0;
    logic [8:0]  dlugosc = 9'd0;
    logic       rwazne, gotowy, wpobierz;
    logic [7:0] rdane;
    logic [3:0] dq_o, dq_oe;
    qspi_master #(.DIV(2)) u_qspi (.clk(clk), .rst(rst), .start(start), .rozkaz(rozkaz), .adres(24'd0),
        .z_adresem(z_adresem), .puste(puste), .dlugosc(dlugosc), .zapis(1'b0), .quad(quad), .wdane(8'h00),
        .wpobierz(wpobierz), .rdane(rdane), .rwazne(rwazne), .gotowy(gotowy), .sclk(FLASH_DCLK), .cs_n(FLASH_NCSO),
        .dq_o(dq_o), .dq_oe(dq_oe), .dq_i(FLASH_DATA));
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : g_dq
            assign FLASH_DATA[g] = dq_oe[g] ? dq_o[g] : 1'bz;
        end
    endgenerate
    assign FLASH_RESET_n = 1'b1;

    // ---- sekwencja: ID, odczyt 1-1-1, odczyt 1-1-4
    logic [7:0]   id [0:2];
    logic [127:0] a, b;
    logic [4:0]   n;
    logic [2:0]   krok = 3'd0;
    logic         zgodne = 1'b0, koniec = 1'b0;
    always_ff @(posedge clk) begin
        start <= 1'b0;
        if (rst || nacisk) begin
            krok   <= 3'd0;
            koniec <= 1'b0;
        end else case (krok)
            3'd0: if (gotowy) begin
                      rozkaz <= 8'h9F; z_adresem <= 1'b0; puste <= 4'd0; dlugosc <= 9'd3; quad <= 1'b0;
                      start <= 1'b1; n <= 5'd0; krok <= 3'd1;
                  end
            3'd1: if (rwazne) begin id[n[1:0]] <= rdane; n <= n + 1'b1; end
                  else if (gotowy && !start) krok <= 3'd2;
            3'd2: begin
                      rozkaz <= 8'h03; z_adresem <= 1'b1; puste <= 4'd0; dlugosc <= 9'd16; quad <= 1'b0;
                      start <= 1'b1; krok <= 3'd3;
                  end
            3'd3: if (rwazne) a <= {a[119:0], rdane};
                  else if (gotowy && !start) krok <= 3'd4;
            3'd4: begin
                      rozkaz <= 8'h6B; z_adresem <= 1'b1; puste <= 4'd8; dlugosc <= 9'd16; quad <= 1'b1;
                      start <= 1'b1; krok <= 3'd5;
                  end
            3'd5: if (rwazne) b <= {b[119:0], rdane};
                  else if (gotowy && !start) begin
                      zgodne <= (a == b);
                      koniec <= 1'b1;
                      krok   <= 3'd6;
                  end
            default: ;
        endcase
    end

    logic [7:0] pokaz;
    always_comb case (s_sw)
        2'b00:   pokaz = id[0];
        2'b01:   pokaz = id[1];
        2'b10:   pokaz = id[2];
        default: pokaz = {zgodne, koniec, 2'b00, a[123:120]};
    endcase
    assign LED = ~pokaz;
endmodule

`default_nettype wire
