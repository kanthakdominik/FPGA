// Moduł nadrzędny DECA — Verilog. UART 115 200 b/s 8N1 na złączu GPIO (20.01):
//   GPIO0_D[0] — TX (do wejścia RX przejściówki USB-UART 3,3 V), GPIO0_D[1] — RX (z wyjścia TX przejściówki).
//   Echo: każdy odebrany bajt wraca do komputera; SW[0] w górze — echo zamienia małe litery na wielkie.
//   KEY[1] — wysłanie napisu „DECA UART 115200 8N1”, KEY[0] — reset.
//   LED[6:0] — kod ostatniego odebranego znaku, LED[7] — błąd ramki (lepki do resetu).
// Bez przejściówki: zwora między GPIO0_D[0] i GPIO0_D[1] — napis z KEY[1] wraca i pojawia się na diodach.
`default_nettype none

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,
    input  wire [1:0] SW,
    output wire [7:0] LED,                     // 0 = świeci
    inout  wire [1:0] GPIO0_D
);
    wire clk = MAX10_CLK1_50;

    reg [1:0] rs = 2'b00;
    always @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    wire rst = ~rs[1];

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] s_sw = 2'b00, s_key = 2'b11;
    always @(posedge clk) begin
        s_sw  <= SW;
        s_key <= {s_key[0], KEY[1]};
    end

    // ---- UART
    wire       tx, gotowy, wazne, bl_r;
    wire [7:0] odebr;
    reg        start = 1'b0;
    reg  [7:0] bajt = 8'd0;
    /* verilator lint_off PINCONNECTEMPTY */
    uart_tx #(.CLK_HZ(50_000_000), .BAUD(115_200)) u_tx (.clk(clk), .rst(rst), .start(start), .dane(bajt),
        .gotowy(gotowy), .tx(tx));
    uart_rx #(.CLK_HZ(50_000_000), .BAUD(115_200)) u_rx (.clk(clk), .rst(rst), .rx(GPIO0_D[1]), .dane(odebr),
        .wazne(wazne), .blad_ramki(bl_r), .blad_parz());
    /* verilator lint_on PINCONNECTEMPTY */
    assign GPIO0_D[0] = tx;
    assign GPIO0_D[1] = 1'bz;

    // ---- napis
    localparam DL = 22;
    function [7:0] napis(input [4:0] i);
        case (i)
            5'd0: napis = "D";  5'd1: napis = "E";  5'd2: napis = "C";  5'd3: napis = "A";  5'd4: napis = " ";
            5'd5: napis = "U";  5'd6: napis = "A";  5'd7: napis = "R";  5'd8: napis = "T";  5'd9: napis = " ";
            5'd10: napis = "1"; 5'd11: napis = "1"; 5'd12: napis = "5"; 5'd13: napis = "2"; 5'd14: napis = "0";
            5'd15: napis = "0"; 5'd16: napis = " "; 5'd17: napis = "8"; 5'd18: napis = "N"; 5'd19: napis = "1";
            5'd20: napis = 8'h0D; default: napis = 8'h0A;
        endcase
    endfunction

    // przycisk: zbocze po odczekaniu drgań (próbkowanie co 2^18 taktów)
    reg [17:0] dz = 18'd0;
    reg [1:0]  kp = 2'b11;
    always @(posedge clk) begin
        dz <= dz + 1'b1;
        if (dz == 0) kp <= {kp[0], s_key[1]};
    end
    wire nacisk = (kp == 2'b10) && (dz == 0);

    reg        nadaje = 1'b0;
    reg [4:0]  ni = 5'd0;
    reg        echo = 1'b0;
    reg [7:0]  echo_b = 8'd0;
    reg [6:0]  ost = 7'd0;
    reg        blad = 1'b0;
    always @(posedge clk) begin
        start <= 1'b0;
        if (rst) begin
            nadaje <= 1'b0;
            echo   <= 1'b0;
            blad   <= 1'b0;
        end else begin
            if (wazne) begin
                ost <= odebr[6:0];
                if (bl_r) blad <= 1'b1;
                echo   <= 1'b1;
                echo_b <= (s_sw[0] && odebr >= "a" && odebr <= "z") ? odebr - 8'd32 : odebr;
            end
            if (nacisk) begin
                nadaje <= 1'b1;
                ni     <= 5'd0;
            end
            if (gotowy && !start) begin
                if (echo) begin                            // echo ma pierwszeństwo przed napisem
                    bajt  <= echo_b;
                    start <= 1'b1;
                    echo  <= 1'b0;
                end else if (nadaje) begin
                    bajt  <= napis(ni);
                    start <= 1'b1;
                    ni    <= ni + 1'b1;
                    if (ni == DL - 1) nadaje <= 1'b0;
                end
            end
        end
    end

    assign LED = ~{blad, ost};
endmodule

`default_nettype wire
