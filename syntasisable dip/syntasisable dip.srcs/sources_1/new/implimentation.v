`timescale 1ns / 1ps

module pe_dip #(
    parameter width = 8,
    parameter acc_width = 32
)(
    input wire clk,
    input wire rst,

    input wire newweightshift,
    input wire newinputopr,
    input wire multiplyresult,
    input wire adder_accumulator,

    input wire signed [width-1:0] datain,
    input wire signed [width-1:0] weightsin,

    input wire signed [acc_width-1:0] sumin,

    output wire signed [width-1:0] dataout,
    output wire signed [width-1:0] weightsout,

    output wire signed [acc_width-1:0] sumout
);

    
    reg signed [width-1:0] datareg;

    reg signed [width-1:0] weightreg;

    reg signed [(2*width)-1:0] productregis;

    reg signed [acc_width-1:0] accumreg;




    always @(posedge clk) begin

        if (rst) begin

            datareg      <= 0;
            weightreg    <= 0;
            productregis <= 0;
            accumreg     <= 0;

        end

        else begin

            
            if (newinputopr) begin
                datareg <= datain;
            end


            
            if (newweightshift) begin
                weightreg <= weightsin;
            end


           
            if (multiplyresult) begin
                productregis <= datareg * weightreg;
            end


            
            if (adder_accumulator) begin
                accumreg <= sumin + productregis;
            end

        end

    end


 
    assign dataout   = datareg;

    assign weightsout = weightreg;

    assign sumout    = accumreg;

endmodule


