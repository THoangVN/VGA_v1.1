`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//
// 
//////////////////////////////////////////////////////////////////////////////////
module vga(
	input CLOCK_50,     
	input  [1:0]SW,
	output VGA_HS, 
	output VGA_VS,
	output VGA_CLK,
	output VGA_BLANK,
	output VGA_SYNC,
	output [9:0] VGA_B,      
	output [9:0] VGA_G,      
	output [9:0] VGA_R,      
   inout  [25:11] GPIO_1
   );

   wire [9:0] w_x, w_y;
   wire w_p_tick, w_video_on; //w_reset;
   reg [29:0] rgb_reg;
   wire [29:0] rgb_next;
   wire up, down, right, left;

   // Instantiate Inner Modules
   vga_controller vga( .clk_50MHz(CLOCK_50),
                        .reset(SW[1]),
                        .video_on(w_video_on),
                        .p_tick(VGA_CLK),//w_p_tick),
                        .hsync(VGA_HS),
                        .vsync(VGA_VS),
                        .x(w_x),
                        .y(w_y));
   
   pixel_gen pg(        .clk_50MHz(CLOCK_50),
                        .reset(SW[1]),
                        .video_on(w_video_on),
								.up(up),
								.down(down),
								.left(left),
								.right(right),
								.shot(SW[0]),
                        .x(w_x),
                        .y(w_y),
								.p_tick(VGA_CLK),
                        .rgb(rgb_next));

	assign {up, down, left, right} = {!GPIO_1[11], !GPIO_1[13], !GPIO_1[15], !GPIO_1[17]};		
	assign {VGA_R, VGA_G, VGA_B} = rgb_reg;
   // rgb buffer
   always @(posedge CLOCK_50) 
      if(VGA_CLK)
         rgb_reg <= rgb_next;

   assign VGA_BLANK = 0;//hsync & vsync;
   assign VGA_SYNC = 0 ;


endmodule