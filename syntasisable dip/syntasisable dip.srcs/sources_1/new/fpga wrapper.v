`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////


module dip_fpga_top (

    input wire CLK100MHZ,

    input wire BTNC,

    output wire [3:0] LED

);


    localparam N = 4;
    localparam WIDTH = 8;
    localparam ACC_WIDTH = 32;


    

    wire [N*ACC_WIDTH-1:0] sumin_bus;
    wire [N*ACC_WIDTH-1:0] sumout_bus;

    wire [N*WIDTH-1:0] data_bus;

    wire [N*N*WIDTH-1:0] weight_bus;


    

    wire newweightshift;

    wire [N-1:0] newinputopr;
    wire [N-1:0] multiplyresult;
    wire [N-1:0] adder_accumulator;


  

    assign newweightshift = 1'b0;

    assign newinputopr = 4'b0000;

    assign multiplyresult = 4'b0000;

    assign adder_accumulator = 4'b0000;


    
    assign data_bus = 32'h04030201;


    
    assign weight_bus =
        128'h01000000010000000100000001000000;


   
    assign sumin_bus = 128'd0;



    dip #(

        .N(N),
        .width(WIDTH),
        .acc_width(ACC_WIDTH)

    ) DUT (

        .clk(CLK100MHZ),

        .rst(BTNC),

        .newweightshift(newweightshift),

        .newinputopr(newinputopr),

        .multiplyresult(multiplyresult),

        .adder_accumulator(adder_accumulator),

        .data_bus(data_bus),

        .weight_bus(weight_bus),

        .sumin_bus(sumin_bus),

        .sumout_bus(sumout_bus)

    );



    assign LED = sumout_bus[3:0];


endmodule
