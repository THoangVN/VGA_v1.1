`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//
// 
//////////////////////////////////////////////////////////////////////////////////
module vga(
	input clk_50MHz,     
	input reset,
	input [3:0] sw,       // 12 bits for color
	input  [16:15]SW,
	// input  up,
	// input  down,
	// input  right,
	// input  left,
	output hsync, 
	output vsync,
	output VGA_CLK,
	output VGA_BLANK,
	output VGA_SYNC,
	output [29:0] rgb,      // 30 FPGA pins for RGB(10 per color)	
   inout  [25:11]GPIO_1
   );
   //	reg [29:0] rgb_reg;    // register for Basys 3 12-bit RGB DAC 
	// wire video_on;         // Same signal as in controller
   wire [9:0] w_x, w_y;
   wire w_p_tick, w_video_on; //w_reset;
   reg [29:0] rgb_reg;
   wire [29:0] rgb_next;
   wire up, down, right, left;
   // Instantiate Inner Modules
   vga_controller vga( .clk_50MHz(clk_50MHz),
                        .reset(reset),
                        .video_on(w_video_on),
                        .p_tick(VGA_CLK),//w_p_tick),
                        .hsync(hsync),
                        .vsync(vsync),
                        .x(w_x),
                        .y(w_y));
    
   pixel_gen pg(        .clk_50MHz(clk_50MHz),
                        .reset(reset),
                        .video_on(w_video_on),
								.up(up),
								.down(down),
								.left(left),
								.right(right),
								.shot(sw[0]),
                        .x(w_x),
                        .y(w_y),
								.p_tick(VGA_CLK),
                        .rgb(rgb_next));

	assign {up, down, left, right} = {!GPIO_1[11], !GPIO_1[13], !GPIO_1[15], !GPIO_1[17]};		
   // assign reset = GPIO_1[23];
					 
   // rgb buffer
   always @(posedge clk_50MHz) 
      if(VGA_CLK)
         rgb_reg <= rgb_next;
    
   assign rgb = rgb_reg;
   assign VGA_BLANK = SW[15];//hsync & vsync;
   assign VGA_SYNC = SW[16] ;
        
endmodule