`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/17/2023 07:19:50 PM
// Design Name: 
// Module Name: linebuffer
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


/* Assumptions

Writing one pixel at a time from the DDR to line buffer
Image size is 512 X 512
Kernel Size 3 X 3
Each Pixel is 8 bits
Reading three pixels at a time

*/

module linebuffer(
    input i_clk, i_rst, i_data_valid, i_read_data,
    input [7:0] i_data,
    output [23 : 0] o_data
    );
    
    reg [7:0] line [511:0];   //memory where the data will be stored
    reg [8:0] write_pointer;  //it points to the location in the line buffer where data is to be stored
    reg [8:0] read_pointer;   //it points to the location in the line buffer from where data is to be read
    
    //logic for storing data at the location
    always @(posedge i_clk)
    begin
        if(i_data_valid)
            line [write_pointer] <= i_data; 
    end
    
    
    //logic for write pointer
    always @(posedge i_clk)
    begin
        if(i_rst)
            write_pointer <= 0;
        else if (i_data_valid)
            write_pointer <= write_pointer + 1;
    end
    
    //logic for reading data
    assign o_data = {line[read_pointer],line[read_pointer + 1], line[read_pointer + 2]};
    
    //logic for read pointer
    always @(posedge i_clk)
    begin
        if(i_rst)
            read_pointer <= 0;
        else if (i_read_data)
            read_pointer <= read_pointer + 1;
    end
    
endmodule