module pe_mac #(
    parameter AW = 8,
    parameter BW = 8,
    parameter CW = 32
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   vld_in,
    input  wire signed [AW-1:0]   a_in,
    input  wire signed [BW-1:0]   b_in,
    output reg  signed [AW-1:0]   a_out,
    output reg  signed [BW-1:0]   b_out,
    output wire signed [CW-1:0]   c_out
);

    reg signed [CW-1:0] acc;

    assign c_out = acc;

    always @(posedge clk) begin
        if (rst) begin
            acc   <= {CW{1'b0}};
            a_out <= {AW{1'b0}};
            b_out <= {BW{1'b0}};
        end
        else if (vld_in) begin
            acc <= acc + $signed(a_in) * $signed(b_in);
            a_out <= a_in;
            b_out <= b_in;
        end
    end

endmodule
