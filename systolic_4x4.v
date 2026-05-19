// =============================================================================
// FILE: systolic_4x4.v  (corrected index ordering)
// DESCRIPTION: 4×4 Systolic Array for Matrix Multiplication  C = A × B
//
// DATA FLOW:
//   A elements flow LEFT → RIGHT through PE columns.
//   B elements flow TOP → BOTTOM through PE rows.
//   Each PE[i][j] independently accumulates C[i][j] = sum_k A[i][k]*B[k][j].
//
// BUS INDEXING CONVENTION:
//   a_bus[cb][r] = A value at horizontal (column) boundary cb, row r
//     cb=0..N, r=0..N-1. cb=0 is the left edge, cb=N is right drain.
//
//   b_bus[cb][c] = B value at vertical (row) boundary cb, column c
//     cb=0..N, c=0..N-1. cb=0 is the top edge, cb=N is bottom drain.
//
// PE[i][j] connections:
//   a_in  = a_bus[j][i]     (A arriving from left at col-boundary j, row i)
//   a_out → a_bus[j+1][i]   (A passing right to boundary j+1)
//   b_in  = b_bus[i][j]     (B arriving from top at row-boundary i, col j)
//   b_out → b_bus[i+1][j]   (B passing down to boundary i+1)
// =============================================================================

module systolic_4x4 #(
    parameter N  = 4,
    parameter AW = 8,
    parameter BW = 8,
    parameter CW = 32
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     vld_in,
    input  wire signed [AW-1:0]     a_in [0:N-1],    // Left edge, row 0..N-1
    input  wire signed [BW-1:0]     b_in [0:N-1],    // Top edge, col 0..N-1
    output wire signed [CW-1:0]     c_out [0:N-1][0:N-1]
);

    // A bus: a_bus[col_boundary][row]
    // Boundary 0 = left edge (driven by a_in); boundary N = right drain (unused)
    wire signed [AW-1:0] a_bus [0:N][0:N-1];

    // B bus: b_bus[row_boundary][col]
    // Boundary 0 = top edge (driven by b_in); boundary N = bottom drain (unused)
    wire signed [BW-1:0] b_bus [0:N][0:N-1];

    genvar i, j;

    // Connect external inputs to boundary 0
    generate
        for (i = 0; i < N; i = i + 1) begin : EDGE_A
            // a_bus[boundary=0][row=i] = left-edge input for row i
            assign a_bus[0][i] = a_in[i];
        end
        for (j = 0; j < N; j = j + 1) begin : EDGE_B
            // b_bus[boundary=0][col=j] = top-edge input for col j
            assign b_bus[0][j] = b_in[j];
        end
    endgenerate

    // Instantiate N×N PEs
    generate
        for (i = 0; i < N; i = i + 1) begin : PE_ROW    // i = row index
            for (j = 0; j < N; j = j + 1) begin : PE_COL // j = col index

                pe_mac #(.AW(AW), .BW(BW), .CW(CW)) U_PE (
                    .clk    (clk),
                    .rst    (rst),
                    .vld_in (vld_in),

                    // A flows left→right along row i
                    // Enters at column boundary j, exits at boundary j+1
                    .a_in   (a_bus[j][i]),       // A from left (boundary j, row i)
                    .a_out  (a_bus[j+1][i]),      // A to right (boundary j+1, row i)

                    // B flows top→bottom along column j
                    // Enters at row boundary i, exits at boundary i+1
                    .b_in   (b_bus[i][j]),        // B from above (boundary i, col j)
                    .b_out  (b_bus[i+1][j]),      // B downward (boundary i+1, col j)

                    // C: internal accumulator output = C[i][j]
                    .c_out  (c_out[i][j])
                );
            end
        end
    endgenerate

endmodule
