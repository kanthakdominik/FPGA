// Pamięć RAM ze slave'em Avalon-MM z burstami (21.03): burstcount 1…2^(BW-1), adresy słów.
// Zapis: adres i burstcount z pierwszego taktu, kolejne takty z write = 1 niosą dane pod kolejne adresy.
// Odczyt: jeden rozkaz read z burstcount, potem burstcount słów z readdatavalid (odczyt potokowy);
// waitrequest = 1, dopóki trwa oddawanie danych (jeden burst odczytu naraz).
`default_nettype none

module avmm_burst_ram #(
    parameter integer AW = 10,
    parameter integer BW = 5
) (
    input  logic          clk,
    input  logic          rst,
    input  logic [AW-1:0] address,
    input  logic          read,
    input  logic          write,
    input  logic [31:0]   writedata,
    input  logic [3:0]    byteenable,
    input  logic [BW-1:0] burstcount,
    output logic          waitrequest,
    output logic  [31:0]   readdata,
    output logic           readdatavalid
);
    logic [31:0]   mem [0:(1 << AW) - 1];
    logic          w_akt, r_akt;
    logic [AW-1:0] w_adr, r_adr;
    logic [BW-1:0] w_zost, r_zost;
    logic [AW-1:0] w_gdzie;
    assign w_gdzie = w_akt ? w_adr : address;          // pierwszy takt burstu: adres z magistrali

    assign waitrequest = r_akt;

    integer b;
    always_ff @(posedge clk) begin
        if (write && !waitrequest)
            for (b = 0; b < 4; b = b + 1)
                if (byteenable[b]) mem[w_gdzie][b*8 +: 8] <= writedata[b*8 +: 8];
        readdata <= mem[r_adr];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            w_akt         <= 1'b0;
            r_akt         <= 1'b0;
            readdatavalid <= 1'b0;
        end else begin
            if (write && !waitrequest) begin
                w_adr <= w_gdzie + 1'b1;
                if (!w_akt) begin
                    w_akt  <= (burstcount > {{(BW-1){1'b0}}, 1'b1});
                    w_zost <= burstcount - {{(BW-2){1'b0}}, 2'd2};                  // pozostałe takty po następnym
                end else begin
                    if (w_zost == {BW{1'b0}}) w_akt <= 1'b0;
                    w_zost <= w_zost - 1'b1;
                end
            end
            readdatavalid <= r_akt;
            if (r_akt) begin
                r_adr <= r_adr + 1'b1;
                if (r_zost == {BW{1'b0}}) r_akt <= 1'b0;
                r_zost <= r_zost - 1'b1;
            end else if (read && !waitrequest) begin
                r_akt  <= 1'b1;
                r_adr  <= address;
                r_zost <= burstcount - 1'b1;
            end
        end
    end
endmodule

`default_nettype wire
