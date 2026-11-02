
`timescale 1ns / 1ps

module nexys_a7_top (
    input  wire        CLK100MHZ,
    input  wire        btnC,
    input  wire        btnU,
    input  wire [3:0]  sw,
    output wire [15:0] led
);

    localparam N      = 4;
    localparam DATA_W = 8;
    localparam ACC_W  = 20;

    // -------------------------------------------------
    // Matrix A = 1 to 16
    // -------------------------------------------------
    localparam [N*N*DATA_W-1:0] A_FLAT = {
        8'd16, 8'd15, 8'd14, 8'd13,
        8'd12, 8'd11, 8'd10, 8'd9,
        8'd8,  8'd7,  8'd6,  8'd5,
        8'd4,  8'd3,  8'd2,  8'd1
    };

    // -------------------------------------------------
    // Matrix B
    // -------------------------------------------------
    localparam [N*N*DATA_W-1:0] B_FLAT = {
        8'd0, 8'd1, 8'd2, 8'd3,
        8'd1, 8'd1, 8'd1, 8'd1,
        8'd1, 8'd2, 8'd1, 8'd2,
        8'd2, 8'd1, 8'd2, 8'd1
    };

    // -------------------------------------------------
    // Button synchronization
    // -------------------------------------------------
    reg [1:0] rst_sync   = 2'b00;
    reg [1:0] start_sync = 2'b00;
    reg       start_prev = 1'b0;

    always @(posedge CLK100MHZ) begin
        rst_sync   <= {rst_sync[0], btnC};
        start_sync <= {start_sync[0], btnU};
        start_prev <= start_sync[1];
    end

    wire rst   = rst_sync[1];
    wire start = start_sync[1] & ~start_prev;

    // -------------------------------------------------
    // Core signals
    // -------------------------------------------------
    wire [N*N*ACC_W-1:0] C_flat;
    wire busy;
    wire done;

    // -------------------------------------------------
    // Systolic array instance
    // -------------------------------------------------
    ws_top #(
        .N(N),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) systolic_core (
        .clk(CLK100MHZ),
        .rst(rst),
        .start(start),

        .A_flat(A_FLAT),
        .B_flat(B_FLAT),

        .C_flat(C_flat),

        .busy(busy),
        .done(done),

        .cycle(),
        .a_west_dbg(),
        .psum_south_dbg()
    );

    // -------------------------------------------------
    // Select output element using switches
    // sw = 0  -> C[0][0]
    // sw = 1  -> C[0][1]
    // ...
    // sw = 15 -> C[3][3]
    // -------------------------------------------------
    wire [ACC_W-1:0] selected_result;

    assign selected_result = C_flat[sw * ACC_W +: ACC_W];

    // -------------------------------------------------
    // LED display
    // -------------------------------------------------
    assign led[11:0]  = selected_result[11:0];
    assign led[13:12] = 2'b00;
    assign led[14]    = busy;
    assign led[15]    = done;

endmodule
