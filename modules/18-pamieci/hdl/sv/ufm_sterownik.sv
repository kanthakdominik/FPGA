// Sterownik pamięci flash użytkownika MAX 10 (18.05) — strona "master" dla rdzenia On-Chip Flash IP
// (interfejsy Avalon-MM: csr i data, tryb równoległy, burstcount = 1). Polecenia:
//   op = 0 — odczyt słowa 32-bitowego spod addr,
//   op = 1 — zapis (program) słowa; flash zmienia tylko bity 1 -> 0, więc miejsce musi być skasowane,
//   op = 2 — kasowanie strony zawierającej addr (wszystkie bity -> 1).
// Zapis i kasowanie: zdjęcie ochrony zapisu sektora SEKTOR w rejestrze kontrolnym, operacja,
// odpytywanie rejestru statusu do busy = 00, sprawdzenie ws/es, przywrócenie ochrony.
// Rejestr statusu (adres 0): [1:0] busy (00 bezczynny, 01 kasowanie, 10 zapis, 11 odczyt), [2] rs, [3] ws, [4] es.
// Rejestr kontrolny (adres 1): [19:0] adres kasowanej strony, [22:20] numer kasowanego sektora (111 — brak),
// [27:23] ochrona zapisu sektorów 1..5 (1 = chroniony).
module ufm_sterownik #(
    parameter int AW     = 17,                   // szerokość adresu danych rdzenia (słowa 32-bitowe)
    parameter int SEKTOR = 1,                    // sektor UFM, w którym leżą adresy (1..5)
    parameter int CZEKAJ = 4                     // takty od polecenia do pierwszego odczytu statusu
) (
    input  logic          clk,
    input  logic          rst,
    // polecenia
    input  logic          start,
    input  logic [1:0]    op,
    input  logic [AW-1:0] addr,
    input  logic [31:0]   wdata,
    output logic          busy,
    output logic          done,
    output logic          ok,
    output logic [31:0]   rdata,
    // Avalon-MM csr
    output logic          csr_addr,
    output logic          csr_read,
    output logic          csr_write,
    output logic [31:0]   csr_writedata,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [31:0]   csr_readdata,               // używane bity [4:0]
    /* verilator lint_on UNUSEDSIGNAL */
    // Avalon-MM data
    output logic [AW-1:0] data_addr,
    output logic          data_read,
    output logic          data_write,
    output logic [31:0]   data_writedata,
    output logic [3:0]    data_burstcount,
    input  logic          data_waitrequest,
    input  logic          data_readdatavalid,
    input  logic [31:0]   data_readdata
);
    localparam logic [3:0] S_IDLE = 4'd0, S_RD = 4'd1, S_RD_CZEKAJ = 4'd2, S_ODBLOKUJ = 4'd3, S_ZAPIS = 4'd4,
                     S_KASUJ = 4'd5, S_START = 4'd6, S_STATUS = 4'd7, S_STATUS_D = 4'd8, S_ZABLOKUJ = 4'd9,
                     S_KONIEC = 4'd10, S_ZAPIS_REQ = 4'd11, S_STATUS_W = 4'd12;
    localparam logic [1:0] OP_ODCZYT = 2'd0, OP_ZAPIS = 2'd1;            // 2 = kasowanie strony
    // rejestr kontrolny: wszystko 1 (brak kasowania, ochrona wszystkich sektorów) poza bitem ochrony SEKTOR
    localparam logic [31:0] CTRL_CHRONIONY = 32'hFFFF_FFFF;
    localparam logic [31:0] CTRL_ODBLOK    = CTRL_CHRONIONY & ~(32'd1 << (22 + SEKTOR));

    logic [3:0]  stan;
    logic [1:0]  op_r;
    logic [3:0]  licz;
    logic [19:0] adres_strony;                // pole pe rejestru kontrolnego (rozszerzenie zerami)
    assign adres_strony = 20'(data_addr);

    assign busy            = (stan != S_IDLE);
    assign data_burstcount = 4'd1;

    always_ff @(posedge clk)
        if (rst) begin
            stan       <= S_IDLE;
            done       <= 1'b0;
            ok         <= 1'b0;
            csr_read   <= 1'b0;
            csr_write  <= 1'b0;
            data_read  <= 1'b0;
            data_write <= 1'b0;
            csr_addr   <= 1'b0;
        end else begin
            done      <= 1'b0;
            csr_read  <= 1'b0;
            csr_write <= 1'b0;
            case (stan)
                S_IDLE:
                    if (start) begin
                        op_r           <= op;
                        data_addr      <= addr;
                        data_writedata <= wdata;
                        ok             <= 1'b0;
                        if (op == OP_ODCZYT) begin
                            data_read <= 1'b1;
                            stan      <= S_RD;
                        end else begin
                            stan <= S_ODBLOKUJ;
                        end
                    end
                S_RD:                                   // żądanie trwa, dopóki rdzeń trzyma waitrequest
                    if (!data_waitrequest) begin
                        data_read <= 1'b0;
                        stan      <= S_RD_CZEKAJ;
                    end
                S_RD_CZEKAJ:
                    if (data_readdatavalid) begin
                        rdata <= data_readdata;
                        ok    <= 1'b1;
                        stan  <= S_KONIEC;
                    end
                S_ODBLOKUJ: begin                       // zdjęcie ochrony zapisu sektora
                    csr_addr      <= 1'b1;
                    csr_write     <= 1'b1;
                    csr_writedata <= CTRL_ODBLOK;
                    stan <= (op_r == OP_ZAPIS) ? S_ZAPIS_REQ : S_KASUJ;
                end
                S_ZAPIS_REQ: begin                      // zapis danych takt po zdjęciu ochrony
                    data_write <= 1'b1;
                    stan       <= S_ZAPIS;
                end
                S_ZAPIS:
                    if (!data_waitrequest) begin
                        data_write <= 1'b0;
                        licz       <= 4'(CZEKAJ);
                        stan       <= S_START;
                    end
                S_KASUJ: begin                          // adres strony w polu pe, sektor 111 = brak
                    csr_addr      <= 1'b1;
                    csr_write     <= 1'b1;
                    csr_writedata <= {CTRL_ODBLOK[31:20], adres_strony};
                    licz          <= 4'(CZEKAJ);
                    stan          <= S_START;
                end
                S_START:                                // rdzeń potrzebuje chwili, zanim pokaże busy
                    if (licz == 4'd0) stan <= S_STATUS;
                    else              licz <= licz - 4'd1;
                S_STATUS: begin                         // odczyt statusu; dane po jednym takcie oczekiwania
                    csr_addr <= 1'b0;
                    csr_read <= 1'b1;
                    stan     <= S_STATUS_W;
                end
                S_STATUS_W:
                    stan <= S_STATUS_D;
                S_STATUS_D:
                    if (csr_readdata[1:0] != 2'b00) begin
                        stan <= S_STATUS;              // wciąż zajęty
                    end else begin
                        ok   <= (op_r == OP_ZAPIS) ? csr_readdata[3] : csr_readdata[4];
                        stan <= S_ZABLOKUJ;
                    end
                S_ZABLOKUJ: begin                       // przywrócenie ochrony
                    csr_addr      <= 1'b1;
                    csr_write     <= 1'b1;
                    csr_writedata <= CTRL_CHRONIONY;
                    stan          <= S_KONIEC;
                end
                default: begin                          // S_KONIEC
                    done <= 1'b1;
                    stan <= S_IDLE;
                end
            endcase
        end
endmodule

