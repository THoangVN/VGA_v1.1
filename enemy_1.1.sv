module enemy #(parameter number_of_brick=100)(
    input clk_50MHz,      // sys clock
    input reset,                // sys reset
    input [9:0] x,              // from VGA controller
    input [9:0] y,              // from VGA controller
    input refresh_tick,
    input wire [number_of_brick-1:0] stop_up,
    input wire [number_of_brick-1:0] stop_down,
    input wire [number_of_brick-1:0] stop_left,
    input wire [number_of_brick-1:0] stop_right,
    input hit,
    input tank_detroyed,
    input [9:0] x_tank_bullet,
    input [9:0] y_tank_bullet,
    input [9:0] x_tank,
    input [9:0] y_tank,
    output reg [9:0] x_enemy_l,
    output reg [9:0] x_enemy_r,
    output reg [9:0] y_enemy_t,
    output reg [9:0] y_enemy_b,
    output wire enemy_on,
    output wire [29:0] rom_enemy,
    output wire bullet_on,
    output reg [9:0] x_bullet,
    output reg [9:0] y_bullet,
    output bit enemy_detroyed
    );
    localparam X_START_ENEMY = 32;
    localparam Y_START_ENEMY = 32;
    localparam enemy_speed = 1;
    localparam X_LEFT = 32;                 
    localparam X_RIGHT = 608;               
    localparam Y_TOP = 32;                   
    localparam Y_BOTTOM = 448; 
    localparam X_MAX = 639;
    localparam Y_MAX = 479;

    wire clk_50Hz;
    wire up, down, left, right, hold_boom;
    wire [29:0] rom_enemy_up;
    wire [29:0] rom_enemy_down;
    wire [29:0] rom_enemy_left;
    wire [29:0] rom_enemy_right;
    wire [29:0] boom_rom_data;
    reg  [9:0] x_enemy_register;
    reg  [9:0] y_enemy_register;
    reg  [9:0] x_enemy_next;
    reg  [9:0] y_enemy_next;
    wire [4:0] row_enemy, col_enemy;
    bit stop_up_by_tank, stop_down_by_tank, stop_left_by_tank, stop_right_by_tank;
    // bit change;
    assign col_enemy = x - x_enemy_l;
    assign row_enemy = y - y_enemy_t;
    assign rom_enemy = hold_boom ? boom_rom_data : up ? rom_enemy_up : down ? rom_enemy_down : left ? rom_enemy_left : rom_enemy_right;
    enemy_up_rom    enemy_up_unit       (.clk(clk_50MHz), .row(row_enemy), .col(col_enemy), .color_data(rom_enemy_up));
    enemy_down_rom  enemy_down_unit     (.clk(clk_50MHz), .row(row_enemy), .col(col_enemy), .color_data(rom_enemy_down));
    enemy_left_rom  enemy_left_unit     (.clk(clk_50MHz), .row(row_enemy), .col(col_enemy), .color_data(rom_enemy_left));
    enemy_right_rom enemy_right_unit    (.clk(clk_50MHz), .row(row_enemy), .col(col_enemy), .color_data(rom_enemy_right));
    boom_rom        enemy_boom          (.clk(clk_50MHz), .row(row_enemy), .col(col_enemy), .color_data(boom_rom_data));

    always @(posedge clk_50MHz or negedge reset) begin
        if (!reset) begin
            // Initialization logic
            x_enemy_register <= X_START_ENEMY;
            y_enemy_register <= Y_START_ENEMY;
        end
        else begin
            x_enemy_register <= x_enemy_next;
            y_enemy_register <= y_enemy_next;
        end
    end

    enemy_bullet bullet    (.clk_50MHz(clk_50MHz), 
                            .reset(reset), 
                            .x(x), 
                            .y(y),
                            .refresh_tick(refresh_tick),
                            .hit(hit),
                            .tank_detroyed(tank_detroyed),
                            .x_enemy(x_enemy_register), 
                            .y_enemy(y_enemy_register), 
                            .enemy_up(up), 
                            .enemy_down(down), 
                            .enemy_left(left), 
                            .enemy_right(right), 
                            .x_bullet_l(x_bullet), 
                            .y_bullet_t(y_bullet), 
                            .bullet_on(bullet_on));
    clk_divider  clk_dev   (.clk_50MHz(clk_50MHz), .clk_50Hz(clk_50Hz));
    random_move  rand_move (.clk(clk_50Hz), .rst(reset), .up(up), .down(down), .left(left), .right(right), .enemy_detroyed(enemy_detroyed), .boom(hold_boom));

    assign enemy_detroyed = ((y_tank_bullet < y_enemy_b) && ((y_tank_bullet+3) > y_enemy_t) && (x_tank_bullet < x_enemy_r) && ((x_tank_bullet+3) > x_enemy_l));
    assign stop_up_by_tank    = ((y_tank + 32) == y_enemy_t) && (x_tank <= x_enemy_r) && ((x_tank + 32) >= x_enemy_l);
    assign stop_down_by_tank  = (y_tank == y_enemy_b)        && (x_tank <= x_enemy_r) && ((x_tank + 32) >= x_enemy_l);
    assign stop_left_by_tank  = ((x_tank + 32) == x_enemy_l) && (y_tank <= y_enemy_b) && ((y_tank + 32) >= y_enemy_t);
    assign stop_right_by_tank = (x_tank == x_enemy_r)        && (y_tank <= y_enemy_b) && ((y_tank + 32) >= y_enemy_t);
    
    always @* begin
        y_enemy_next = y_enemy_register;       // no move
        x_enemy_next = x_enemy_register;       // no move
        if(refresh_tick) begin
            // change = 0;
            if (enemy_detroyed) begin
                y_enemy_next = Y_START_ENEMY;
                x_enemy_next = X_START_ENEMY;
            end
            else begin
                if(up & (y_enemy_t > enemy_speed) & (y_enemy_t > (Y_TOP + enemy_speed)) && (|stop_up)==0 && !stop_up_by_tank)
                    y_enemy_next = y_enemy_register - enemy_speed;  // move up
                else if(down & (y_enemy_b < (Y_MAX - enemy_speed)) & (y_enemy_b < (Y_BOTTOM - enemy_speed) && (|stop_down)==0) && !stop_down_by_tank)
                    y_enemy_next = y_enemy_register + enemy_speed;  // move down
                else if(left & (x_enemy_l > enemy_speed) & (x_enemy_l > (X_LEFT + enemy_speed - 1) && (|stop_left)==0) && !stop_left_by_tank)
                    x_enemy_next = x_enemy_register - enemy_speed;   // move left
                else if(right & (x_enemy_r < (X_MAX - enemy_speed)) & (x_enemy_r < (X_RIGHT - enemy_speed) && (|stop_right)==0) && !stop_right_by_tank)
                    x_enemy_next = x_enemy_register + enemy_speed;   // move right
                // else if ((up    && !((y_enemy_t > enemy_speed) && (y_enemy_t > (Y_TOP + enemy_speed)) && (|stop_up)==0)) ||
                //          (down  && !((y_enemy_b < (Y_MAX - enemy_speed)) && (y_enemy_b < (Y_BOTTOM - enemy_speed)) && (|stop_down)==0)) ||
                //          (left  && !((x_enemy_l > enemy_speed) && (x_enemy_l > (X_LEFT + enemy_speed - 1)) && (|stop_left)==0)) ||
                //          (right && !((x_enemy_r < (X_MAX - enemy_speed)) && (x_enemy_r < (X_RIGHT - enemy_speed)) && (|stop_right)==0)))
                //     change = 1;
            end
        end
    end  
    assign x_enemy_l = x_enemy_register;
    assign y_enemy_t = y_enemy_register;
    assign x_enemy_r = x_enemy_register + 31;
    assign y_enemy_b = y_enemy_register + 31;
    assign enemy_on = (x >= x_enemy_l) && (x <= x_enemy_r) && (y >= y_enemy_t) && (y <= y_enemy_b);
