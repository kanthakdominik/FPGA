// Rejestr potokowy strumienia valid/ready z buforem „skid” — porty wypisane osobno (Verilog nie ma interfejsów).
`default_nettype none

module skid_buffer #(
    parameter integer W = 8
) (
    input  wire         clk,
    input  wire         rst,
    input  wire [W-1:0] s_data,
    input  wire         s_valid,
    output wire         s_ready,
    output wire [W-1:0] m_data,
    output wire         m_valid,
    input  wire         m_ready
);
    reg [W-1:0] main_data, skid_data;
    reg         main_valid, skid_valid;

    assign s_ready = ~skid_valid;
    assign m_valid = main_valid;
    assign m_data  = main_data;

    always @(posedge clk) begin
        if (rst) begin
            main_valid <= 1'b0;
            skid_valid <= 1'b0;
        end else if (m_ready || !main_valid) begin
            if (skid_valid) begin
                main_data  <= skid_data;
                main_valid <= 1'b1;
                skid_valid <= 1'b0;
            end else begin
                main_data  <= s_data;
                main_valid <= s_valid;
            end
        end else if (s_valid && s_ready) begin
            skid_data  <= s_data;
            skid_valid <= 1'b1;
        end
    end
endmodule

`default_nettype wire
