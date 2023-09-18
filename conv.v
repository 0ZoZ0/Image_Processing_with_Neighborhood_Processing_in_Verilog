`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/17/2023 08:35:17 PM
// Design Name: 
// Module Name: conv
// Project Name: Image Processing Using FPGA
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

/*
Assumptuons:
We have 3 line buffers which will send the data and at a time

*/


module conv(
    input i_clk, i_pixel_data_valid,
    input [71:0] i_pixel_data,
    
    output reg [7:0] o_convolved_data,
    output reg       o_convolved_data_valid
    );
    
    reg [7:0] kernel [8:0];         //kernel 3 X 3 matrix in which each value is represented in 8 btis
    reg [15:0] multiply_data [8:0]; //register to store the data after the kernel is multiplied to the pixel data
    reg [15:0] sumDataInt;          //register to hold the data as the adder part is combinational 
    reg [15:0] sumData;             //register to hold the final summed data sequentially
    reg multDataValid;              //pipelining signals to determie sum and multiply process is completed
    reg sumDataValid;
    

    
    //initializing kernel for box blurring
    initial
    begin : kernel_block
        integer i;
        for(i=0;i<9;i=i+1)
        begin
            kernel[i] = 1;
        end
    end
    
    
    /*
   
    //initializing kernel for edge detection
    initial
    begin
        kernel[0] = -1;
        kernel[1] = -1;    
        kernel[2] = -1;
        kernel[3] = -1;
        kernel[4] =  8;
        kernel[5] = -1;
        kernel[6] = -1;
        kernel[7] = -1;
        kernel[8] = -1;
    end
    */
    
    /*
    //initializing kernel for sharpening
    initial
    begin
        kernel[0] =  0;
        kernel[1] = -1;    
        kernel[2] =  0;
        kernel[3] = -1;
        kernel[4] =  5;
        kernel[5] = -1;
        kernel[6] =  0;
        kernel[7] = -1;
        kernel[8] =  0;
    end
    */
    
    //Multiplication
    always @(posedge i_clk)
    begin : multiplication_block
        integer i;
        for(i = 0; i<9;i=i+1)
        begin
            multiply_data[i] <= kernel[i]*i_pixel_data[i*8+:8];        
        end
        multDataValid <= i_pixel_data_valid;
    end    
    
    //Summation
    always @(*)
    begin : sum_data_comb
        integer i;
        sumDataInt = 0;
        for(i=0;i<9;i=i+1)
        begin
            sumDataInt = sumDataInt + multiply_data[i];
        end
    end

    always @(posedge i_clk)
    begin
        sumData <= sumDataInt;
        sumDataValid <= multDataValid;
    end
    
    //Divison
    always @(posedge i_clk)
    begin
        o_convolved_data <= sumData/9;
        o_convolved_data_valid <= sumDataValid;
    end
    
endmodule