`timescale 1ns / 1ps

// =====================================================================
//  CORE DESIGN: 4x4 Weight-Stationary Systolic Array
// =====================================================================
module ws_top #(
    parameter N      = 4,
    parameter DATA_W = 8,
    parameter ACC_W  = 20
)(
    input  wire                      clk,
    input  wire                      rst,
    input  wire                      start,
    input  wire [N*N*DATA_W-1:0]     A_flat,   // A(i,k) at index i*N+k
    input  wire [N*N*DATA_W-1:0]     B_flat,   // B(k,j) at index k*N+j
    output reg  [N*N*ACC_W-1:0]      C_flat,   // C(i,j) at index i*N+j
    output reg                       busy,
    output reg                       done,
    output reg  [7:0]                cycle,          // for waveform
    output wire [N*DATA_W-1:0]       a_west_dbg,     // for waveform
    output wire [N*ACC_W-1:0]        psum_south_dbg  // for waveform
);
    localparam IDLE = 2'd0, LOAD = 2'd1, RUN = 2'd2, FIN = 2'd3;
    reg [1:0] state;

    // Storage inside every PE(k,j)
    reg [DATA_W-1:0] weight [0:N-1][0:N-1];  // B number that never moves
    reg [DATA_W-1:0] a_reg  [0:N-1][0:N-1];  // A number passed to the right
    reg [ACC_W-1:0]  p_reg  [0:N-1][0:N-1];  // partial sum passed down

    // Skewed input from the left: row k gets A(i,k) at cycle i+k
    reg [N*DATA_W-1:0] a_west;
    integer ka, jb, kc, jc, idx, ci;     // separate loop counters for each block

    always @* begin
        a_west = {N*DATA_W{1'b0}};
        if (state == RUN) begin
            for (ka = 0; ka < N; ka = ka + 1) begin
                idx = $signed({1'b0, cycle}) - ka;
                if (idx >= 0 && idx < N)
                    a_west[ka*DATA_W +: DATA_W] = A_flat[(idx*N + ka)*DATA_W +: DATA_W];
            end
        end
    end

    // Sums falling out of the bottom row
    reg [N*ACC_W-1:0] psum_south;
    always @* begin
        for (jb = 0; jb < N; jb = jb + 1)
            psum_south[jb*ACC_W +: ACC_W] = p_reg[N-1][jb];
    end

    assign a_west_dbg     = a_west;
    assign psum_south_dbg = psum_south;

    // Everything that happens on a clock edge
    reg [DATA_W-1:0] a_in;
    reg [ACC_W-1:0]  p_in;

    always @(posedge clk) begin
        if (rst) begin
            state  <= IDLE;
            cycle  <= 0;
            busy   <= 0;
            done   <= 0;
            C_flat <= {N*N*ACC_W{1'b0}};
            for (kc = 0; kc < N; kc = kc + 1)
                for (jc = 0; jc < N; jc = jc + 1) begin
                    weight[kc][jc] <= 0;
                    a_reg[kc][jc]  <= 0;
                    p_reg[kc][jc]  <= 0;
                end
        end else begin

            // ----- The 16 PEs -----
            for (kc = 0; kc < N; kc = kc + 1) begin
                for (jc = 0; jc < N; jc = jc + 1) begin
                    if (state == LOAD) begin
                        weight[kc][jc] <= B_flat[(kc*N + jc)*DATA_W +: DATA_W];
                        a_reg[kc][jc]  <= 0;
                        p_reg[kc][jc]  <= 0;
                    end else begin
                        a_in = (jc == 0) ? a_west[kc*DATA_W +: DATA_W] : a_reg[kc][jc-1];
                        p_in = (kc == 0) ? {ACC_W{1'b0}}               : p_reg[kc-1][jc];
                        a_reg[kc][jc] <= a_in;                          // pass A right
                        p_reg[kc][jc] <= p_in + a_in * weight[kc][jc];  // multiply-add, send down
                    end
                end
            end

            // ----- Controller -----
            case (state)
                IDLE: if (start) begin
                    state  <= LOAD;
                    busy   <= 1;
                    done   <= 0;
                    cycle  <= 0;
                    C_flat <= {N*N*ACC_W{1'b0}};
                end

                LOAD: begin
                    state <= RUN;
                    cycle <= 0;
                end

                RUN: begin
                    for (jc = 0; jc < N; jc = jc + 1) begin
                        ci = $signed({1'b0, cycle}) - N - jc;
                        if (ci >= 0 && ci < N)
                            C_flat[(ci*N + jc)*ACC_W +: ACC_W] <= psum_south[jc*ACC_W +: ACC_W];
                    end
                    if (cycle == 3*N-2) state <= FIN;
                    else                cycle <= cycle + 1;
                end

                FIN: begin
                    busy  <= 0;
                    done  <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule


// =====================================================================
//  WRAPPER FOR THE FPGA BOARD: only 23 pins, matrices A and B built inside
//  btnC = reset, btnU = start, sw[3:0] = which C element to show
//  led[11:0] = shown value, led[14] = busy, led[15] = done