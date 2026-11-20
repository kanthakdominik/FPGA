// PWM centrowany z wyjściami komplementarnymi i czasem martwym (20.04) — sterowanie gałęzią mostka
// (tranzystor górny i dolny). Licznik liczy w górę i w dół: 0 … OKRES−1, OKRES−1 … 0 (wartości skrajne
// po dwa takty, okres 2·OKRES taktów), odniesienie = (licznik < wyp) — wypełnienie dokładnie wyp/OKRES. Wypełnienie pobierane tylko przy liczniku = 0 (podwójne buforowanie —
// zmiana w trakcie okresu nie tworzy krótkich impulsów). Każde wyjście włącza się dopiero MARTWY taktów
// po wyłączeniu drugiego — oba tranzystory nigdy nie przewodzą jednocześnie.
`default_nettype none

module pwm_mostek #(
    parameter W      = 10,
    parameter OKRES  = 1000,                    // f_PWM = f_clk / (2·OKRES)
    parameter MARTWY = 20                       // takty, >= 1
) (
    input  wire         clk,
    input  wire         rst,
    input  wire [W-1:0] wyp,                    // 0 … OKRES
    output reg          gora = 1'b0,
    output reg          dol = 1'b0,
    output reg          poczatek = 1'b0         // impuls na początku okresu
);
    localparam MW = $clog2(MARTWY + 1);
    localparam [W-1:0]  TOP = OKRES;
    localparam [MW-1:0] DT  = MARTWY;

    reg [W-1:0]  licz = {W{1'b0}};
    reg          w_gore = 1'b1;
    reg [W-1:0]  wyp_b = {W{1'b0}};
    reg          ref_d = 1'b0;
    reg [MW-1:0] t = {MW{1'b0}};                // odliczanie czasu martwego po zmianie odniesienia

    wire ref_s = (licz < wyp_b);

    always @(posedge clk) begin
        poczatek <= 1'b0;
        if (rst) begin
            licz   <= {W{1'b0}};
            w_gore <= 1'b1;
            gora   <= 1'b0;
            dol    <= 1'b0;
            t      <= DT;
        end else begin
            // licznik trójkątny
            if (w_gore) begin
                if (licz == TOP - 1'b1) w_gore <= 1'b0;   // szczyt: wartość trwa dwa takty
                else licz <= licz + 1'b1;
            end else begin
                if (licz == 0) w_gore <= 1'b1;
                else licz <= licz - 1'b1;
            end
            if (licz == 0 && !w_gore) begin              // koniec okresu: nowe wypełnienie od następnego taktu
                wyp_b    <= (wyp > TOP) ? TOP : wyp;
                poczatek <= 1'b1;
            end
            // czas martwy: po każdej zmianie odniesienia oba wyjścia wyłączone przez MARTWY taktów
            ref_d <= ref_s;
            if (ref_s != ref_d) begin
                gora <= 1'b0;
                dol  <= 1'b0;
                t    <= DT - 1'b1;
            end else if (t != 0) begin
                t <= t - 1'b1;
            end else begin
                gora <= ref_s;
                dol  <= !ref_s;
            end
        end
    end
endmodule

`default_nettype wire
