`timescale  1ns/1ps

module fsm_lights_tb;

    reg clk ,rst;
    wire red , green , yellow;

    fsm_lights #(
        .RED_TIME(5),
        .YELLOW_TIME(2),
        .GREEN_TIME(4)
    )   dut (
        .clk(clk),
        .rst(rst),
        .red(red),
        .yellow(yellow),
        .green(green)
    );

    always #5 clk = ~clk ;

    integer  cycle;
    reg [55:0] state_name;

    always @(*) begin
        if(red) state_name = "RED";
        else if (yellow) state_name = "YELLOW";
        else if (green) state_name = "GREEN";
        else state_name = "???";
    end

    initial begin


        $dumpfile("wave.vcd");
        $dumpvars(0, fsm_lights_tb);

        
        clk = 0;
        rst = 1;
        cycle = 0;

        $display("time\tstate R Y G");
        $monitor("%0t\t%s\t%b %b %b", $time, state_name, red, yellow, green);

        repeat(2) @(posedge clk);
        rst = 0;

        repeat(40) @(posedge clk);
    
        if (red+green+yellow !== 1)
            $display("ERROR : More than one lights are on ! ");
        else
            $display("PASS : one hot output check");

            $display("Simul finished");
            $finish;
        end
endmodule