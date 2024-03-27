module map_1 #( parameter number_of_brick = 100,
                parameter number_of_iron = 10)(
    input clk_50MHz,   // sys clock
    input reset,        // sys reset
    input [9:0] x,      // from VGA controller
    input [9:0] y,      // from VGA controller
    input refresh_tick,
    input [9:0] x_tank_r,
    input [9:0] x_tank_l,
    input [9:0] y_tank_t,
    input [9:0] y_tank_b,
    input [9:0] x_enemy_r,
    input [9:0] x_enemy_l,
    input [9:0] y_enemy_t,
    input [9:0] y_enemy_b,
    input [9:0] x_enemy_r_2,
    input [9:0] x_enemy_l_2,
    input [9:0] y_enemy_t_2,
    input [9:0] y_enemy_b_2,
    input [9:0] x_enemy_r_3,
    input [9:0] x_enemy_l_3,
    input [9:0] y_enemy_t_3,
    input [9:0] y_enemy_b_3,
    input [9:0] x_bullet_r,
    input [9:0] x_bullet_l,
    input [9:0] y_bullet_t,
    input [9:0] y_bullet_b,
    input [9:0] x_bullet_enemy,
    input [9:0] y_bullet_enemy,
    input [9:0] x_bullet_enemy_2,
    input [9:0] y_bullet_enemy_2,
    input [9:0] x_bullet_enemy_3,
    input [9:0] y_bullet_enemy_3,
    input [9:0] bullet_size,
    output hit,
    output hit_by_enemy,
    output hit_by_enemy_2,
    output hit_by_enemy_3,
    output wire [number_of_brick+number_of_iron-1:0] stop_go_up,
    output wire [number_of_brick+number_of_iron-1:0] stop_go_down,
    output wire [number_of_brick+number_of_iron-1:0] stop_go_left,
    output wire [number_of_brick+number_of_iron-1:0] stop_go_right,
    output wire [number_of_brick+number_of_iron-1:0] stop_enemy_go_up,
    output wire [number_of_brick+number_of_iron-1:0] stop_enemy_go_down,
    output wire [number_of_brick+number_of_iron-1:0] stop_enemy_go_left,
    output wire [number_of_brick+number_of_iron-1:0] stop_enemy_go_right,
    output wire [number_of_brick+number_of_iron-1:0] stop_enemy_go_up_2,
    output wire [number_of_brick+number_of_iron-1:0] stop_enemy_go_down_2,
    output wire [number_of_brick+number_of_iron-1:0] stop_enemy_go_left_2,
    output wire [number_of_brick+number_of_iron-1:0] stop_enemy_go_right_2,
    output wire [number_of_brick+number_of_iron-1:0] stop_enemy_go_up_3,
    output wire [number_of_brick+number_of_iron-1:0] stop_enemy_go_down_3,
    output wire [number_of_brick+number_of_iron-1:0] stop_enemy_go_left_3,
    output wire [number_of_brick+number_of_iron-1:0] stop_enemy_go_right_3,
    output wire [number_of_brick-1:0] brick_on,
    output wire [29:0] brick_rom_data,
    output wire wall_on,  
    output wire [29:0] wall_rom_data,
    output wire [number_of_iron-1:0] iron_on,
    output wire [29:0] iron_rom_data
    );
    
    wire [9:0] x_brick_l [number_of_brick];
    wire [9:0] x_brick_r [number_of_brick];
    wire [9:0] y_brick_t [number_of_brick];
    wire [9:0] y_brick_b [number_of_brick];
    reg  [9:0] x_brick_register [number_of_brick];
    reg  [9:0] y_brick_register [number_of_brick];
    reg  [9:0] x_brick_next [number_of_brick];
    reg  [9:0] y_brick_next [number_of_brick];
    
    wire [9:0] x_iron_l [number_of_iron];
    wire [9:0] x_iron_r [number_of_iron];
    wire [9:0] y_iron_t [number_of_iron];
    wire [9:0] y_iron_b [number_of_iron];
    reg  [9:0] x_iron_register [number_of_iron];
    reg  [9:0] y_iron_register [number_of_iron];

    brick_rom   brick_unit  (.clk(clk_50MHz), .row(y), .col(x), .color_data(brick_rom_data));
    wall_rom    wall_unit   (.clk(clk_50MHz), .row(y), .col(x), .color_data(wall_rom_data));
    iron_rom    iron_unit   (.clk(clk_50MHz), .row(y), .col(x), .color_data(iron_rom_data));

    always @(posedge clk_50MHz or negedge reset) begin
        if (!reset) begin
            // IRON
                x_iron_register[0] = 288;
                y_iron_register[0] = 256;
                x_iron_register[1] = 320;
                y_iron_register[1] = 256;
                x_iron_register[2] = 352;
                y_iron_register[2] = 256;
                
                x_iron_register[3] = 128;
                y_iron_register[3] = 256;
                x_iron_register[4] = 192;
                y_iron_register[4] = 256;
                x_iron_register[5] = 160;
                y_iron_register[5] = 256;
                
                x_iron_register[6] = 448;
                y_iron_register[6] = 256;
                x_iron_register[7] = 480;
                y_iron_register[7] = 256;
                x_iron_register[8] = 512;
                y_iron_register[8] = 256;
            // 20 Bricks Cover Eagle
                //    **
                //   ****
                //  ******
                //  **  **
                //  **  **
                // Column 1
                    x_brick_register[0] = 288;
                    y_brick_register[0] = 432;

                    x_brick_register[1] = 288;
                    y_brick_register[1] = 416;

                    x_brick_register[2] = 288;
                    y_brick_register[2] = 400;
                // Column 2
                    x_brick_register[3] = 304;
                    y_brick_register[3] = 432;

                    x_brick_register[4] = 304;
                    y_brick_register[4] = 416;

                    x_brick_register[5] = 304;
                    y_brick_register[5] = 400;

                    x_brick_register[6] = 304;
                    y_brick_register[6] = 384;
                // Column 3
                    x_brick_register[7] = 320;
                    y_brick_register[7] = 400;

                    x_brick_register[8] = 320;
                    y_brick_register[8] = 384;

                    x_brick_register[9] = 320;
                    y_brick_register[9] = 368;
                // Column 4
                    x_brick_register[10] = 336;
                    y_brick_register[10] = 400;

                    x_brick_register[11] = 336;
                    y_brick_register[11] = 384;

                    x_brick_register[12] = 336;
                    y_brick_register[12] = 368;
                // Column 5
                    x_brick_register[13] = 352;
                    y_brick_register[13] = 432;

                    x_brick_register[14] = 352;
                    y_brick_register[14] = 416;

                    x_brick_register[15] = 352;
                    y_brick_register[15] = 400;

                    x_brick_register[16] = 352;
                    y_brick_register[16] = 384;
                // Column 6
                    x_brick_register[17] = 368;
                    y_brick_register[17] = 432;

                    x_brick_register[18] = 368;
                    y_brick_register[18] = 416;

                    x_brick_register[19] = 368;
                    y_brick_register[19] = 400;
            // Build map
                x_brick_register[20] = 96;
                y_brick_register[20] = 80;
                for (int i = 1; i <= 20 ; i++) begin
                    y_brick_register[20+i] = y_brick_register[20+i-1] + 16;
                    x_brick_register[20+i] = x_brick_register[20+i-1];
                end
                
                x_brick_register[41] = 240;
                y_brick_register[41] = 80;
                for (int i = 1; i <= 20 ; i++) begin
                    y_brick_register[41+i] = y_brick_register[41+i-1] + 16;
                    x_brick_register[41+i] = x_brick_register[41+i-1];
                end
                
                x_brick_register[62] = 544;
                y_brick_register[62] = 80;
                for (int i = 1; i <= 20 ; i++) begin
                    y_brick_register[62+i] = y_brick_register[62+i-1] + 16;
                    x_brick_register[62+i] = x_brick_register[62+i-1];
                end
                
                x_brick_register[83] = 96+16;
                y_brick_register[83] = 80;
                for (int i = 1; i <= 20 ; i++) begin
                    y_brick_register[83+i] = y_brick_register[83+i-1] + 16;
                    x_brick_register[83+i] = x_brick_register[83+i-1];
                end

                x_brick_register[104] = 240+16;
                y_brick_register[104] = 80;
                for (int i = 1; i <= 20 ; i++) begin
                    y_brick_register[104+i] = y_brick_register[104+i-1] + 16;
                    x_brick_register[104+i] = x_brick_register[104+i-1];
                end

                x_brick_register[125] = 544+16;
                y_brick_register[125] = 80;
                for (int i = 1; i <= 20 ; i++) begin
                    y_brick_register[125+i] = y_brick_register[125+i-1] + 16;
                    x_brick_register[125+i] = x_brick_register[125+i-1];
                end

                x_brick_register[146] = 400;
                y_brick_register[146] = 80;
                for (int i = 1; i <= 20 ; i++) begin
                    y_brick_register[146+i] = y_brick_register[146+i-1] + 16;
                    x_brick_register[146+i] = x_brick_register[146+i-1];
                end

                x_brick_register[167] = 400+16;
                y_brick_register[167] = 80;
                for (int i = 1; i <= 20 ; i++) begin
                    y_brick_register[167+i] = y_brick_register[167+i-1] + 16;
                    x_brick_register[167+i] = x_brick_register[167+i-1];
                end
        end
        else begin
            // State update logic
            x_brick_register[0] <= x_brick_next[0];
            y_brick_register[0] <= y_brick_next[0];
            for (int i = 1; i < number_of_brick; i++) begin
                x_brick_register[i] <= x_brick_next[i];
                y_brick_register[i] <= y_brick_next[i];
            end
        end
    end

    always @* begin
        // Update logic for x_brick_next and y_brick_next
        for (int i = 0; i < number_of_brick; i++) begin
            y_brick_next[i] = y_brick_register[i];
            x_brick_next[i] = x_brick_register[i];
        end
        if (refresh_tick)
        begin
            hit = 0;
            hit_by_enemy = 0;
            hit_by_enemy_2 = 0;
            hit_by_enemy_3 = 0;
            for (int i = 0; i < number_of_brick; i++) begin
                if ((y_bullet_t < (y_brick_register[i] + 15)) && (y_bullet_b > y_brick_register[i]) && (x_bullet_l < (x_brick_register[i] + 15)) && (x_bullet_r > x_brick_register[i]))
                begin
                    x_brick_next[i] = 0;
                    y_brick_next[i] = 0;
                    hit <= 1;
                end
                if ((y_bullet_enemy < (y_brick_register[i] + 15)) && ((y_bullet_enemy + 3) > y_brick_register[i]) && (x_bullet_enemy < (x_brick_register[i] + 15)) && ((x_bullet_enemy+3) > x_brick_register[i]))
                begin
                    x_brick_next[i] = 0;
                    y_brick_next[i] = 0;
                    hit_by_enemy <= 1;
                end
                if ((y_bullet_enemy_2 < (y_brick_register[i] + 15)) && ((y_bullet_enemy_2 + 3) > y_brick_register[i]) && (x_bullet_enemy_2 < (x_brick_register[i] + 15)) && ((x_bullet_enemy_2+3) > x_brick_register[i]))
                begin
                    x_brick_next[i] = 0;
                    y_brick_next[i] = 0;
                    hit_by_enemy_2 <= 1;
                end
                if ((y_bullet_enemy_3 < (y_brick_register[i] + 15)) && ((y_bullet_enemy_3 + 3) > y_brick_register[i]) && (x_bullet_enemy_3 < (x_brick_register[i] + 15)) && ((x_bullet_enemy_3+3) > x_brick_register[i]))
                begin
                    x_brick_next[i] = 0;
                    y_brick_next[i] = 0;
                    hit_by_enemy_3 <= 1;
                end
            end

            for (int j = 0; j < number_of_iron; j++) begin
                if ((y_bullet_t < (y_iron_register[j] + 31)) && (y_bullet_b > y_iron_register[j]) && (x_bullet_l < (x_iron_register[j] + 31)) && (x_bullet_r > x_iron_register[j]))
                    hit <= 1;
                if ((y_bullet_enemy < (y_iron_register[j] + 31)) && ((y_bullet_enemy + 3) > y_iron_register[j]) && (x_bullet_enemy < (x_iron_register[j] + 31)) && ((x_bullet_enemy+3) > x_iron_register[j]))
                    hit_by_enemy <= 1;
                if ((y_bullet_enemy_2 < (y_iron_register[j] + 31)) && ((y_bullet_enemy_2 + 3) > y_iron_register[j]) && (x_bullet_enemy_2 < (x_iron_register[j] + 31)) && ((x_bullet_enemy_2+3) > x_iron_register[j]))
                    hit_by_enemy_2 <= 1;
                if ((y_bullet_enemy_3 < (y_iron_register[j] + 31)) && ((y_bullet_enemy_3 + 3) > y_iron_register[j]) && (x_bullet_enemy_3 < (x_iron_register[j] + 31)) && ((x_bullet_enemy_3+3) > x_iron_register[j]))
                    hit_by_enemy_3 <= 1;
            end
        end
    end

    // BRICK (detroyable)
    genvar i;
    generate
        for (i=0; i < number_of_brick; i++) begin : assign1
            assign_border x_border      (x_brick_register[i], x_brick_l[i], x_brick_r[i]);
            assign_border y_border      (y_brick_register[i], y_brick_t[i], y_brick_b[i]);
            // STOP FOR TANK
            assign_stop   stop_up_1     (y_brick_b[i]+2, x_brick_l[i], x_brick_r[i], y_tank_t, x_tank_l, x_tank_r, stop_go_up[i]);
            assign_stop   stop_down_1   (y_brick_t[i]-2, x_brick_l[i], x_brick_r[i], y_tank_b, x_tank_l, x_tank_r, stop_go_down[i]);
            assign_stop   stop_left_1   (x_brick_r[i]+2, y_brick_t[i], y_brick_b[i], x_tank_l, y_tank_t, y_tank_b, stop_go_left[i]);
            assign_stop   stop_right_1  (x_brick_l[i]-2, y_brick_t[i], y_brick_b[i], x_tank_r, y_tank_t, y_tank_b, stop_go_right[i]);
            // STOP FOR ENEMY
            assign_stop   stop_up_2     (y_brick_b[i]+2, x_brick_l[i], x_brick_r[i], y_enemy_t, x_enemy_l, x_enemy_r, stop_enemy_go_up[i]);
            assign_stop   stop_down_2   (y_brick_t[i]-2, x_brick_l[i], x_brick_r[i], y_enemy_b, x_enemy_l, x_enemy_r, stop_enemy_go_down[i]);
            assign_stop   stop_left_2   (x_brick_r[i]+2, y_brick_t[i], y_brick_b[i], x_enemy_l, y_enemy_t, y_enemy_b, stop_enemy_go_left[i]);
            assign_stop   stop_right_2  (x_brick_l[i]-2, y_brick_t[i], y_brick_b[i], x_enemy_r, y_enemy_t, y_enemy_b, stop_enemy_go_right[i]);

            assign_stop   stop_up_3     (y_brick_b[i]+2, x_brick_l[i], x_brick_r[i], y_enemy_t_2, x_enemy_l_2, x_enemy_r_2, stop_enemy_go_up_2[i]);
            assign_stop   stop_down_3   (y_brick_t[i]-2, x_brick_l[i], x_brick_r[i], y_enemy_b_2, x_enemy_l_2, x_enemy_r_2, stop_enemy_go_down_2[i]);
            assign_stop   stop_left_3   (x_brick_r[i]+2, y_brick_t[i], y_brick_b[i], x_enemy_l_2, y_enemy_t_2, y_enemy_b_2, stop_enemy_go_left_2[i]);
            assign_stop   stop_right_3  (x_brick_l[i]-2, y_brick_t[i], y_brick_b[i], x_enemy_r_2, y_enemy_t_2, y_enemy_b_2, stop_enemy_go_right_2[i]);
            
            assign_stop   stop_up_4     (y_brick_b[i]+2, x_brick_l[i], x_brick_r[i], y_enemy_t_3, x_enemy_l_3, x_enemy_r_3, stop_enemy_go_up_3[i]);
            assign_stop   stop_down_4   (y_brick_t[i]-2, x_brick_l[i], x_brick_r[i], y_enemy_b_3, x_enemy_l_3, x_enemy_r_3, stop_enemy_go_down_3[i]);
            assign_stop   stop_left_4   (x_brick_r[i]+2, y_brick_t[i], y_brick_b[i], x_enemy_l_3, y_enemy_t_3, y_enemy_b_3, stop_enemy_go_left_3[i]);
            assign_stop   stop_right_4  (x_brick_l[i]-2, y_brick_t[i], y_brick_b[i], x_enemy_r_3, y_enemy_t_3, y_enemy_b_3, stop_enemy_go_right_3[i]);
            assign brick_on[i] = (x >= x_brick_l[i]) && (x <= x_brick_r[i]) && (y >= y_brick_t[i]) && (y <= y_brick_b[i]);
        end
    endgenerate

    // IRON (none detroyeable)
    genvar j;
    generate
        for (j=0; j < number_of_iron; j++) begin : assign2
            assign_border #(31) x_border_iron   (x_iron_register[j], x_iron_l[j], x_iron_r[j]);
            assign_border #(31) y_border_iron   (y_iron_register[j], y_iron_t[j], y_iron_b[j]);
            // STOP FOR TANK
            assign_stop   iron_stop_up_1        (y_iron_b[j]+2, x_iron_l[j], x_iron_r[j], y_tank_t, x_tank_l, x_tank_r, stop_go_up   [j+number_of_brick]);
            assign_stop   iron_stop_down_1      (y_iron_t[j]-2, x_iron_l[j], x_iron_r[j], y_tank_b, x_tank_l, x_tank_r, stop_go_down [j+number_of_brick]);
            assign_stop   iron_stop_left_1      (x_iron_r[j]+2, y_iron_t[j], y_iron_b[j], x_tank_l, y_tank_t, y_tank_b, stop_go_left [j+number_of_brick]);
            assign_stop   iron_stop_right_1     (x_iron_l[j]-2, y_iron_t[j], y_iron_b[j], x_tank_r, y_tank_t, y_tank_b, stop_go_right[j+number_of_brick]);
            // STOP FOR ENEMY
            assign_stop   iron_stop_up_2        (y_iron_b[j]+2, x_iron_l[j], x_iron_r[j], y_enemy_t, x_enemy_l, x_enemy_r, stop_enemy_go_up   [j+number_of_brick]);
            assign_stop   iron_stop_down_2      (y_iron_t[j]-2, x_iron_l[j], x_iron_r[j], y_enemy_b, x_enemy_l, x_enemy_r, stop_enemy_go_down [j+number_of_brick]);
            assign_stop   iron_stop_left_2      (x_iron_r[j]+2, y_iron_t[j], y_iron_b[j], x_enemy_l, y_enemy_t, y_enemy_b, stop_enemy_go_left [j+number_of_brick]);
            assign_stop   iron_stop_right_2     (x_iron_l[j]-2, y_iron_t[j], y_iron_b[j], x_enemy_r, y_enemy_t, y_enemy_b, stop_enemy_go_right[j+number_of_brick]);

            assign_stop   iron_stop_up_3        (y_iron_b[j]+2, x_iron_l[j], x_iron_r[j], y_enemy_t_2, x_enemy_l_2, x_enemy_r_2, stop_enemy_go_up_2   [j+number_of_brick]);
            assign_stop   iron_stop_down_3      (y_iron_t[j]-2, x_iron_l[j], x_iron_r[j], y_enemy_b_2, x_enemy_l_2, x_enemy_r_2, stop_enemy_go_down_2 [j+number_of_brick]);
            assign_stop   iron_stop_left_3      (x_iron_r[j]+2, y_iron_t[j], y_iron_b[j], x_enemy_l_2, y_enemy_t_2, y_enemy_b_2, stop_enemy_go_left_2 [j+number_of_brick]);
            assign_stop   iron_stop_right_3     (x_iron_l[j]-2, y_iron_t[j], y_iron_b[j], x_enemy_r_2, y_enemy_t_2, y_enemy_b_2, stop_enemy_go_right_2[j+number_of_brick]);
            
            assign_stop   iron_stop_up_4        (y_iron_b[j]+2, x_iron_l[j], x_iron_r[j], y_enemy_t_3, x_enemy_l_3, x_enemy_r_3, stop_enemy_go_up_3   [j+number_of_brick]);
            assign_stop   iron_stop_down_4      (y_iron_t[j]-2, x_iron_l[j], x_iron_r[j], y_enemy_b_3, x_enemy_l_3, x_enemy_r_3, stop_enemy_go_down_3 [j+number_of_brick]);
            assign_stop   iron_stop_left_4      (x_iron_r[j]+2, y_iron_t[j], y_iron_b[j], x_enemy_l_3, y_enemy_t_3, y_enemy_b_3, stop_enemy_go_left_3 [j+number_of_brick]);
            assign_stop   iron_stop_right_4     (x_iron_l[j]-2, y_iron_t[j], y_iron_b[j], x_enemy_r_3, y_enemy_t_3, y_enemy_b_3, stop_enemy_go_right_3[j+number_of_brick]);
            assign iron_on[j] = (x >= x_iron_l[j]) && (x <= x_iron_r[j]) && (y >= y_iron_t[j]) && (y <= y_iron_b[j]);
        end
    endgenerate

    assign wall_on = !((x > 31) && (x < 608) && (y > 31) && (y < 448));

endmodule : map_1

module assign_border #(parameter n = 15)(
    input  [9:0] brick_reg,
    output [9:0] brick_out_1,
    output [9:0] brick_out_2
    );
    assign brick_out_1 = brick_reg;
    assign brick_out_2 = brick_reg + n;
endmodule : assign_border

module assign_stop(
    input  [9:0] brick_border_1,
    input  [9:0] brick_border_2,
    input  [9:0] brick_border_3,
    input  [9:0] tank_border_1,
    input  [9:0] tank_border_2,
    input  [9:0] tank_border_3,
    output stop
    );
    assign stop = (brick_border_1 == tank_border_1) && ((tank_border_3 <= brick_border_3 + 32) && (tank_border_2 >= brick_border_2 - 32));
endmodule