// Wbudowany analizator logiczny w miniaturze (17.02) — ta sama zasada co Signal Tap i ILA:
// próbki sygnałów zapisywane w każdym takcie do bufora kołowego w pamięci, warunek wyzwolenia,
// próbki sprzed wyzwolenia (PRE) i po nim, odczyt bufora po zakończeniu.
//   arm       — zbocze narastające uzbraja analizator (poziom z przełącznika albo źródła JTAG),
//   trig_val, trig_mask — warunek: ((probe ^ trig_val) & trig_mask) == 0 (maska 0 = bit nieistotny),
//   trig_zbocze = 1 — wyzwolenie dopiero przy przejściu warunku z fałszu na prawdę,
//   pre       — liczba próbek przed wyzwoleniem (0..2^AW - 1); wyzwolenie jest ignorowane,
//               dopóki bufor nie zbierze pre próbek,
//   rd_addr -> rd_data (takt opóźnienia): próbka nr rd_addr, 0 = najstarsza, pre = próbka wyzwolenia.
// Stan: armed (czeka na wyzwolenie), capturing (zbiera próbki po wyzwoleniu), done; trig_out — impuls
// w takcie po wyzwoleniu (np. na pin, jako wyzwolenie oscyloskopu).
`default_nettype none

module mini_ila #(
    parameter W  = 16,
    parameter AW = 8                     // głębokość 2^AW próbek
) (
    input  wire          clk,
    input  wire          rst,
    input  wire [W-1:0]  probe,
    input  wire          arm,
    input  wire [W-1:0]  trig_val,
    input  wire [W-1:0]  trig_mask,
    input  wire          trig_zbocze,
    input  wire [AW-1:0] pre,
    input  wire [AW-1:0] rd_addr,
    output reg  [W-1:0]  rd_data,
    output wire          armed,
    output wire          capturing,
    output wire          done,
    output reg           trig_out
);
    localparam [1:0] S_IDLE = 2'd0, S_PRE = 2'd1, S_WAIT = 2'd2, S_POST = 2'd3;
    localparam [AW-1:0] OSTATNI = {AW{1'b1}};          // 2^AW - 1

    reg [W-1:0]  mem [0:(1<<AW)-1];
    reg [1:0]    stan;
    reg          zakonczony;
    reg          arm_d, war_d;
    reg [AW-1:0] wr_ptr, licz, trig_ptr;

    wire war  = ((probe ^ trig_val) & trig_mask) == {W{1'b0}};
    wire wyzw = war && (!trig_zbocze || !war_d);
    wire zapis = (stan != S_IDLE);

    always @(posedge clk) begin
        if (zapis) mem[wr_ptr] <= probe;
        rd_data <= mem[trig_ptr - pre + rd_addr];
    end

    always @(posedge clk) begin
        arm_d    <= arm;
        war_d    <= war;
        trig_out <= 1'b0;
        if (rst) begin
            stan       <= S_IDLE;
            zakonczony <= 1'b0;
            wr_ptr     <= {AW{1'b0}};
            licz       <= {AW{1'b0}};
            trig_ptr   <= {AW{1'b0}};
            arm_d      <= 1'b0;
        end else begin
            if (zapis) wr_ptr <= wr_ptr + 1'b1;
            case (stan)
                S_IDLE:
                    if (arm && !arm_d) begin
                        zakonczony <= 1'b0;
                        licz       <= {AW{1'b0}};
                        stan       <= (pre == {AW{1'b0}}) ? S_WAIT : S_PRE;
                    end
                S_PRE: begin                            // zbieranie próbek sprzed wyzwolenia
                    licz <= licz + 1'b1;
                    if (licz + 1'b1 == pre) stan <= S_WAIT;
                end
                S_WAIT:
                    if (wyzw) begin
                        trig_ptr <= wr_ptr;             // próbka wyzwolenia zapisywana w tym takcie
                        trig_out <= 1'b1;
                        licz     <= OSTATNI - pre;      // tyle próbek jeszcze po wyzwoleniu
                        if (pre == OSTATNI) begin
                            stan       <= S_IDLE;
                            zakonczony <= 1'b1;
                        end else begin
                            stan <= S_POST;
                        end
                    end
                default: begin                          // S_POST
                    licz <= licz - 1'b1;
                    if (licz == {{(AW-1){1'b0}}, 1'b1}) begin
                        stan       <= S_IDLE;
                        zakonczony <= 1'b1;
                    end
                end
            endcase
        end
    end

    assign armed     = (stan == S_PRE) || (stan == S_WAIT);
    assign capturing = (stan == S_POST);
    assign done      = zakonczony;
endmodule

`default_nettype wire
