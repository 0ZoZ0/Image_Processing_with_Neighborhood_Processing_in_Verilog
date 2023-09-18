`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2023 11:34:56 AM
// Design Name: 
// Module Name: tb
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


`define headerSize 1080
`define imageSize 512*512

module tb();
    
 
 reg clk;
 reg reset;
 reg [7:0] imgData;
 integer file,file1,i;
 reg imgDataValid;
 integer sentSize;
 
 wire intr;
 wire [7:0] outData;
 wire outDataValid;
 
 integer receivedData = 0;
 
  top dut( 
    .axi_clk(clk), .axi_reset_n(reset),
    
    //slave interface
    .i_data_valid(imgDataValid), .i_data(imgData), .o_data_ready(),
    
    //master interface
    .o_data_valid(outDataValid), .o_data(outData), .i_data_ready(1'b1),
    
    //interrupt
    .o_intr(intr)
); 

 initial
 begin
    clk = 1'b0;
    forever
    begin
        #5 clk = ~clk;
    end
 end
 
 initial
 begin
 
    reset = 0;
    sentSize = 0;
    imgDataValid = 0;
    #100;
    reset = 1;
    #100;
    
    //opening input file and output file
    file = $fopen("/home/akash/Downloads/lena_gray.bmp","rb");
    file1 = $fopen("/home/akash/Downloads/blurred_lena_gray.bmp","wb");

    for(i=0;i<`headerSize;i=i+1)            //The picture contains the header file as well as data
    begin
        $fscanf(file,"%c",imgData);
        $fwrite(file1,"%c",imgData);        //Processing is done only in the data part header file data is stored as it is in the output
    end
 
    //Reading values from the image and sending it to the module
    //We can at max read 4 line at a time
    for(i=0;i<4*512;i=i+1)
    begin
        @(posedge clk);
        $fscanf(file,"%c",imgData);
        imgDataValid <= 1'b1;              //it will tell the module that it has the data and read it
    end
    
    //We have sent 4 lines of data
    sentSize = 4*512;
    
    
    //Deassert the input data valid signal 
    @(posedge clk);
    imgDataValid <= 1'b0;
    
    
    //until the total sent size is less than the image size wait for the interrupt from the module if the interrupt comes then send the next line data
    while(sentSize < `imageSize)
    begin
        @(posedge intr);
        for(i=0;i<512;i=i+1)
        begin
            @(posedge clk);
            $fscanf(file,"%c",imgData);
            imgDataValid <= 1'b1;    
        end
        @(posedge clk);
        imgDataValid <= 1'b0;
        sentSize = sentSize+512;
    end
    
    
    @(posedge clk);
    imgDataValid <= 1'b0;
   
   //we need to send two dummy lines as in neighborhood processing we are not taking care of the edges
   // Two horizontal edges  
    @(posedge intr);
    for(i=0;i<512;i=i+1)
    begin
        @(posedge clk);
        imgData <= 0;
        imgDataValid <= 1'b1;
        
    end
    @(posedge clk);
    imgDataValid <= 1'b0;
    
    @(posedge intr);
    for(i=0;i<512;i=i+1)
    begin
        @(posedge clk);
        imgData <= 0;
        imgDataValid <= 1'b1;    
       
    end
    
    @(posedge clk);
    imgDataValid <= 1'b0;
    $fclose(file);
   
 end
 
 always @(posedge clk)
 begin
     if(outDataValid)
     begin
         $fwrite(file1,"%c",outData);
         receivedData = receivedData+1;
     end 
     
     if(receivedData == `imageSize)
     begin
        $fclose(file1);
        $stop;
     end
 end
 
  
    
endmodule
