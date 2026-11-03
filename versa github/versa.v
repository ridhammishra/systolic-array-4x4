`timescale 1ns/1ps
//============================================================
// VerSA (simple version) - Versatile Systolic Array
// Weight-stationary systolic array split into SUBARRAYS.
// Between subarrays there is an IPB (register + MUX).
//   mode = 0 : DENSE  -> IPB passes partial sum to next subarray
//   mode = 1 : SPARSE -> IPB feeds ZERO, each subarray works alone
//============================================================

// ---------------- Processing Element (MAC) ----------------
module pe #(parameter DW = 8, parameter PW = 24)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 load_w,          // load weight
    input  wire signed [DW-1:0] w_in,
    input  wire signed [DW-1:0] a_in,            // input activation
    input  wire signed [PW-1:0] psum_in,         // partial sum from top
    output reg  signed [DW-1:0] a_out,           // activation to right
    output reg  signed [PW-1:0] psum_out         // partial sum to bottom
);
    reg signed [DW-1:0] w;
    always @(posedge clk) begin
        if (rst) begin
            w <= 0; a_out <= 0; psum_out <= 0;
        end else begin
            if (load_w) w <= w_in;
            a_out    <= a_in;
            psum_out <= psum_in + a_in * w;      // MAC
        end
    end
endmodule

// ---------------- VerSA top ----------------
module versa #(
    parameter ROWS = 4,      // total rows in SA
    parameter COLS = 4,      // total columns in SA
    parameter SUB  = 2,      // rows per subarray
    parameter DW   = 8,
    parameter PW   = 24
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     mode,        // 0 = dense, 1 = sparse
    input  wire                     load_w,      // 1 cycle pulse: load weights
    input  wire [ROWS*COLS*DW-1:0]  w_flat,      // weight of PE(r,c) at [(r*COLS+c)*DW +: DW]
    input  wire [ROWS*DW-1:0]       a_in_flat,   // one input per row
    output wire [(ROWS/SUB)*COLS*PW-1:0] sub_out_flat // output of each subarray (last row)
);
    localparam NSUB = ROWS/SUB;

    wire [ROWS*(COLS+1)*DW-1:0] a_bus;           // activation wires
    wire [ROWS*COLS*PW-1:0]     p_bus;           // psum output of every PE
    reg  [NSUB*COLS*PW-1:0]     ipb_reg;         // IPB buffer registers (index 0 unused)

    genvar r, c, s;

    // ---- activation input to column 0 of each row
    generate
        for (r = 0; r < ROWS; r = r + 1) begin : G_AIN
            assign a_bus[(r*(COLS+1))*DW +: DW] = a_in_flat[r*DW +: DW];
        end
    endgenerate

    // ---- PE array
    generate
        for (r = 0; r < ROWS; r = r + 1) begin : G_ROW
            for (c = 0; c < COLS; c = c + 1) begin : G_COL
                wire [PW-1:0] psum_in;
                if (r == 0)
                    assign psum_in = {PW{1'b0}};
                else if (r % SUB == 0)           // first row of a subarray -> via IPB MUX
                    assign psum_in = mode ? {PW{1'b0}} : ipb_reg[((r/SUB)*COLS + c)*PW +: PW];
                else                              // inside a subarray
                    assign psum_in = p_bus[((r-1)*COLS + c)*PW +: PW];

                pe #(.DW(DW), .PW(PW)) u_pe (
                    .clk(clk), .rst(rst), .load_w(load_w),
                    .w_in   (w_flat[(r*COLS+c)*DW +: DW]),
                    .a_in   (a_bus[(r*(COLS+1)+c)*DW +: DW]),
                    .psum_in(psum_in),
                    .a_out  (a_bus[(r*(COLS+1)+c+1)*DW +: DW]),
                    .psum_out(p_bus[(r*COLS+c)*PW +: PW])
                );
            end
        end
    endgenerate

    // ---- IPB registers (1 clock delay) : capture last row of subarray s-1
    generate
        for (s = 1; s < NSUB; s = s + 1) begin : G_IPB
            for (c = 0; c < COLS; c = c + 1) begin : G_IC
                always @(posedge clk) begin
                    if (rst) ipb_reg[(s*COLS+c)*PW +: PW] <= 0;
                    else     ipb_reg[(s*COLS+c)*PW +: PW] <= p_bus[((s*SUB-1)*COLS + c)*PW +: PW];
                end
            end
        end
    endgenerate

    // ---- outputs: last row of every subarray
    generate
        for (s = 0; s < NSUB; s = s + 1) begin : G_OUT
            for (c = 0; c < COLS; c = c + 1) begin : G_OC
                assign sub_out_flat[(s*COLS+c)*PW +: PW] = p_bus[((s*SUB+SUB-1)*COLS + c)*PW +: PW];
            end
        end
    endgenerate
endmodule
