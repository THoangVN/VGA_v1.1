module pixel_gen(
    input clk_50MHz,        // sys clock
    input reset,            // sys reset
    input up,               // btnU
    input down,             // btnD
    input left,             // btnL
    input right,            // btnR
    input shot,
    input video_on,         // from VGA controller
    input [9:0] x,          // from VGA controller
    input [9:0] y,          // from VGA controller
    input p_tick,           // 25MHz from vga controller
    output reg [29:0] rgb   // to VGA port
    );
    // 60Hz refresh tick
    wire refresh_tick;
    assign refresh_tick = ((y == 491) && (x == 0)) ? 1 : 0; // start of vsync(vertical retrace)

//------------------------------------------------------//
//                   MAP SETTING                        //
//------------------------------------------------------//
    localparam number_of_brick = 100;
    wire hit, hit_by_enemy;
    wire [number_of_brick-1:0] stop_up, stop_down, stop_left, stop_right ;
    wire [number_of_brick-1:0] stop_enemy_up, stop_enemy_down, stop_enemy_left, stop_enemy_right ;
    wire [number_of_brick-1:0] brick_on;
    wire wall_on;
    wire [29:0] brick_rom;
    wire [29:0] wall_rom;
    // map_1 #(number_of_brick) map_1_unit (   .clk_50MHz(clk_50MHz),
    //                                         .reset(reset),
    //                                         .x(x),
    //                                         .y(y),
    //                                         .brick_on(brick_on),
    //                                         .wall_on(wall_on),
    //                                         .refresh_tick(refresh_tick),
    //                                         .brick_rom_data(brick_rom),
    //                                         .wall_rom_data(wall_rom),
    //                                         .x_tank_r(x_tank_r),
    //                                         .x_tank_l(x_tank_l),
    //                                         .y_tank_t(y_tank_t),
    //                                         .y_tank_b(y_tank_b),
    //                                         .x_enemy_r(x_enemy_r),
    //                                         .x_enemy_l(x_enemy_l),
    //                                         .y_enemy_t(y_enemy_t),
    //                                         .y_enemy_b(y_enemy_b),
    //                                         .x_bullet_r(sq_x_reg+3),
    //                                         .x_bullet_l(sq_x_reg),
    //                                         .y_bullet_t(sq_y_reg),
    //                                         .y_bullet_b(sq_y_reg+3),
    //                                         .hit(hit),
    //                                         .hit_by_enemy(hit_by_enemy),
    //                                         .bullet_size(SQUARE_SIZE),
    //                                         .stop_go_up(stop_up),
    //                                         .stop_go_down(stop_down),
    //                                         .stop_go_left(stop_left),
    //                                         .stop_go_right(stop_right),
    //                                         .stop_enemy_go_up(stop_enemy_up),
    //                                         .stop_enemy_go_down(stop_enemy_down),
    //                                         .stop_enemy_go_left(stop_enemy_left),
    //                                         .stop_enemy_go_right(stop_enemy_right),
    //                                         .x_bullet_enemy(x_bullet_enemy),
    //                                         .y_bullet_enemy(y_bullet_enemy)
    //                                         );

//------------------------------------------------------//
//                   ENEMY SETTING                      //
//------------------------------------------------------//
    wire enemy_on, bullet_on;
    wire [29:0] rom_enemy;
    wire [9:0] x_enemy_l;
    wire [9:0] x_enemy_r;
    wire [9:0] y_enemy_t;
    wire [9:0] y_enemy_b;
    wire [9:0] x_bullet_enemy;
    wire [9:0] y_bullet_enemy;
    wire enemy_detroyed;
    enemy #(number_of_brick) enemy1 (   .clk_50MHz(clk_50MHz),
                                        .reset(reset),                        
                                        .x(x),                     
                                        .y(y),                     
                                        .refresh_tick(refresh_tick),
                                        .stop_up(stop_enemy_up),
                                        .stop_down(stop_enemy_down),
                                        .stop_left(stop_enemy_left),
                                        .stop_right(stop_enemy_right),
                                        .x_enemy_r(x_enemy_r),
                                        .x_enemy_l(x_enemy_l),
                                        .y_enemy_t(y_enemy_t),
                                        .y_enemy_b(y_enemy_b),
                                        .enemy_on(enemy_on),
                                        .rom_enemy(rom_enemy),
                                        .bullet_on(bullet_on),
                                        .x_bullet(x_bullet_enemy),
                                        .y_bullet(y_bullet_enemy),
                                        .x_tank(x_tank_reg),
                                        .y_tank(y_tank_reg),
                                        .x_tank_bullet(sq_x_next),
                                        .y_tank_bullet(sq_y_next),
                                        .hit(hit_by_enemy),
                                        .tank_detroyed(tank_detroyed),
                                        .enemy_detroyed(enemy_detroyed)
                                        );

