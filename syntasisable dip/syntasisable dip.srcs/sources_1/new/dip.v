`timescale 1ns / 1ps

module dip #(
    parameter N = 4,
    parameter width = 8,
    parameter acc_width = 32
)(
    input wire clk,
    input wire rst,

  
    input wire newweightshift,

   
    input wire [N-1:0] newinputopr,
    input wire [N-1:0] multiplyresult,
    input wire [N-1:0] adder_accumulator,

    
    input wire [N*width-1:0] data_bus,

    input wire [N*N*width-1:0] weight_bus,

    // Initial partial sums for each column
    input wire [N*acc_width-1:0] sumin_bus,

    // Final output row
    output wire [N*acc_width-1:0] sumout_bus
);


    // ========================================
    // 1. INTERNAL MATRICES
    // ========================================

    wire signed [width-1:0] weightsm
        [0:N-1][0:N-1];

    wire signed [width-1:0] pweightsm
        [0:N-1][0:N-1];

    wire signed [width-1:0] weight_matrix
        [0:N-1][0:N-1];

    wire signed [width-1:0] data_matrix
        [0:N-1][0:N-1];

    wire signed [width-1:0] data_input_matrix
        [0:N-1][0:N-1];

    wire signed [acc_width-1:0] sum_matrix
        [0:N-1][0:N-1];

    wire signed [acc_width-1:0] sum_input_matrix
        [0:N-1][0:N-1];




    genvar i, j;

    generate

        for (i = 0; i < N; i = i + 1) begin : WEIGHT_ROW

            for (j = 0; j < N; j = j + 1) begin : WEIGHT_COL

                assign weightsm[i][j] =
                    weight_bus[(i*N+j)*width +: width];

            end

        end

    endgenerate



    generate

        for (i = 0; i < N; i = i + 1) begin : PERM_ROW

            for (j = 0; j < N; j = j + 1) begin : PERM_COL

                assign pweightsm[i][j] =
                    weightsm[(i+j)%N][j];

            end

        end

    endgenerate


    
    localparam IDX_WIDTH = (N <= 1) ? 1 : $clog2(N);

    reg [IDX_WIDTH-1:0] weight_row_idx;

   

    always @(posedge clk) begin

        if (rst) begin

            weight_row_idx <= N-1;

        end

        else if (newweightshift) begin

            if (weight_row_idx == 0)
                weight_row_idx <= N-1;

            else
                weight_row_idx <= weight_row_idx - 1'b1;

        end

    end


 

    generate

        for (i = 0; i < N; i = i + 1) begin : W_ROUTE_ROW

            for (j = 0; j < N; j = j + 1) begin : W_ROUTE_COL

                if (i == 0) begin

                    // Top row receives the external
                    // permuted weight stream.

                    assign weight_matrix[i][j] =
                        pweightsm[weight_row_idx][j];

                end

                else begin

                    // Weight propagation vertically.

                    assign weight_matrix[i][j] =
                        weight_matrix[i-1][j];

                end

            end

        end

    endgenerate

    generate

        for (i = 0; i < N; i = i + 1) begin : D_ROUTE_ROW

            for (j = 0; j < N; j = j + 1) begin : D_ROUTE_COL

                if (i == 0) begin

                    

                    assign data_input_matrix[i][j] =
                        data_bus[j*width +: width];

                end

                else begin

                  

                    assign data_input_matrix[i][j] =
                        data_matrix[i-1][(j+1)%N];

                end

            end

        end

    endgenerate


    generate

        for (i = 0; i < N; i = i + 1) begin : SUM_ROUTE_ROW

            for (j = 0; j < N; j = j + 1) begin : SUM_ROUTE_COL

                if (i == 0) begin

                    // Initial partial sum from external input.

                    assign sum_input_matrix[i][j] =
                        sumin_bus[j*acc_width +: acc_width];

                end

                else begin

                    // Partial sum propagation vertically.

                    assign sum_input_matrix[i][j] =
                        sum_matrix[i-1][j];

                end

            end

        end

    endgenerate


 

    generate

        for (i = 0; i < N; i = i + 1) begin : ROW

            for (j = 0; j < N; j = j + 1) begin : COLS

                pe_dip #(
                    .width(width),
                    .acc_width(acc_width)
                ) pe (

                    .clk(clk),
                    .rst(rst),

                    
                    .newweightshift(newweightshift),

                    
                    .newinputopr(newinputopr[i]),

                    .multiplyresult(multiplyresult[i]),

                    .adder_accumulator(adder_accumulator[i]),

                    
                    .datain(data_input_matrix[i][j]),

                    
                    .weightsin(weight_matrix[i][j]),

                    
                    .sumin(sum_input_matrix[i][j]),

                    
                    .dataout(data_matrix[i][j]),

                   
                    .weightsout(weight_matrix[i][j]),

                    
                    .sumout(sum_matrix[i][j])

                );

            end

        end

    endgenerate


  

    generate

        for (j = 0; j < N; j = j + 1) begin : OUTPUT_COL

            assign sumout_bus[j*acc_width +: acc_width] =
                sum_matrix[N-1][j];

        end

    endgenerate


endmodule