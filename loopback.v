`timescale 1ns/1ps
 
module uart_loopback_tb;
 
    reg clk, rst;
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_serial, tx_busy;
    wire [7:0] rx_data;
    wire rx_valid;
 
    reg baud_tick, os_tick;
    integer baud_div_count, os_div_count;
 
    // ---- Clock: 100MHz (10ns period) ----
    always #5 clk = ~clk;
 
    // ---- baud_tick every 64 clk cycles, os_tick every 4 clk cycles ----
    // (64 = 16 * 4, so os_tick fires exactly 16x per baud period)
    always @(posedge clk) begin
        if (rst) begin
            baud_div_count <= 0;
            os_div_count   <= 0;
            baud_tick      <= 0;
            os_tick        <= 0;
        end else begin
            baud_div_count <= (baud_div_count == 63) ? 0 : baud_div_count + 1;
            baud_tick      <= (baud_div_count == 63);
 
            os_div_count   <= (os_div_count == 3) ? 0 : os_div_count + 1;
            os_tick        <= (os_div_count == 3);
        end
    end
 
    uart_tx dut_tx (
        .clk(clk), .rst(rst),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx_serial),
        .tx_busy(tx_busy)
    );
 
    uart_rx dut_rx (
        .clk(clk), .rst(rst),
        .os_tick(os_tick),
        .rx_raw(tx_serial),     // direct loopback, no external noise
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );
 
    integer errors;
 
    task send_byte(input [7:0] b);
        begin
            @(posedge clk);
            tx_data  = b;
            tx_start = 1;
            @(posedge clk);
            tx_start = 0;
            // wait for TX to finish this byte
            wait (tx_busy == 0);
        end
    endtask

    initial begin

        $dumpfile("wave.vcd");
        $dumpvars(0, uart_loopback_tb);


        clk = 0; rst = 1; tx_start = 0; tx_data = 8'h00;
        errors = 0;
        repeat (5) @(posedge clk);
        rst = 0;
 
        send_byte(8'hA5);
        wait (rx_valid == 1);
        @(posedge clk);
        if (rx_data !== 8'hA5) begin
            $display("FAIL: expected A5, got %h", rx_data);
            errors = errors + 1;
        end else
            $display("PASS: byte A5 received correctly");
 
        send_byte(8'h3C);
        wait (rx_valid == 1);
        @(posedge clk);
        if (rx_data !== 8'h3C) begin
            $display("FAIL: expected 3C, got %h", rx_data);
            errors = errors + 1;
        end else
            $display("PASS: byte 3C received correctly");
 
        send_byte(8'h00);
        wait (rx_valid == 1);
        @(posedge clk);
        if (rx_data !== 8'h00) begin
            $display("FAIL: expected 00, got %h", rx_data);
            errors = errors + 1;
        end else
            $display("PASS: byte 00 received correctly");
 
        send_byte(8'hFF);
        wait (rx_valid == 1);
        @(posedge clk);
        if (rx_data !== 8'hFF) begin
            $display("FAIL: expected FF, got %h", rx_data);
            errors = errors + 1;
        end else
            $display("PASS: byte FF received correctly");
 
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);
 
        $finish;
    end
 
endmodule
 