//------------------------------------------------------//
//                  TANK SETTING                        //
//------------------------------------------------------//
    // maximum x, y values in display area
    localparam X_MAX = 639;
    localparam Y_MAX = 479;
    // square rom boundaries
    localparam tank_SIZE = 32;
    localparam X_START = 32;                // starting x position - left rom edge centered horizontally
    localparam Y_START = 416;                // starting y position - centered in lower yellow area vertically
    // tank gameboard boundaries
    localparam X_LEFT = 32;                  // against left green wall
    localparam X_RIGHT = 608;                // against right green wall
    localparam Y_TOP = 32;                   // against top home/wall areas 
    localparam Y_BOTTOM = 448;               // against bottom green wall
    localparam number_of_lives = 5;
    // tank boundary signals
    reg [9:0] x_tank_l, x_tank_r;          // tank horizontal boundary signals
    reg [9:0] y_tank_t, y_tank_b;          // tank vertical boundary signals  
    reg [9:0] y_tank_reg = Y_START;         // tank starting position X
    reg [9:0] x_tank_reg = X_START;         // tank starting position Y
    reg [9:0] y_tank_next, x_tank_next;     // signals for register buffer 
    localparam tank_VELOCITY = 1;            // tank velocity 
    bit tank_detroyed;
    byte count;
    bit stop_up_by_enemy, stop_down_by_enemy, stop_left_by_enemy, stop_right_by_enemy;
    assign tank_detroyed = ((y_bullet_enemy < y_tank_b) && ((y_bullet_enemy+3) > y_tank_t) && (x_bullet_enemy < x_tank_r) && ((x_bullet_enemy+3) > x_tank_l));
    assign stop_up_by_enemy    = (y_tank_t == y_enemy_b) && (x_tank_l <= x_enemy_r) && (x_tank_r >= x_enemy_l);
    assign stop_down_by_enemy  = (y_tank_b == y_enemy_t) && (x_tank_l <= x_enemy_r) && (x_tank_r >= x_enemy_l);
    assign stop_left_by_enemy  = (x_tank_l == x_enemy_r) && (y_tank_t <= y_enemy_b) && (y_tank_b >= y_enemy_t);
    assign stop_right_by_enemy = (x_tank_r == x_enemy_l) && (y_tank_t <= y_enemy_b) && (y_tank_b >= y_enemy_t);
    // Register Control
    always @(posedge clk_50MHz or negedge reset)
        if(!reset) begin
            x_tank_reg <= X_START;
            y_tank_reg <= Y_START;
        end
        else begin 
            x_tank_reg <= x_tank_next;
            y_tank_reg <= y_tank_next;
        end
        
    wire shoted;		  
    // tank Control
    always @* begin
        y_tank_next = y_tank_reg;       // no move
        x_tank_next = x_tank_reg;       // no move

        if(refresh_tick) begin
            if (tank_detroyed) begin
                y_tank_next <= Y_START;
                x_tank_next <= X_START;
            end
            else begin
                if(up & (y_tank_t > tank_VELOCITY) & (y_tank_t > (Y_TOP + tank_VELOCITY)&& (|stop_up)==0) && !stop_up_by_enemy)
                    y_tank_next = y_tank_reg - tank_VELOCITY;  // move up
                else if(down & (y_tank_b < (Y_MAX - tank_VELOCITY)) & (y_tank_b < (Y_BOTTOM - tank_VELOCITY) && (|stop_down)==0) && !stop_down_by_enemy)
                    y_tank_next = y_tank_reg + tank_VELOCITY;  // move down
                else if(left & (x_tank_l > tank_VELOCITY) & (x_tank_l > (X_LEFT + tank_VELOCITY - 1) && (|stop_left)==0) && !stop_left_by_enemy)
                    x_tank_next = x_tank_reg - tank_VELOCITY;   // move left
                else if(right & (x_tank_r < (X_MAX - tank_VELOCITY)) & (x_tank_r < (X_RIGHT - tank_VELOCITY) && (|stop_right)==0) && !stop_right_by_enemy)
                    x_tank_next = x_tank_reg + tank_VELOCITY;   // move right
            end
        end
    end     
    
    // row and column wires for each rom
    wire [4:0] row, col;      // tank up
    
    //give value to rows and columns for roms
    assign col = x - x_tank_l;     // to obtain the column value, subtract rom left x position from x
    assign row = y - y_tank_t;     // to obtain the row value, subtract rom top y position from y

    // Instantiate roms
    // tank direction roms
    tank_up_rom     rom1(.clk(clk_50MHz), .row(row), .col(col), .color_data(rom_data1));
    tank_down_rom   rom2(.clk(clk_50MHz), .row(row), .col(col), .color_data(rom_data2));
    tank_left_rom   rom3(.clk(clk_50MHz), .row(row), .col(col), .color_data(rom_data3));
    tank_right_rom  rom4(.clk(clk_50MHz), .row(row), .col(col), .color_data(rom_data4));
    // boom_rom        tank_boom(.clk(clk_50MHz), .row(row), .col(col), .color_data(rom_data5));
    
    // **** ROM BOUNDARIES / STATUS SIGNALS ****
    // tank rom data square boundaries
    assign x_tank_l = x_tank_reg;
    assign y_tank_t = y_tank_reg;
    assign x_tank_r = x_tank_l + tank_SIZE - 1;
    assign y_tank_b = y_tank_t + tank_SIZE - 1;
    
    // rom object status signal
    
    wire tank_on;
    
    // pixel within rom square boundaries
    assign tank_on = (x_tank_l <= x) && (x <= x_tank_r) && (y_tank_t <= y) && (y <= y_tank_b);     
    // RGB Color Values
    localparam RED    = 30'h3FF00000;
    localparam GREEN  = {{10{1'b0}},{10{1'b1}},{10{1'b0}}};
    localparam BLUE   = {{10{1'b0}},{10{1'b0}},{10{1'b1}}};
    localparam YELLOW = {{10{1'b1}},{10{1'b1}},{10{1'b0}}}; 
    localparam BLACK  = 30'h000;
    
    // **** MULTIPLEX tank ROMS ****
    wire [29:0] tank_rom;
    wire [29:0] rom_data1, rom_data2, rom_data3, rom_data4;//, rom_data5;

    reg [1:0] tank_select;
    bit [1:0] bullet_select ;

    always @(posedge clk_50MHz or negedge reset)
    begin
        if(!reset) begin
            tank_select = 2'b00;
            count = number_of_lives;
        end
        else if(refresh_tick)
        begin
            if (tank_detroyed) count--;
            if(up)
                tank_select = 2'b00;
            else if(down)
                tank_select = 2'b01;
            else if(left)
                tank_select = 2'b10;
            else if(right)
                tank_select = 2'b11;
        end
    end
    
    assign tank_rom =    
    // tank_detroyed ? rom_data5 :
                        (tank_select == 2'b00) ? rom_data1 :
                        (tank_select == 2'b01) ? rom_data2 :
                        (tank_select == 2'b10) ? rom_data3 :
                                                rom_data4 ;

//------------------------------------------------------//
//                      EAGLE                           //
//------------------------------------------------------//
    wire eagle_on;
    // wire eagle_detroyed;
    wire [29:0] rom_eagle;
    wire [9:0] x_eagle;
    wire [9:0] y_eagle;
    eagle eagle_unit (  .clk_50MHz(clk_50MHz),        
                        .reset(reset),                
                        .x(x),              
                        .y(y),              
                        .refresh_tick(refresh_tick),
                        // .x_enemy_bullet(x_bullet_enemy),
                        // .y_enemy_bullet(y_bullet_enemy),
                        // .x_enemy(x_enemy_l),
                        // .y_enemy(y_enemy_t),
                        // .x_tank_bullet(sq_x_next),
                        // .y_tank_bullet(sq_y_next),
                        // .x_tank(x_tank_reg),
                        // .y_tank(y_tank_reg),
                        .x_eagle(x_eagle),
                        .y_eagle(y_eagle),
                        .rom_eagle(rom_eagle),
                        .eagle_on(eagle_on),
                        // .eagle_detroyed(eagle_detroyed)
                        );

//------------------------------------------------------//
//               TANK BULLET SETTING                    //
//------------------------------------------------------//
    localparam SQUARE_SIZE = 4;             // width of square sides in pixels
    localparam SQUARE_VELOCITY = 8;         // set position change value for positive direction
    
    reg [9:0] sq_x_l, sq_x_r;              // square left and right boundary
    reg [9:0] sq_y_t, sq_y_b;              // square top and bottom boundary
    
    reg [9:0] sq_x_reg;
    reg [9:0] sq_y_reg;                     // regs to track left, top position
    wire [9:0] sq_x_next, sq_y_next;        // buffer wires

    // register control
    always @(posedge clk_50MHz or negedge reset)
        if(!reset) begin
            sq_x_reg <= X_START + tank_SIZE/2 - SQUARE_SIZE/2;
            sq_y_reg <= Y_START + tank_SIZE/2 - SQUARE_SIZE/2;
        end
        else 
        begin
            sq_x_reg <= sq_x_next;
            sq_y_reg <= sq_y_next;
        end
    
    // square boundaries
    assign sq_x_l = sq_x_reg;                   // left boundary
    assign sq_y_t = sq_y_reg;                   // top boundary
    assign sq_x_r = sq_x_reg + SQUARE_SIZE - 1;   // right boundary
    assign sq_y_b = sq_y_reg + SQUARE_SIZE - 1;   // bottom boundary
    
    // square status signal
    wire sq_on;
    assign sq_on = ((sq_x_l <= x) && (x <= sq_x_r) && (sq_y_t <= y) && (y <= sq_y_b)) ;//&& (y <= Y_START && x >= X_START);
    bit state;
    bit [1:0] bullet_direction;
    localparam IDLE = 0;
    localparam SHOTING = 1;
    always @(posedge clk_50MHz or negedge reset) begin
        if (!reset) begin
            state = IDLE;
            sq_y_next = sq_y_reg;       
            sq_x_next = sq_x_reg;       
            bullet_direction = 2'b00;
        end
        else begin
            if (refresh_tick)
            case (state)
                IDLE: begin
                    sq_x_next = x_tank_reg + tank_SIZE/2 - SQUARE_SIZE/2;
                    sq_y_next = y_tank_reg + tank_SIZE/2 - SQUARE_SIZE/2;
                    if (shot) state = SHOTING;
                    bullet_direction = tank_select;
                end
                SHOTING: begin
                    case (bullet_direction)
                        2'b00: begin
                            sq_y_next = sq_y_reg - SQUARE_VELOCITY;
                        end
                        2'b01: begin
                            sq_y_next = sq_y_reg + SQUARE_VELOCITY;
                        end
                        2'b10: begin
                            sq_x_next = sq_x_reg - SQUARE_VELOCITY;
                        end
                        2'b11: begin
                            sq_x_next = sq_x_reg + SQUARE_VELOCITY;
                        end
                    endcase
                    if ((sq_x_next > 607) || (sq_x_next < 28) || (sq_y_next > 447) || (sq_y_next < 28) || hit || enemy_detroyed)
                        state = IDLE;
                end
            endcase
        end
    end             

//------------------------------------------------------//
//                   TANK LIVES                         //
//------------------------------------------------------//
    // wire [29:0] rom_heart_on;
    // wire [29:0] rom_heart_off;
    // wire [number_of_lives:1] lives;
    // bit game_over;

    // assign lives[1] = (x >= 256) && (x < 272) && (y >= 456) && (y < 472);
    // assign lives[2] = (x >= 288) && (x < 304) && (y >= 456) && (y < 472);
    // assign lives[3] = (x >= 320) && (x < 336) && (y >= 456) && (y < 472);
    // assign lives[4] = (x >= 352) && (x < 368) && (y >= 456) && (y < 472);
    // assign lives[5] = (x >= 384) && (x < 400) && (y >= 456) && (y < 472);
    // assign game_over = (count==0);

    // heart_on_rom    heart_on_unit   (.clk(clk_50MHz), .row(y), .col(x), .color_data(rom_heart_on));
    // heart_off_rom   heart_off_unit  (.clk(clk_50MHz), .row(y), .col(x), .color_data(rom_heart_off));

//------------------------------------------------------//
//                   SCORE BOARD                        //
//------------------------------------------------------//
    // wire [3:0] dig0, dig1;
    // wire [29:0] text_rgb;
    // wire text_on;
    // m100_counter counter_unit  (.clk(clk_50MHz),
    //                             .reset(reset),
    //                             .d_inc(enemy_detroyed),  
    //                             // .d_clr(d_clr),
    //                             .dig0(dig0),
    //                             .dig1(dig1));

    // text text_unit (.clk(clk_50MHz),
    //                 .x(x),
    //                 .y(y),
    //                 .dig0(dig0),
    //                 .dig1(dig1),       
    //                 .text_on(text_on),
    //                 .text_rgb(text_rgb));

//------------------------------------------------------//
//                      GAME OVER                       //
//------------------------------------------------------//
    // wire [29:0] over_rgb;
    // wire over_on;
    // game_over_display over_display (.clk(clk_50MHz), .x(x), .y(y), .game_over(game_over), .game_over_on(over_on), .game_over_rgb(over_rgb));

//------------------------------------------------------//
//                  RGB SETTING OUTPUT                  //
//------------------------------------------------------//
    // Pixel Location Status Signals
    wire upper_yellow_on, lower_yellow_on, street_on, water_on, street_2_on;
    wire [29:0] rom_sand = YELLOW;
    wire [29:0] rom_water = BLUE;
    wire [29:0] rom_road = BLACK;
    // Drivers for Status Signals
    assign upper_yellow_on  = ((x >= 32) && (x < 608) && (y >= 228) && (y < 260));
    assign lower_yellow_on  = ((x >= 32) && (x < 608) && (y >= 420) && (y < 452));
    assign street_on        = ((x >= 32) && (x < 608) && (y >= 260) && (y < 420));
    assign street_2_on      = ((x >= 32) && (x < 608) && (y >= 31) && (y < 68));
    assign water_on         = ((x >= 32) && (x < 608) && (y >= 68) && (y < 228));

    // sand_rom    sand_unit  (.clk(clk_50MHz), .row(y), .col(x), .color_data(rom_sand));
    // water_rom   water_unit (.clk(clk_50MHz), .row(y), .col(x), .color_data(rom_water));
    // road_rom    road_unit  (.clk(clk_50MHz), .row(y), .col(x), .color_data(rom_road));

    always @* begin
        if (~video_on) 
            rgb = 30'h0;
        // else if (game_over)
        //     rgb = over_rgb;
        else  begin 					
            // tank 
            if(tank_on && lower_yellow_on)      
                if(|tank_rom == 0)              
                    rgb = rom_road;
                else
                    rgb = tank_rom;
                
                
            else if(tank_on && upper_yellow_on) 
                if(|tank_rom == 0)              
                    rgb = rom_water;
                else
                    rgb = tank_rom;
        
        
            else if(tank_on && street_on)      
                if(|tank_rom == 0 )  
                    rgb = rom_sand;
                else
                    rgb = tank_rom;
            
            
            else if(tank_on && water_on)       
                if(|tank_rom == 0)  
                    rgb = rom_sand;
                else
                    rgb = tank_rom;

            else if(tank_on && street_2_on)        
                if(|tank_rom == 0) 
                    rgb = rom_road;
                else
                    rgb = tank_rom;

            //eagle
            else if(eagle_on && lower_yellow_on)        
                if(&rom_eagle == 1)  
                    rgb = rom_road;
                else
                    rgb = rom_eagle;
                
                
            else if(eagle_on && upper_yellow_on) 
                if(&rom_eagle == 1)  
                    rgb = rom_water;
                else
                    rgb = rom_eagle;
        
        
            else if(eagle_on && street_on)     
                if(&rom_eagle == 1 )  
                    rgb = rom_sand;
                else
                    rgb = rom_eagle;
            
            
            else if(eagle_on && water_on)      
                if(&rom_eagle == 1)  
                    rgb = rom_sand;
                else
                    rgb = rom_eagle;
            
            else if(eagle_on && street_2_on)        
                if(&rom_eagle == 1) 
                    rgb = rom_road;
                else
                    rgb = rom_eagle;

            // enemy
            else if(enemy_on && lower_yellow_on)    
                if(&rom_enemy == 1)  
                    rgb = rom_road;
                else
                    rgb = rom_enemy;
                
                
            else if(enemy_on && upper_yellow_on) 
                if(&rom_enemy == 1)  
                    rgb = rom_water;
                else
                    rgb = rom_enemy;
        
        
            else if(enemy_on && street_on)     
                if(&rom_enemy == 1 )  
                    rgb = rom_sand;
                else
                    rgb = rom_enemy;
            
            
            else if(enemy_on && water_on)      
                if(&rom_enemy == 1)  
                    rgb = rom_sand;
                else
                    rgb = rom_enemy;
            
            else if(enemy_on && street_2_on)        
                if(&rom_enemy == 1) 
                    rgb = rom_road;
                else
                    rgb = rom_enemy;

            else if(sq_on)
                rgb = RED;
            else if (bullet_on)
                rgb = RED;

            // else if(text_on)
            //     if(|text_rgb==0)
            //         rgb = RED;
            //     else rgb = text_rgb;	

            // else if (lives[1])
            //     if (count >= 1)
            //         if (&rom_heart_on == 1)
            //             rgb = wall_rom;
            //         else rgb = rom_heart_on;
            //     else 
            //         if (&rom_heart_off == 1)
            //             rgb = wall_rom;
            //         else rgb = rom_heart_off;

            // else if (lives[2])
            //     if (count >= 2)
            //         if (&rom_heart_on == 1)
            //             rgb = wall_rom;
            //         else rgb = rom_heart_on;
            //     else 
            //         if (&rom_heart_off == 1)
            //             rgb = wall_rom;
            //         else rgb = rom_heart_off;

            // else if (lives[3])
            //     if (count >= 3)
            //         if (&rom_heart_on == 1)
            //             rgb = wall_rom;
            //         else rgb = rom_heart_on;
            //     else 
            //         if (&rom_heart_off == 1)
            //             rgb = wall_rom;
            //         else rgb = rom_heart_off;

            // else if (lives[4])
            //     if (count >= 4)
            //         if (&rom_heart_on == 1)
            //             rgb = wall_rom;
            //         else rgb = rom_heart_on;
            //     else 
            //         if (&rom_heart_off == 1)
            //             rgb = wall_rom;
            //         else rgb = rom_heart_off;

            // else if (lives[5])
            //     if (count == 5)
            //         if (&rom_heart_on == 1)
            //             rgb = wall_rom;
            //         else rgb = rom_heart_on;
            //     else 
            //         if (&rom_heart_off == 1)
            //             rgb = wall_rom;
            //         else rgb = rom_heart_off;

            else if(wall_on)
                rgb = wall_rom;					   
            else if (|brick_on)
                rgb = brick_rom;
        
            // game board backgrounds    
            else if(upper_yellow_on)
                rgb = rom_water;
                
                
            else if(lower_yellow_on)
                rgb = rom_road;
                
                
            else if(street_on)
                rgb = rom_sand;
                    
            else if(street_2_on)
                rgb = rom_road;
                    
            else if(water_on)
                rgb = rom_sand;

        end
    end
endmodule