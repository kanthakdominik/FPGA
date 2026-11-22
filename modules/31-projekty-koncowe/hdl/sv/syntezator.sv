// Syntezator 4-głosowy (31.03). Głos: akumulator fazy 24-bitowy (krok z tabeli półtonów, oktawy przesunięciem),
// kształt fali (0 — prostokąt, 1 — piła, 2 — trójkąt, 3 — sinus z tablicy ćwiartki), obwiednia ADSR i głośność
// z prędkości klawisza. Na każdą próbkę (impuls ramka z i2s_master, fs = 12,5 MHz / 256) głosy liczone są po
// kolei, 4 takty na głos, jedną mnożarką w kolejnych krokach; suma 4 głosów, skala do 24 bitów.
// Zdarzenia z dekodera MIDI czekają w rejestrze do początku następnej próbki. Przydział głosów: ta sama nuta —
// ten sam głos (ponowny atak), inaczej wolny głos, inaczej najstarszy przydzielony (kolejka cykliczna).
`default_nettype none

module syntezator #(
    parameter [16:0] A_KROK = 17'd268,      // atak 0 -> 65 535 w ok. 5 ms (przy fs 48,8 kHz)
    parameter [16:0] D_KROK = 17'd5,        // opadanie do S_POZ w ok. 100 ms
    parameter [16:0] S_POZ  = 17'd39321,    // podtrzymanie 0,6
    parameter [16:0] R_KROK = 17'd4         // wybrzmiewanie z 0,6 w ok. 200 ms
) (
    input  logic               clk,
    input  logic               rst,
    input  logic               ramka,
    input  logic               ev_on,
    input  logic               ev_off,
    input  logic               ev_wszystkie,
    input  logic               ev_prog,
    input  logic [6:0]         nuta,
    input  logic [6:0]         vel,
    input  logic [1:0]         prog,
    output logic  signed [23:0] probka = 24'sd0,
    output logic                nowa = 1'b0,
    output logic [3:0]         aktywne
);
    localparam [2:0] CISZA = 3'd0, ATAK = 3'd1, OPAD = 3'd2, PODTRZ = 3'd3, WYBRZ = 3'd4;

    // krok fazy dla nut 120..131; nuta n: TAB[n mod 12] >> (10 - n div 12)
    function [23:0] krok_nuty(input [6:0] n);
        logic [23:0] t;
        logic [6:0]  okt, s;
        begin
            okt = n / 7'd12;
            s   = n % 7'd12;
            case (s)
                7'd0: t = 24'd2876604;  7'd1: t = 24'd3047655;  7'd2: t = 24'd3228878;  7'd3: t = 24'd3420877;
                7'd4: t = 24'd3624293;  7'd5: t = 24'd3839805;  7'd6: t = 24'd4068132;  7'd7: t = 24'd4310035;
                7'd8: t = 24'd4566323;  7'd9: t = 24'd4837851;  7'd10: t = 24'd5125525; default: t = 24'd5430304;
            endcase
            krok_nuty = t >> (7'd10 - okt);
        end
    endfunction

    logic [2:0]  stan [0:3];
    logic [6:0]  g_nuta [0:3];
    logic [6:0]  g_vel [0:3];
    logic [23:0] faza [0:3];
    logic [23:0] krok [0:3];
    logic [16:0] env [0:3];
    logic [1:0]  fala = 2'd0;
    logic [1:0]  kolejny = 2'd0;
    integer i;
    initial for (i = 0; i < 4; i = i + 1) begin
        stan[i] = CISZA; g_nuta[i] = 7'd0; g_vel[i] = 7'd0; faza[i] = 24'd0; krok[i] = 24'd0; env[i] = 17'd0;
    end
    assign aktywne = {stan[3] != CISZA, stan[2] != CISZA, stan[1] != CISZA, stan[0] != CISZA};

    // zdarzenia oczekujące na początek próbki
    logic       zd_on = 1'b0;
    logic       zd_off = 1'b0;
    logic       zd_wsz = 1'b0;
    logic [6:0] zd_n = 7'd0;
    logic [6:0] zd_v = 7'd0;
    logic [23:0] krok_zd;
    assign krok_zd = krok_nuty(zd_n);            // poza blokiem sekwencyjnym: zwykła logika kombinacyjna

    // wybór głosu dla Note On
    logic [1:0] wyb;
    logic       znal;
    integer   j;
    always @* begin
        wyb = kolejny; znal = 1'b0;
        for (j = 3; j >= 0; j = j - 1)
            if (stan[j] == CISZA) begin wyb = j[1:0]; znal = 1'b1; end
        for (j = 3; j >= 0; j = j - 1)
            if (stan[j] != CISZA && g_nuta[j] == zd_n) begin wyb = j[1:0]; znal = 1'b1; end
    end

    // przetwarzanie głosów
    logic        dziala = 1'b0;
    logic  [3:0] licz = 4'd0;
    logic [1:0] g;
    assign g = licz[3:2];
    /* verilator lint_off UNUSEDSIGNAL */
    logic  [23:0] fz = 24'd0;                         // najmłodsze bity fazy nie wchodzą do kształtu fali
    /* verilator lint_on UNUSEDSIGNAL */
    logic  signed [16:0] w = 17'sd0;
    logic  [15:0] amp = 16'd0;
    logic  signed [15:0] wyj = 16'sd0;
    logic  signed [17:0] acc = 18'sd0;
    // adres ćwiartki sinusa z fazy głosu w kroku 0 (tablica rejestruje — wynik w kroku 1)
    /* verilator lint_off UNUSEDSIGNAL */
    logic [23:0] fg;
    assign fg = faza[g];
    /* verilator lint_on UNUSEDSIGNAL */
    logic [7:0]  sin_a;
    assign sin_a = fg[22] ? ~fg[21:14] : fg[21:14];
    logic [15:0] sin_q;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [22:0] env_vel;
    assign env_vel = env[g][15:0] * g_vel[g];
    logic signed [33:0] iloczyn;
    assign iloczyn = w * $signed({1'b0, amp});
    /* verilator lint_on UNUSEDSIGNAL */
    sin_tab u_sin (.clk(clk), .a(sin_a), .q(sin_q));

    always_ff @(posedge clk) begin
        nowa <= 1'b0;
        if (ev_on)  begin zd_on <= 1'b1; zd_n <= nuta; zd_v <= vel; end
        if (ev_off) begin zd_off <= 1'b1; zd_n <= nuta; end
        if (ev_wszystkie) zd_wsz <= 1'b1;
        if (ev_prog) fala <= prog;
        if (rst) begin
            for (i = 0; i < 4; i = i + 1) begin stan[i] <= CISZA; env[i] <= 17'd0; end
            dziala <= 1'b0; zd_on <= 1'b0; zd_off <= 1'b0; zd_wsz <= 1'b0; kolejny <= 2'd0; fala <= 2'd0;
        end else if (ramka) begin
            // zdarzenia
            if (zd_wsz) begin
                for (i = 0; i < 4; i = i + 1) if (stan[i] != CISZA) stan[i] <= WYBRZ;
            end else if (zd_off) begin
                for (i = 0; i < 4; i = i + 1)
                    if (stan[i] != CISZA && stan[i] != WYBRZ && g_nuta[i] == zd_n) stan[i] <= WYBRZ;
            end else if (zd_on) begin
                stan[wyb]   <= ATAK;
                g_nuta[wyb] <= zd_n;
                g_vel[wyb]  <= zd_v;
                krok[wyb]   <= krok_zd;
                if (!znal) kolejny <= kolejny + 2'd1;
            end
            zd_on <= ev_on; zd_off <= ev_off; zd_wsz <= ev_wszystkie;
            dziala <= 1'b1; licz <= 4'd0; acc <= 18'sd0;
        end else if (dziala) begin
            licz <= licz + 4'd1;
            case (licz[1:0])
                2'd0: begin                                   // faza, adres sinusa, obwiednia
                    fz <= faza[g];
                    faza[g] <= faza[g] + krok[g];
                    case (stan[g])
                        ATAK:   if (env[g] + A_KROK >= 17'd65535) begin env[g] <= 17'd65535; stan[g] <= OPAD; end
                                else env[g] <= env[g] + A_KROK;
                        OPAD:   if (env[g] <= S_POZ + D_KROK) begin env[g] <= S_POZ; stan[g] <= PODTRZ; end
                                else env[g] <= env[g] - D_KROK;
                        WYBRZ:  if (env[g] <= R_KROK) begin env[g] <= 17'd0; stan[g] <= CISZA; end
                                else env[g] <= env[g] - R_KROK;
                        default: ;
                    endcase
                end
                2'd1: begin                                   // próbka fali (sinus już z tablicy), amplituda
                    case (fala)
                        2'd0: w <= fz[23] ? -17'sd32767 : 17'sd32767;
                        2'd1: w <= $signed({~fz[23], ~fz[23], fz[22:8]});
                        2'd2: w <= fz[23] ? 17'sd32767 - $signed({1'b0, fz[22:7]})
                                          : $signed({1'b0, fz[22:7]}) - 17'sd32768;
                        default: w <= fz[23] ? -$signed({1'b0, sin_q}) : $signed({1'b0, sin_q});
                    endcase
                    amp <= env_vel[22:7];
                end
                2'd2: wyj <= iloczyn[31:16];                  // fala × amplituda / 65 536
                default: begin
                    acc <= acc + {{2{wyj[15]}}, wyj};
                    if (licz == 4'd15) begin
                        dziala <= 1'b0;
                        probka <= {acc + {{2{wyj[15]}}, wyj}, 6'd0};
                        nowa   <= 1'b1;
                    end
                end
            endcase
        end
    end
endmodule

`default_nettype wire
