module eagle (
    input clk_50MHz,            // sys clock
    input reset,                // sys reset
    input [9:0] x,              // from VGA controller
    input [9:0] y,              // from VGA controller
    input refresh_tick,
    input [9:0] x_enemy_bullet,
    input [9:0] y_enemy_bullet,
    input [9:0] x_tank_bullet,
    input [9:0] y_tank_bullet,
    output reg [9:0] x_eagle,
    output reg [9:0] y_eagle,
    output reg [29:0] rom_eagle,
    output reg eagle_on,
    output reg eagle_detroyed
    );

    localparam X_START = 320;
    localparam Y_START = 240;
    wire [4:0] col_eagle;
    wire [4:0] row_eagle;
    reg [9:0] x_eagle_l ;
    reg [9:0] x_eagle_r ;
    reg [9:0] y_eagle_t ;
    reg [9:0] y_eagle_b ;
    reg [9:0] x_eagle_next = X_START;
    reg [9:0] y_eagle_next = Y_START;

    assign col_eagle = x - x_eagle;
    assign row_eagle = y - y_eagle;
    assign x_eagle_l = x_eagle;
    assign x_eagle_r = x_eagle + 31;
    assign y_eagle_t = y_eagle;
    assign y_eagle_b = y_eagle + 31;
    assign eagle_on = (x >= x_eagle_l) && (x <= x_eagle_r) && (y >= y_eagle_t) && (y <= y_eagle_b);
    
    eagle_rom   eagle_rom_unit   (.clk(clk_50MHz), .row(row_eagle), .col(col_eagle), .color_data(rom_eagle));

    always @(posedge clk_50MHz or negedge reset)
    begin
        if (!reset) begin
            x_eagle <= X_START;
            y_eagle <= Y_START;
        end
        else begin
            x_eagle <= x_eagle_next;
            y_eagle <= y_eagle_next;
        end
    end

    always @(posedge clk_50MHz) begin
        if (!reset) eagle_detroyed = 0;
        else 
        if (refresh_tick) begin
            y_eagle_next = y_eagle;       // no move
            x_eagle_next = x_eagle;       // no move
            if (((y_enemy_bullet < y_eagle_b) && (y_enemy_bullet + 3 > y_eagle_t) && (x_enemy_bullet < x_eagle_r) && (x_enemy_bullet > x_eagle_l)) ||
                ((y_tank_bullet  < y_eagle_b) && (y_tank_bullet + 3  > y_eagle_t) && (x_tank_bullet < x_eagle_r)  && (x_tank_bullet  > x_eagle_l)) )
            begin
                eagle_detroyed = 1;
            end
        end
    end
endmodule