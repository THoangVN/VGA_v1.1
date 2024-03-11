module game_over_display(
    input clk,
    input [9:0] x,y,
    input game_over,
    output game_over_on,
    output reg [29:0] game_over_rgb
    );
    
    wire [10:0] rom_addr;
    wire [7:0] ascii_word;
    wire [6:0] char_addr;
    wire [3:0] row_addr;
    wire [2:0] bit_addr;
    wire ascii_bit;

    ascii_rom over_unit (.clk(clk), .addr(rom_addr), .data(ascii_word));

    assign game_over_on = (y >= 224) && (y < 256) && (x >= 128) && (x < 500); 
    assign row_addr = y[4:1];
    assign bit_addr = x[3:1];
    assign rom_addr = {char_addr, row_addr};
    assign ascii_bit = ascii_word[~bit_addr];

    always @* begin
        case(x[7:4])
            4'h0 : char_addr = 7'h47;     // G
            4'h1 : char_addr = 7'h41;     // A
            4'h2 : char_addr = 7'h4d;     // M
            4'h3 : char_addr = 7'h45;     // E
            4'h4 : char_addr = 7'h4f;     // O
            4'h5 : char_addr = 7'h56;     // V
            4'h6 : char_addr = 7'h45;     // E
            4'h7 : char_addr = 7'h52;     // R
            4'h8 : char_addr = 7'h00;     //
            4'h9 : char_addr = 7'h00;     //
            4'hA : char_addr = 7'h00;     // 
            4'hB : char_addr = 7'h00;     // 
            4'hC : char_addr = 7'h00;     // 
            4'hD : char_addr = 7'h00;     // 
            4'hE : char_addr = 7'h00;     // 
            4'hF : char_addr = 7'h00;     // 
        endcase
    end

    always @* begin
        game_over_rgb = 30'h0;     // black background
        // game_over_rgb = 30'h000fffff;     // aqua background
        
        if(game_over_on) begin
            if(ascii_bit)
                game_over_rgb = 30'h3FF00000; // red
        end
    end
endmodule