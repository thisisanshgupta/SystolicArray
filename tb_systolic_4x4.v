// =============================================================================
// FILE: tb_systolic_4x4.v
// TESTBENCH: 4×4 Systolic Array
//
// TEST: A × Identity(4×4) = A
//   A = [[ 1  2  3  4]
//        [ 5  6  7  8]
//        [ 9 10 11 12]
//        [13 14 15 16]]
//
// STAGGERING:
//   At feed cycle c (0-indexed):
//     a_in[i] = A[i][c-i]  if 0 <= (c-i) < N, else 0
//     b_in[j] = B[c-j][j]  if 0 <= (c-j) < N, else 0
//
// TIMING TO VALID OUTPUT:
//   Feed window  = 2*N - 1 = 7 cycles  (diagonal wavefront)
//   Each element passes through j+1 PE registers before its acc is correct.
//   PE[i][j] accumulates over N=4 steps; its last product arrives at cycle
//   (i + j + N - 1) = i+j+3.  With 1 register in PE, result valid at i+j+4.
//   Worst case: PE[3][3]: valid at 3+3+4 = 10 cycles after feed start.
//   We sample at cycle 12 (feed_start + 12) to be safe.
// =============================================================================

`timescale 1ns/1ps

module tb_systolic_4x4;

    localparam N   = 4;
    localparam AW  = 8;
    localparam BW  = 8;
    localparam CW  = 32;
    localparam CLK = 10;  // ns

    // ---- DUT ports ----
    reg  clk, rst, vld_in;
    reg  signed [AW-1:0] a_in [0:N-1];
    reg  signed [BW-1:0] b_in [0:N-1];
    wire signed [CW-1:0] c_out [0:N-1][0:N-1];

    // ---- Clock ----
    initial clk = 0;
    always #(CLK/2) clk = ~clk;

    // ---- DUT ----
    systolic_4x4 #(.N(N),.AW(AW),.BW(BW),.CW(CW)) DUT (
        .clk(clk), .rst(rst), .vld_in(vld_in),
        .a_in(a_in), .b_in(b_in), .c_out(c_out)
    );

    // ---- Test data ----
    reg signed [AW-1:0] A [0:N-1][0:N-1];
    reg signed [BW-1:0] B [0:N-1][0:N-1];
    reg signed [CW-1:0] expected [0:N-1][0:N-1];
    integer ii, jj, kk, cyc;
    integer pass_count, fail_count;

    initial begin
        // --- Build A ---
        A[0][0]=1;  A[0][1]=2;  A[0][2]=3;  A[0][3]=4;
        A[1][0]=5;  A[1][1]=6;  A[1][2]=7;  A[1][3]=8;
        A[2][0]=9;  A[2][1]=10; A[2][2]=11; A[2][3]=12;
        A[3][0]=13; A[3][1]=14; A[3][2]=15; A[3][3]=16;

        // --- Build B = Identity ---
        for (ii=0;ii<N;ii=ii+1)
          for (jj=0;jj<N;jj=jj+1)
            B[ii][jj] = (ii==jj) ? 1 : 0;

        // --- Golden model: expected = A × B = A ---
        for (ii=0;ii<N;ii=ii+1)
          for (jj=0;jj<N;jj=jj+1) begin
            expected[ii][jj] = 0;
            for (kk=0;kk<N;kk=kk+1)
              expected[ii][jj] = expected[ii][jj] + A[ii][kk]*B[kk][jj];
          end

        // --- Reset ---
        rst=1; vld_in=0;
        for (ii=0;ii<N;ii=ii+1) begin a_in[ii]=0; b_in[ii]=0; end
        repeat(3) @(posedge clk); #1;
        rst=0;

        // --- Feed staggered inputs for 2*N-1 = 7 cycles ---
        vld_in=1;
        $display("\n=== STAGGERED FEED (cycles 0..%0d) ===", 2*N-2);
        for (cyc=0; cyc < 2*N-1; cyc=cyc+1) begin
            for (ii=0;ii<N;ii=ii+1)
                a_in[ii] = (cyc>=ii && (cyc-ii)<N) ? A[ii][cyc-ii] : 0;
            for (jj=0;jj<N;jj=jj+1)
                b_in[jj] = (cyc>=jj && (cyc-jj)<N) ? B[cyc-jj][jj] : 0;
            $display("  cyc=%0d  A_in=[%2d %2d %2d %2d]  B_in=[%2d %2d %2d %2d]",
                cyc, a_in[0],a_in[1],a_in[2],a_in[3],
                     b_in[0],b_in[1],b_in[2],b_in[3]);
            @(posedge clk); #1;
        end

        // --- Drain: send zeros, wait for pipeline to complete ---
        for (ii=0;ii<N;ii=ii+1) begin a_in[ii]=0; b_in[ii]=0; end
        // Wait enough cycles: worst-case PE[3][3] finishes at feed_cycle 6+3=9+pipeline
        repeat(2*N) @(posedge clk); #1;
        vld_in=0;
        @(posedge clk); #1;

        // --- Display raw c_out for debug ---
        $display("\n=== C_OUT (raw, after drain) ===");
        for (ii=0;ii<N;ii=ii+1)
          $display("  row%0d: [%4d %4d %4d %4d]",
            ii, c_out[ii][0],c_out[ii][1],c_out[ii][2],c_out[ii][3]);

        $display("\n=== EXPECTED ===");
        for (ii=0;ii<N;ii=ii+1)
          $display("  row%0d: [%4d %4d %4d %4d]",
            ii, expected[ii][0],expected[ii][1],expected[ii][2],expected[ii][3]);

        // --- Verify ---
        pass_count=0; fail_count=0;
        $display("\n=== VERIFICATION ===");
        for (ii=0;ii<N;ii=ii+1)
          for (jj=0;jj<N;jj=jj+1)
            if (c_out[ii][jj] === expected[ii][jj]) begin
              $display("  C[%0d][%0d] = %4d  PASS", ii,jj,c_out[ii][jj]);
              pass_count = pass_count+1;
            end else begin
              $display("  C[%0d][%0d] = %4d  EXPECTED %4d  *** FAIL ***",
                ii,jj,c_out[ii][jj],expected[ii][jj]);
              fail_count = fail_count+1;
            end

        $display("\n%0d PASSED, %0d FAILED", pass_count, fail_count);
        $finish;
    end

    // Watchdog
    initial begin
        #(CLK*300);
        $display("TIMEOUT"); $finish;
    end

    initial begin
        $dumpfile("systolic_4x4.vcd");
        $dumpvars(0, tb_systolic_4x4);
    end

endmodule
