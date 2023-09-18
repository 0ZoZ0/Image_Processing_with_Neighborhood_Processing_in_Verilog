`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/17/2023 11:18:15 PM
// Design Name: 
// Module Name: control
// Project Name: 
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

Assumptions:

Getting stream of data from external world and storing it in line buffer and sending stream of data as output for the multiplier 

Instantiating 4 line bufferes: At a time processing data in three of them and stroing the next stream of data in the 4th line buffer

*/


module control(
    input i_clk, i_rst, i_pixel_data_valid,
    input [7:0] i_pixel_data,
    
    output reg [71:0] o_pixel_data,
    output            o_pixel_data_valid,
    output reg        o_intr
    );
    
 linebuffer l1(
    .i_clk(i_clk), .i_rst(i_rst), .i_data_valid(linebuffer_valid[0]), .i_read_data(read_linebuffer_valid[0]), .i_data(i_pixel_data), .o_data(lb1_data)
    );   
    
 linebuffer l2(
    .i_clk(i_clk), .i_rst(i_rst), .i_data_valid(linebuffer_valid[1]), .i_read_data(read_linebuffer_valid[1]), .i_data(i_pixel_data), .o_data(lb2_data)
    );      
    
 linebuffer l3(
    .i_clk(i_clk), .i_rst(i_rst), .i_data_valid(linebuffer_valid[2]), .i_read_data(read_linebuffer_valid[2]), .i_data(i_pixel_data), .o_data(lb3_data)
    );
    
 linebuffer l4(
    .i_clk(i_clk), .i_rst(i_rst), .i_data_valid(linebuffer_valid[3]), .i_read_data(read_linebuffer_valid[3]), .i_data(i_pixel_data), .o_data(lb4_data)
    );  
    
    
    
    // Logic to select in which line buffer data is to be written for that a counter is used

    reg [8:0] pixel_counter;       //as the image size is 512 X 512 it will change the line buffer after it has received 512 datas for that log2(512)..9 bits required
    reg [1:0] current_linebuffer;  //reg which will tell us in which line buffer to write
    reg [3:0] linebuffer_valid;    //reg which contains the valid signals for the line buffer 
    
    always @(posedge i_clk)
    begin
    
        if(i_rst)
            pixel_counter <= 0;
        else
        begin
            if(i_pixel_data_valid)
                pixel_counter <= pixel_counter + 1;
        end
    end
    
    always @(posedge i_clk)
    begin
        if(i_rst)
            current_linebuffer <= 0;
        else if(pixel_counter == 511 && i_pixel_data_valid)
        begin
            current_linebuffer <= current_linebuffer + 1;
        end    
    
    end
    
    always @(*)
    begin
        linebuffer_valid = 0;
        linebuffer_valid[current_linebuffer] = i_pixel_data_valid;
    end
    
    
    // Logic to select from which line buffer data is to be read
    
    reg [1:0] currentreadlinebuffer;                    //reg which will tells us from which line buffer to read
    wire [23:0] lb1_data,lb2_data, lb3_data, lb4_data;  //output of the line buffer
    reg [3:0] read_linebuffer_valid;                    //reg which tells the line buffer to read  
    reg [8:0] read_pixel_counter;                       //as the image size is 512 X 512 it will change the line buffer after it has read 512 datas for that log2(512)..9 bits required
    
    reg read_linebuffer;                                // signal which ultimately decides whether to read or not
    
    always @(*)
    begin
    
        case(currentreadlinebuffer)
        0: begin
                o_pixel_data = {lb1_data,lb2_data,lb3_data};
           end
        1: begin
                o_pixel_data = {lb2_data,lb3_data,lb4_data};
           end
        2: begin
                o_pixel_data = {lb3_data,lb4_data,lb1_data};
           end
        3: begin
                o_pixel_data = {lb4_data,lb1_data,lb2_data};
           end        
        endcase
    
    end
    
    always @(posedge i_clk)
    begin
        if(i_rst)
            read_pixel_counter <= 0;
        else
        begin
            if(read_linebuffer)
                read_pixel_counter <= read_pixel_counter + 1;
        end
    end
    
    always @(posedge i_clk)
    begin
        if(i_rst)
            currentreadlinebuffer <= 0;
        else if(read_pixel_counter == 511 && read_linebuffer)
        begin
            currentreadlinebuffer <= currentreadlinebuffer + 1;
        end    
    
    end
 
    always @(*)
    begin
        case(currentreadlinebuffer)
        0: begin
            read_linebuffer_valid[0] = read_linebuffer;
            read_linebuffer_valid[1] = read_linebuffer;
            read_linebuffer_valid[2] = read_linebuffer;
            read_linebuffer_valid[3] = 0;
           end
        1: begin
            read_linebuffer_valid[0] = 0;
            read_linebuffer_valid[1] = read_linebuffer;
            read_linebuffer_valid[2] = read_linebuffer;
            read_linebuffer_valid[3] = read_linebuffer;
           end
        2: begin
            read_linebuffer_valid[0] = read_linebuffer;
            read_linebuffer_valid[1] = 0;
            read_linebuffer_valid[2] = read_linebuffer;
            read_linebuffer_valid[3] = read_linebuffer;
           end
        3: begin
            read_linebuffer_valid[0] = read_linebuffer;
            read_linebuffer_valid[1] = read_linebuffer;
            read_linebuffer_valid[2] = 0;
            read_linebuffer_valid[3] = read_linebuffer;
           end   
        endcase
    end
      
   // Controlling ultimately the read_linebuffer signal to start reading from line buffer
   // To start reading we need to have atleast received 512 X 3 data then only we can start convolution operation 
   
   reg [12:0] totalpixelcounter;       //reg used to count the total number of pixels in the line buffer 
                                       //total pixels which can be received at a time is (512 X 4) to fill all the 4 line buffers
                                       
   /*
    Cases: 1) We are having data coming from external world but not reading 
           2) Data is not coming from external world but reading
           3) Data is coming and data is reading simultaneously
           
   */
   
   reg read_state;
   
   localparam IDLE = 'b0,
              RD_BUFFER = 'b1;             
   
   always @(posedge i_clk)
   begin
        if(i_rst)
            totalpixelcounter <= 0;
        else
        begin
            if  (i_pixel_data_valid & !read_linebuffer)
                totalpixelcounter <= totalpixelcounter + 1;
            else if (!i_pixel_data_valid & read_linebuffer)
                totalpixelcounter <= totalpixelcounter - 1;
        end
   end
   
   /* 
   
   IDLE STATE: Waits until 1536 pixels received once received starts reading and GOES TO NEXT STATE
 
   RD_BUFFER STATE: checks if 512 pixels read 512 pixels means 1 line buffer is read so now it has to read the next line buffer
           
   */
   
   always @(posedge i_clk)
    begin
        if(i_rst)
        begin
            read_state <= IDLE;
            read_linebuffer <= 1'b0;
            o_intr <= 1'b0;
        end
        else
        begin
        case(read_state)
            IDLE:begin
                    o_intr <= 1'b0;
                    if(totalpixelcounter >= 1536)
                    begin
                        read_linebuffer <= 1'b1;
                        read_state <= RD_BUFFER;
                    end
                end
            RD_BUFFER:begin
                        if(read_pixel_counter == 511)
                         begin
                            read_state <= IDLE;
                            read_linebuffer <= 1'b0;
                            o_intr <= 1'b1;
                        end
                      end
        endcase
        end
    end
   
  // As we have already prefetched the data so my output data valid signal will be asserted when my read_linebuffer is on
  
  assign o_pixel_data_valid = read_linebuffer; 
       
endmodule