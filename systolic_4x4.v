module systolic_4x4 #(
    parameter N  = 4,
    parameter AW = 8,
    parameter BW = 8,
    parameter CW = 32
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     vld_in,
    input  wire signed [AW-1:0]     a_in [0:N-1],
    input  wire signed [BW-1:0]     b_in [0:N-1],
    output wire signed [CW-1:0]     c_out [0:N-1][0:N-1]
);

    wire signed [AW-1:0] a_bus [0:N][0:N-1];
    wire signed [BW-1:0] b_bus [0:N][0:N-1];

    genvar i, j;

    generate
        for (i = 0; i < N; i = i + 1) begin : EDGE_A
            assign a_bus[0][i] = a_in[i];
        end
        for (j = 0; j < N; j = j + 1) begin : EDGE_B
            assign b_bus[0][j] = b_in[j];
        end
    endgenerate

    generate
        for (i = 0; i < N; i = i + 1) begin : PE_ROW
            for (j = 0; j < N; j = j + 1) begin : PE_COL

                pe_mac #(.AW(AW), .BW(BW), .CW(CW)) U_PE (
                    .clk    (clk),
                    .rst    (rst),
                    .vld_in (vld_in),
                    .a_in   (a_bus[j][i]),
                    .a_out  (a_bus[j+1][i]),
                    .b_in   (b_bus[i][j]),
                    .b_out  (b_bus[i+1][j]),
                    .c_out  (c_out[i][j])
                );
            end
        end
    endgenerate

endmodule
