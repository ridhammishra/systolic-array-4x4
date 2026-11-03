`timescale 1ns/1ps

module versa_top #(parameter DEBOUNCE = 2_000_000)(   // 20 ms @ 100 MHz
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,
    input  wire        BTNC,
    input  wire [4:0]  SW,
    output wire [15:0] LED
);
    localparam ROWS = 4, COLS = 4, SUB = 2, DW = 8, PW = 24;
    localparam NSUB = ROWS/SUB;

    
    function signed [7:0] rom_A(input [4:0] i);
        case (i)
            // dense : [1 2 3 4; 5 6 7 8; 2 7 6 5; 4 1 8 3]
            5'd0: rom_A = 1;  5'd1: rom_A = 2;  5'd2: rom_A = 3;  5'd3: rom_A = 4;
            5'd4: rom_A = 5;  5'd5: rom_A = 6;  5'd6: rom_A = 7;  5'd7: rom_A = 8;
            5'd8: rom_A = 2;  5'd9: rom_A = 7;  5'd10: rom_A = 6; 5'd11: rom_A = 5;
            5'd12: rom_A = 4; 5'd13: rom_A = 1; 5'd14: rom_A = 8; 5'd15: rom_A = 3;
            // sparse : [1 0 0 4; 0 3 0 0; 2 0 0 5; 0 0 6 0]
            5'd16: rom_A = 1; 5'd19: rom_A = 4; 5'd21: rom_A = 3;
            5'd24: rom_A = 2; 5'd27: rom_A = 5; 5'd30: rom_A = 6;
            default: rom_A = 0;
        endcase
    endfunction

    // weights, position = r*4 + c  (sparse = condensed weights, a=2 b=3 c=4 d=5)
    function signed [7:0] rom_W(input [4:0] i);
        case (i)
            // dense : [1 0 5 7; 2 4 3 5; 7 1 3 0; 0 4 5 2]
            5'd0: rom_W = 1;  5'd1: rom_W = 0;  5'd2: rom_W = 5;  5'd3: rom_W = 7;
            5'd4: rom_W = 2;  5'd5: rom_W = 4;  5'd6: rom_W = 3;  5'd7: rom_W = 5;
            5'd8: rom_W = 7;  5'd9: rom_W = 1;  5'd10: rom_W = 3; 5'd11: rom_W = 0;
            5'd12: rom_W = 0; 5'd13: rom_W = 4; 5'd14: rom_W = 5; 5'd15: rom_W = 2;
            // sparse condensed : sub0 [a 0 0 0; 0 b 0 0], sub1 [c 0 0 0; d 0 0 0]
            5'd16: rom_W = 2; 5'd21: rom_W = 3; 5'd24: rom_W = 4; 5'd28: rom_W = 5;
            default: rom_W = 0;
        endcase
    endfunction

    // expected final matrix, position = row*4 + col
    function signed [7:0] rom_E(input [4:0] i);
        case (i)
            5'd0: rom_E = 26;  5'd1: rom_E = 27;  5'd2: rom_E = 40;   5'd3: rom_E = 25;
            5'd4: rom_E = 66;  5'd5: rom_E = 63;  5'd6: rom_E = 104;  5'd7: rom_E = 81;
            5'd8: rom_E = 58;  5'd9: rom_E = 54;  5'd10: rom_E = 74;  5'd11: rom_E = 59;
            5'd12: rom_E = 62; 5'd13: rom_E = 24; 5'd14: rom_E = 62;  5'd15: rom_E = 39;
            // sparse : [0 22 0 0; 0 0 0 9; 0 29 0 0; 0 24 0 0]
            5'd17: rom_E = 22; 5'd23: rom_E = 9; 5'd25: rom_E = 29; 5'd29: rom_E = 24;
            default: rom_E = 0;
        endcase
    endfunction

    // original column index of each condensed column (sparse), i = s*4 + c
    function [2:0] rom_I(input [2:0] i);
        case (i)
            3'd0: rom_I = 1;   // sub0, cond col0 -> original col1
            3'd1: rom_I = 3;   // sub0, cond col1 -> original col3
            3'd4: rom_I = 1;   // sub1, cond col0 -> original col1
            default: rom_I = 0;
        endcase
    endfunction

    
    // Reset synchroniser (CPU_RESETN is active low)
  
    reg [1:0] rs = 2'b11;
    always @(posedge CLK100MHZ) rs <= {rs[0], ~CPU_RESETN};
    wire rst = rs[1];

    
    // Button synchroniser + debouncer + edge detect
   
    reg [1:0]  bs      = 2'b00;
    reg        bstable = 1'b0;
    reg        bprev   = 1'b0;
    reg [21:0] bcnt    = 22'd0;
    always @(posedge CLK100MHZ) begin
        bs    <= {bs[0], BTNC};
        bprev <= bstable;
        if (bs[1] == bstable) bcnt <= 0;
        else begin
            bcnt <= bcnt + 1'b1;
            if (bcnt == DEBOUNCE-1) begin
                bstable <= bs[1];
                bcnt    <= 0;
            end
        end
    end
    wire start = bstable & ~bprev;

   
    // Control FSM
   
    localparam S_IDLE = 3'd0, S_CLR = 3'd1, S_LOAD = 3'd2, S_RUN = 3'd3, S_DONE = 3'd4;
    reg [2:0] state  = S_IDLE;
    reg       mode_q = 1'b0;
    reg [4:0] n      = 5'd0;               // cycle counter during RUN

    wire core_rst = rst | (state == S_CLR);
    wire load_w   = (state == S_LOAD);

    wire [ROWS*COLS*DW-1:0]      w_flat;
    wire [ROWS*DW-1:0]           a_in_flat;
    wire [NSUB*COLS*PW-1:0]      sub_out_flat;

    //  weights from ROM
    genvar gr, gc;
    generate
        for (gr = 0; gr < ROWS; gr = gr + 1) begin : G_W_R
            for (gc = 0; gc < COLS; gc = gc + 1) begin : G_W_C
                localparam [3:0] WI = gr*4 + gc;
                assign w_flat[(gr*COLS+gc)*DW +: DW] = rom_W({mode_q, WI});
            end
        end
    endgenerate

    //  skewed inputs from ROM
    //   dense : row r starts after r + r/SUB cycles   (1 extra cycle per IPB)
    //   sparse: row r starts after r % SUB cycles     (subarrays start together)
    generate
        for (gr = 0; gr < ROWS; gr = gr + 1) begin : G_A
            localparam       D_DENSE  = gr + gr/SUB;
            localparam       D_SPARSE = gr % SUB;
            localparam [1:0] RR       = gr;
            wire signed [7:0] tr = mode_q ? ($signed({3'b000, n}) - D_SPARSE)
                                          : ($signed({3'b000, n}) - D_DENSE);
            wire valid = (state == S_RUN) && (tr >= 0) && (tr < 4);
            assign a_in_flat[gr*DW +: DW] = valid ? rom_A({mode_q, tr[1:0], RR}) : 8'sd0;
        end
    endgenerate

    // the VerSA core
    versa #(.ROWS(ROWS), .COLS(COLS), .SUB(SUB), .DW(DW), .PW(PW)) u_versa (
        .clk(CLK100MHZ), .rst(core_rst), .mode(mode_q), .load_w(load_w),
        .w_flat(w_flat), .a_in_flat(a_in_flat), .sub_out_flat(sub_out_flat)
    );

    // capture outputs (same timing as the simulation testbench)
    reg [32*PW-1:0] Pf = 0;                 // P[s*16 + t*4 + c]
    integer ct, cc, cs;
    always @(posedge CLK100MHZ) begin
        if (rst) begin
            state  <= S_IDLE;
            n      <= 5'd0;
            mode_q <= 1'b0;
        end else begin
            case (state)
                S_IDLE, S_DONE: begin
                    if (start) begin
                        mode_q <= SW[0];
                        state  <= S_CLR;
                    end
                end
                S_CLR: begin
                    Pf    <= 0;
                    state <= S_LOAD;
                end
                S_LOAD: begin
                    n     <= 5'd0;
                    state <= S_RUN;
                end
                S_RUN: begin
                    for (cc = 0; cc < COLS; cc = cc + 1) begin
                        if (!mode_q) begin                        // dense: last subarray
                            ct = $signed({1'b0, n}) - 5 - cc;
                            if (ct >= 0 && ct < 4)
                                Pf[(ct*4+cc)*PW +: PW] <= sub_out_flat[((NSUB-1)*COLS+cc)*PW +: PW];
                        end else begin                            // sparse: every subarray
                            ct = $signed({1'b0, n}) - SUB - cc;
                            for (cs = 0; cs < NSUB; cs = cs + 1)
                                if (ct >= 0 && ct < 4)
                                    Pf[(cs*16+ct*4+cc)*PW +: PW] <= sub_out_flat[(cs*COLS+cc)*PW +: PW];
                        end
                    end
                    n <= n + 1'b1;
                    if (n == 5'd19) state <= S_DONE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

    
    // Post-processing (column restoration + addition) and check
   
    reg [16*PW-1:0] cf;
    reg             match;
    reg [PW-1:0]    acc;
    integer pt, pcol, ps, pc;
    always @* begin
        cf    = 0;
        match = 1'b1;
        for (pt = 0; pt < 4; pt = pt + 1)
            for (pcol = 0; pcol < 4; pcol = pcol + 1) begin
                acc = 0;
                if (!mode_q) begin
                    acc = Pf[(pt*4+pcol)*PW +: PW];
                end else begin
                    for (ps = 0; ps < NSUB; ps = ps + 1)
                        for (pc = 0; pc < COLS; pc = pc + 1)
                            if (rom_I(ps*4+pc) == pcol)
                                acc = acc + Pf[(ps*16+pt*4+pc)*PW +: PW];
                end
                cf[(pt*4+pcol)*PW +: PW] = acc;
                if ($signed(acc) != rom_E({mode_q, pt[1:0], pcol[1:0]})) match = 1'b0;
            end
    end

    
    // LEDs
  
    wire       done  = (state == S_DONE);
    wire [7:0] shown = cf[SW[4:1]*PW +: 8];

    assign LED[0]    = done;
    assign LED[1]    = done &  match;
    assign LED[2]    = done & ~match;
    assign LED[3]    = mode_q;
    assign LED[6:4]  = state;
    assign LED[7]    = 1'b0;
    assign LED[15:8] = done ? shown : 8'd0;
endmodule