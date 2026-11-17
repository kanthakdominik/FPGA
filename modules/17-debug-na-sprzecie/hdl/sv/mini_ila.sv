// Wbudowany analizator logiczny w miniaturze (17.02): bufor kołowy 2^AW próbek, warunek wyzwolenia
// (wartość z maską, poziom albo zbocze warunku), pre próbek przed wyzwoleniem, odczyt po zakończeniu.
// rd_addr = 0 — najstarsza próbka, rd_addr = pre — próbka wyzwolenia. Wyzwolenie jest ignorowane,
// dopóki bufor nie zbierze pre próbek. trig_out — impuls w takcie po wyzwoleniu.
module mini_ila #(
    parameter int W  = 16,
    parameter int AW = 8
) (
    input  logic          clk,
    input  logic          rst,
    input  logic [W-1:0]  probe,
    input  logic          arm,
    input  logic [W-1:0]  trig_val,
    input  logic [W-1:0]  trig_mask,
    input  logic          trig_zbocze,
    input  logic [AW-1:0] pre,
    input  logic [AW-1:0] rd_addr,
    output logic [W-1:0]  rd_data,
    output logic          armed,
    output logic          capturing,
    output logic          done,
    output logic          trig_out
);
    typedef enum logic [1:0] {S_IDLE, S_PRE, S_WAIT, S_POST} stan_t;
    localparam logic [AW-1:0] OSTATNI = '1;

    logic [W-1:0]  mem [2**AW];
    stan_t         stan;
    logic          arm_d, war, war_d, wyzw, zapis;
    logic [AW-1:0] wr_ptr, licz, trig_ptr;

    assign war   = ((probe ^ trig_val) & trig_mask) == '0;
    assign wyzw  = war && (!trig_zbocze || !war_d);
    assign zapis = (stan != S_IDLE);

    always_ff @(posedge clk) begin
        if (zapis) mem[wr_ptr] <= probe;
        rd_data <= mem[trig_ptr - pre + rd_addr];
    end

    always_ff @(posedge clk) begin
        arm_d    <= arm;
        war_d    <= war;
        trig_out <= 1'b0;
        if (rst) begin
            stan     <= S_IDLE;
            done     <= 1'b0;
            wr_ptr   <= '0;
            licz     <= '0;
            trig_ptr <= '0;
            arm_d    <= 1'b0;
        end else begin
            if (zapis) wr_ptr <= wr_ptr + 1'b1;
            unique case (stan)
                S_IDLE:
                    if (arm && !arm_d) begin
                        done <= 1'b0;
                        licz <= '0;
                        stan <= (pre == '0) ? S_WAIT : S_PRE;
                    end
                S_PRE: begin
                    licz <= licz + 1'b1;
                    if (licz + 1'b1 == pre) stan <= S_WAIT;
                end
                S_WAIT:
                    if (wyzw) begin
                        trig_ptr <= wr_ptr;
                        trig_out <= 1'b1;
                        licz     <= OSTATNI - pre;
                        if (pre == OSTATNI) begin
                            stan <= S_IDLE;
                            done <= 1'b1;
                        end else begin
                            stan <= S_POST;
                        end
                    end
                S_POST: begin
                    licz <= licz - 1'b1;
                    if (licz == AW'(1)) begin
                        stan <= S_IDLE;
                        done <= 1'b1;
                    end
                end
            endcase
        end
    end

    assign armed     = (stan == S_PRE) || (stan == S_WAIT);
    assign capturing = (stan == S_POST);
endmodule
