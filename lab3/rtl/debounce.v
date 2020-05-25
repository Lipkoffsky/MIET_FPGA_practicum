`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.05.2020 20:07:38
// Design Name: 
// Module Name: Debounce
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

module debounce(

  input         clk_i,
  input         rst_i,
  input         en_i,
   
  output        en_down_o,
  output        en_up_o

);

  reg [1:0] sync;
  
  always @( posedge clk_i or posedge rst_i ) begin
    if ( rst_i )
      sync <= 2'b0;
    else
      begin
        sync[0] <= ~en_i;
        sync[1] <= sync[0];
      end
  end
  

  
  assign en_down_o = ~sync[1] & sync[0];
  assign en_up_o   =  sync[1] & ~sync[0];    
  
endmodule