endmodule : enemy

module random_move (
    input wire clk,
    input wire rst,
    // input wire change,
    input bit enemy_detroyed,
    output reg boom,
    output reg up,
    output reg down,
    output reg left,
    output reg right
    );
    bit [1:0] direction;
    reg [2:0] state;
    // States
    localparam IDLE = 3'b111;
    localparam MOVE_UP = 3'b000;
    localparam MOVE_DOWN = 3'b001;
    localparam MOVE_LEFT = 3'b010;
    localparam MOVE_RIGHT = 3'b011;
    localparam BOOM = 3'b100;

    // Linear Feedback Shift Register
    reg [7:0] lfsr_state;

    assign {up, down, left, right} =  (direction==2'b00) ? 4'b1000 : (direction==2'b01) ? 4'b0100 : (direction==2'b10) ? 4'b0010 : 4'b0001;
    assign boom = (state==BOOM);

    always @(posedge clk or negedge rst /*or posedge change*/) begin
        if (!rst) begin
            state = MOVE_RIGHT;
            lfsr_state = 8'b1;  // Initial state != 0
            direction = 2'b11;
        end
        else begin
            // Update LFSR
            lfsr_state = {lfsr_state[6:0], lfsr_state[0] ^ lfsr_state[2] ^ lfsr_state[4] ^ lfsr_state[6]};
            // Change state
            case (state)
                IDLE: begin
                    if (enemy_detroyed) state = BOOM;
                    else state = {1'b0,lfsr_state[1:0]};
                end
                MOVE_UP: begin
                    direction = 2'b00;
                    if (enemy_detroyed) state = BOOM;
                    else state = IDLE;
                end
                MOVE_DOWN: begin
                    direction = 2'b01;
                    if (enemy_detroyed) state = BOOM;
                    else state = IDLE;
                end
                MOVE_LEFT: begin
                    direction = 2'b10;
                    if (enemy_detroyed) state = BOOM;
                    else state = IDLE;
                end
                MOVE_RIGHT: begin
                    direction = 2'b11;
                    if (enemy_detroyed) state = BOOM;
                    else state = IDLE;
                end
                BOOM: begin
                    state = IDLE;
                end
            endcase
        end
    end
endmodule : random_move

module clk_divider (
    input wire clk_50MHz,
    output bit clk_50Hz
    );
    int counter; 
    always @(posedge clk_50MHz) begin
        if (counter == 15000000) begin // 50MHz / 0.5Hz  ~ 1 seconds counter = 25000000
            counter = 0;
            clk_50Hz = ~clk_50Hz; 
        end else begin
            counter = counter + 1;
        end
    end
endmodule : clk_divider

module enemy_bullet(
    input clk_50MHz,      // sys clock
    input reset,                // sys reset
    input [9:0] x,              // from VGA controller
    input [9:0] y,              // from VGA controller
    input refresh_tick,
    input wire [9:0] x_enemy,
    input wire [9:0] y_enemy,
    input wire enemy_up,
    input wire enemy_down,
    input wire enemy_left,
    input wire enemy_right,
    input hit,
    input tank_detroyed,
    output wire [9:0] x_bullet_l,
    output wire [9:0] y_bullet_t,
    output wire bullet_on
    );
    localparam bullet_speed = 4;
    localparam IDLE = 0;
    localparam SHOTING = 1;
    bit state;

    wire up, down, left, right;
    wire [9:0] y_bullet_b, x_bullet_r;
    reg  [9:0] x_bullet_reg;
    reg  [9:0] y_bullet_reg;
    reg  [9:0] x_bullet_next;
    reg  [9:0] y_bullet_next;

    always @(posedge clk_50MHz or negedge reset) begin
        if (!reset) begin
            // Initialization logic
            x_bullet_reg <= x_enemy + 14;
            y_bullet_reg <= y_enemy + 14;
        end
        else begin
            // State update logic
            x_bullet_reg <= x_bullet_next;
            y_bullet_reg <= y_bullet_next;
        end
    end

    always @(posedge clk_50MHz or negedge reset) begin
        if (!reset) begin
            state = IDLE;
            y_bullet_next = y_bullet_reg;       
            x_bullet_next = x_bullet_reg;       
        end
        else begin
            if (refresh_tick)
            case (state)
                IDLE: begin
                    state = SHOTING;
                    {up,down,left,right} = {enemy_up,enemy_down,enemy_left,enemy_right};
                    x_bullet_next = x_enemy + 14;
                    y_bullet_next = y_enemy + 14;
                end
                SHOTING: begin
                    case ({up,down,left,right})
                        4'b1000: begin
                            y_bullet_next = y_bullet_reg - bullet_speed;
                        end
                        4'b0100: begin
                            y_bullet_next = y_bullet_reg + bullet_speed;
                        end
                        4'b0010: begin
                            x_bullet_next = x_bullet_reg - bullet_speed;
                        end
                        4'b0001: begin
                            x_bullet_next = x_bullet_reg + bullet_speed;
                        end
                    endcase
                    if ((x_bullet_next > 607) || (x_bullet_next < 28) || (y_bullet_next > 447) || (y_bullet_next < 28) || hit || tank_detroyed)
                        state = IDLE;
                end
            endcase
        end
    end 

    assign x_bullet_l = x_bullet_reg;
    assign y_bullet_t = y_bullet_reg;
    assign x_bullet_r = x_bullet_reg + 3;
    assign y_bullet_b = y_bullet_reg + 3;
    assign bullet_on = (x >= x_bullet_l) && (x <= x_bullet_r) && (y >= y_bullet_t) && (y <= y_bullet_b);
endmodule : enemy_bullet

module moving (
    input wire clk,
    input wire rst,
    // input wire change,
    input [9:0] x_tank,
    input [9:0] y_tank,
    input [9:0] x_enemy,
    input [9:0] y_enemy,
    input stop_up,
    input stop_down,
    input stop_left,
    input stop_right,
    output reg boom,
    output reg up,
    output reg down,
    output reg left,
    output reg right
    );
    bit [1:0] direction;
    reg [2:0] state;
    // States
    localparam IDLE = 3'b111;
    localparam MOVE_UP = 3'b000;
    localparam MOVE_DOWN = 3'b001;
    localparam MOVE_LEFT = 3'b010;
    localparam MOVE_RIGHT = 3'b011;

    // Linear Feedback Shift Register
    reg [7:0] lfsr_state;

    assign {up, down, left, right} =  (direction==2'b00) ? 4'b1000 : (direction==2'b01) ? 4'b0100 : (direction==2'b10) ? 4'b0010 : 4'b0001;

    always @(posedge clk or negedge rst /*or posedge change*/) begin
        if (!rst) begin
            // state = MOVE_RIGHT;
            // lfsr_state = 8'b1;  // Initial state != 0
            direction = 2'b00;
        end
        else begin
            if (x_enemy < x_tank)
                direction = 2'b11;
            else if (x_enemy > x_tank) 
                direction = 2'b10;
            else if (y_enemy < y_tank)
                direction = 2'b01;
            else if (y_enemy > y_tank)
                direction = 2'b00;
            
            
            

            // Update LFSR
            // lfsr_state = {lfsr_state[6:0], lfsr_state[0] ^ lfsr_state[2] ^ lfsr_state[4] ^ lfsr_state[6]};
            // // Change state
            // case (state)
            //     IDLE: begin
            //         state = {1'b0,lfsr_state[1:0]};
            //     end
            //     MOVE_UP: begin
            //         direction = 2'b00;
            //         state = IDLE;
            //     end
            //     MOVE_DOWN: begin
            //         direction = 2'b01;
            //         state = IDLE;
            //     end
            //     MOVE_LEFT: begin
            //         direction = 2'b10;
            //         state = IDLE;
            //     end
            //     MOVE_RIGHT: begin
            //         direction = 2'b11;
            //         state = IDLE;
            //     end
            // endcase
        end
    end
endmodule : moving