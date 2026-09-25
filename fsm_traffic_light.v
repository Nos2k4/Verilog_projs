`timescale 1ns/1ps

module fsm_lights #( 
    parameter  RED_TIME = 10, 
    parameter  GREEN_TIME = 8,
    parameter  YELLOW_TIME = 3 
)
(
    input wire clk,
    input wire rst,
    output reg red,
    output reg yellow,
    output reg green
);

    localparam S_red = 2'b00 ;
    localparam S_green = 2'b01;
    localparam S_yellow = 2'b10;

    reg [1:0] state , next_stage ;
    reg [$clog2(RED_TIME):0] counter ;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_red;
            counter <= 0;
        end 
        else if (state != next_stage) begin 
            state <= next_stage;
            counter <= 0;          
        end
        else begin 
            counter <= counter +1 ;
        end
    end

    always @(*) begin
        next_stage = state ; 
        case (state)
            S_red: if  (counter >= RED_TIME - 1) next_stage = S_green;
            S_green: if (counter >= GREEN_TIME -1) next_stage = S_yellow;
            S_yellow : if(counter >= YELLOW_TIME -1) next_stage = S_red;
            default: next_stage = S_red; 
        endcase
    end

    always @(*) begin
        red = (state == S_red );
        yellow = (state == S_yellow); 
        green = (state == S_green);
    end

endmodule