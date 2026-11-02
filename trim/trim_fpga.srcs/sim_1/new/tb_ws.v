`timescale 1ns / 1ps
module tb_ws;
    localparam N = 4, DATA_W = 8, ACC_W = 20;

    reg  clk = 0, rst = 1, start = 0;
    reg  [N*N*DATA_W-1:0] A_flat, B_flat;
    wire [N*N*ACC_W-1:0]  C_flat;
    wire busy, done;
    wire [7:0] cycle;
    wire [N*DATA_W-1:0] a_west_dbg;
    wire [N*ACC_W-1:0]  psum_south_dbg;

    ws_top #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) uut (
        .clk(clk), .rst(rst), .start(start),
        .A_flat(A_flat), .B_flat(B_flat),
        .C_flat(C_flat), .busy(busy), .done(done), .cycle(cycle),
        .a_west_dbg(a_west_dbg), .psum_south_dbg(psum_south_dbg)
    );

    always #5 clk = ~clk;      // 100 MHz clock

    // Easy-to-read signals for the waveform
    wire [DATA_W-1:0] a_row0 = a_west_dbg[0*DATA_W +: DATA_W];
    wire [DATA_W-1:0] a_row1 = a_west_dbg[1*DATA_W +: DATA_W];
    wire [DATA_W-1:0] a_row2 = a_west_dbg[2*DATA_W +: DATA_W];
    wire [DATA_W-1:0] a_row3 = a_west_dbg[3*DATA_W +: DATA_W];
    wire [ACC_W-1:0]  out_col0 = psum_south_dbg[0*ACC_W +: ACC_W];
    wire [ACC_W-1:0]  out_col1 = psum_south_dbg[1*ACC_W +: ACC_W];
    wire [ACC_W-1:0]  out_col2 = psum_south_dbg[2*ACC_W +: ACC_W];
    wire [ACC_W-1:0]  out_col3 = psum_south_dbg[3*ACC_W +: ACC_W];

    integer i, j, k, errors, expected, got;
    integer Bv [0:15];

    initial begin
        // ---- Matrix A = 1..16 (row by row) ----
        for (i = 0; i < N; i = i + 1)
            for (k = 0; k < N; k = k + 1)
                A_flat[(i*N + k)*DATA_W +: DATA_W] = i*N + k + 1;

        // ---- Matrix B (change these numbers to try your own, keep each <= 255) ----
        Bv[0]=1;  Bv[1]=2;  Bv[2]=1;  Bv[3]=2;
        Bv[4]=2;  Bv[5]=1;  Bv[6]=2;  Bv[7]=1;
        Bv[8]=1;  Bv[9]=1;  Bv[10]=1; Bv[11]=1;
        Bv[12]=3; Bv[13]=2; Bv[14]=1; Bv[15]=0;
        for (k = 0; k < N; k = k + 1)
            for (j = 0; j < N; j = j + 1)
                B_flat[(k*N + j)*DATA_W +: DATA_W] = Bv[k*N + j];

        errors = 0;
        #20 rst = 0;
        #20 start = 1;
        #10 start = 0;

        wait (done);
        @(posedge clk); #1;

        $display("");
        $display("=========== RESULT C = A x B ===========");
        for (i = 0; i < N; i = i + 1) begin
            $write("| ");
            for (j = 0; j < N; j = j + 1)
                $write("%5d ", C_flat[(i*N + j)*ACC_W +: ACC_W]);
            $write("|\n");
        end

        // Self-check against normal matrix multiplication
        for (i = 0; i < N; i = i + 1)
            for (j = 0; j < N; j = j + 1) begin
                expected = 0;
                for (k = 0; k < N; k = k + 1)
                    expected = expected + A_flat[(i*N + k)*DATA_W +: DATA_W]
                                        * B_flat[(k*N + j)*DATA_W +: DATA_W];
                got = C_flat[(i*N + j)*ACC_W +: ACC_W];
                if (got !== expected) begin
                    errors = errors + 1;
                    $display("MISMATCH C[%0d][%0d]: got %0d, expected %0d", i, j, got, expected);
                end
            end

        if (errors == 0) $display(">>> PASS: all 16 results are correct <<<");
        else             $display(">>> FAIL: %0d wrong results <<<", errors);
        $finish;
    end

    initial begin               // safety stop
        #5000;
        $display("TIMEOUT");
        $finish;
    end
endmodule
