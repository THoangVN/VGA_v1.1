module m100_counter(
    input clk,
    input reset,
    input  d_inc, //d_clr,
    output [3:0] dig0, dig1 , dig
    );
    
    // signal declaration
    reg [3:0] r_dig0, r_dig1,r_dig, dig0_next, dig1_next, dig_next;
    
    // register control
    always @(posedge clk or negedge reset)
        if(!reset) begin
            r_dig1 <= 0;
            r_dig0 <= 0;
            r_dig  <= 0;
        end
        
        else begin
            r_dig1 <= dig1_next;
            r_dig0 <= dig0_next;
            r_dig  <= dig_next ;
        end
    
    // next state logic
    always @(posedge d_inc or negedge reset) begin
        if(!reset)
        begin
            dig0_next  = 0;
            dig1_next  = 0;
            dig_next   = 0;
        end
        else
        begin
            dig0_next = r_dig0;
            dig1_next = r_dig1;
            dig_next  = r_dig;
            begin
                if(r_dig == 9) begin
                    dig_next = 0;
                    
                    if(r_dig0 == 9)
                    begin
                        dig0_next = 0;

                            if(r_dig1 == 9)
                                dig1_next = 0;
                            else
                                dig1_next = r_dig1 + 1;
                    end
                    else
                        dig0_next = r_dig0 + 1;
                end 
                else    // dig0 != 9
                    dig_next = r_dig + 1;
            end
        end
    end
    
    // output
    assign dig0 = r_dig0;
    assign dig1 = r_dig1;
    assign dig = r_dig;
    
    
endmodule