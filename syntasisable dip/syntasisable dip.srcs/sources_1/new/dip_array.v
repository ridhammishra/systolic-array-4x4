`timescale 1ns / 1ps


module dip_array#(
    parameter N = 4,
    parameter width = 8,
    parameter acc_width = 32
    )(
    input wire clk,
    input wire rst,
    input wire [N*width-1:0] data_bus,
    input wire [N*N*width-1:0] weight_bus,
    
   
    input wire newweightshift,
    input wire[N-1:0] newinputopr,
    input wire [N-1:0] multiplyresult,
    input wire[N-1:0] adder_accumulator 
    );
    
    
    wire signed [width-1:0] data_wire [0:N-1][0:N-1];//data carrying wires between PE's
    
    wire signed [width-1:0] weight_wire [0:N-1][0:N-1]; //connectin among PEs
    wire signed [acc_width-1:0] sum_wire [0:N-1][0:N-1]; 
    wire signed [width-1:0] input_data [0:N-1];
    
    
    genvar i;
    
    generate 
        for(i = 0 ; i <N; i = i+1 )begin: INPUT_SPLIT
        
            assign input_data[i] = data_bus[width*(N-i)-1 -: width ]; 
        end
    endgenerate   
    
    
    
    
    wire signed [width-1:0] weigth_matrix [0:N-1][0:N-1]; //those who will bring weight data
    
    wire signed [width-1:0] permuted_weights [0:N-1][0:N-1]; //stores permuted matrix data
    
    
    genvar r,c;
        generate
            for(r =0 ;r<N;r = r+1) begin: weightrows
            
                for (c = 0 ;c<N; c= c+1) begin:weightcols 
                
                    assign weigth_matrix[r][c] = weight_bus[(r*N+c)*width +:width];
                    
                    
                    assign permuted_weights[r][c]=
                        weigth_matrix[(r+c)%N][c];
                        
                   
                end
                
            end
        endgenerate  
            
endmodule
