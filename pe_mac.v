// =============================================================================
// FILE: pe_mac.v
// DESCRIPTION: Processing Element with INTERNAL accumulator.
//
// Operation each clock (when vld_in=1 and not rst):
//   1. acc <= acc + a_in * b_in   (internal running sum, never leaves PE)
//   2. a_out <= a_in              (pass A to the right neighbor, 1-cycle delay)
//   3. b_out <= b_in              (pass B to the bottom neighbor, 1-cycle delay)
//
// c_out is always the current value of the internal acc register.
// It is VALID after exactly N=4 MAC operations have been performed.
//
// A 'clear' input resets acc to 0 for the next matrix tile computation.
// =============================================================================

module pe_mac #(
    parameter AW = 8,    // Width of A elements
    parameter BW = 8,    // Width of B elements
    parameter CW = 32    // Width of accumulator (must be large enough to avoid overflow)
)(
    input  wire                   clk,      // Rising-edge clock
    input  wire                   rst,      // Synchronous reset: clears everything to 0
    input  wire                   vld_in,   // Enable: compute and forward only when HIGH

    input  wire signed [AW-1:0]   a_in,     // A value arriving from the LEFT
    input  wire signed [BW-1:0]   b_in,     // B value arriving from ABOVE

    output reg  signed [AW-1:0]   a_out,    // A forwarded to the RIGHT neighbor
    output reg  signed [BW-1:0]   b_out,    // B forwarded to the BOTTOM neighbor
    output wire signed [CW-1:0]   c_out     // Current accumulated result (C matrix element)
);

    // -------------------------------------------------------------------------
    // Internal accumulation register — holds the running partial sum
    // -------------------------------------------------------------------------
    reg signed [CW-1:0] acc;

    // Expose internal accumulator as output
    assign c_out = acc;

    always @(posedge clk) begin
        if (rst) begin
            // Synchronous reset: zero all registers
            acc   <= {CW{1'b0}};  // Clear accumulator
            a_out <= {AW{1'b0}};  // Clear A pass-through register
            b_out <= {BW{1'b0}};  // Clear B pass-through register
        end
        else if (vld_in) begin
            // Multiply-accumulate: add product of current inputs to running sum
            // $signed cast ensures signed 2's-complement multiplication
            // This operation maps to a single DSP48 slice on Xilinx FPGAs
            acc <= acc + $signed(a_in) * $signed(b_in);

            // Registered pass-through: A moves right, B moves down
            // The 1-cycle register here IS the systolic pipeline stage
            a_out <= a_in;
            b_out <= b_in;
        end
        // When vld_in=0: all registers hold their current values (implicit)
    end

endmodule
