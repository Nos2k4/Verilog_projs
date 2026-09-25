// ============================================================
// UART Receiver
// Samples at the MIDDLE of each bit using 16x oversampling.
// os_tick: a single-cycle pulse at 16x the baud rate.
// Includes a 2-FF synchronizer on the raw RX pin.
// ============================================================
module uart_rx (
    input  wire       clk,
    input  wire       rst,
    input  wire        os_tick,     // 16x baud-rate tick
    input  wire        rx_raw,      // asynchronous serial input pin
    output reg  [7:0]  rx_data,
    output reg          rx_valid    // 1-cycle pulse when a byte is ready
);

    // ---- 2-FF synchronizer: brings async rx_raw into our clock domain ----
    reg rx_sync0, rx_sync1;
    always @(posedge clk) begin
        rx_sync0 <= rx_raw;
        rx_sync1 <= rx_sync0;
    end
    wire rx = rx_sync1;

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [3:0] os_count;   // 0-15 counter within one bit period
    reg [2:0] bit_idx;    // which data bit (0-7)
    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            rx_valid <= 1'b0;
            os_count <= 4'd0;
            bit_idx  <= 3'd0;
        end else begin
            rx_valid <= 1'b0;   // default: pulse only for one cycle

            case (state)
                // Wait for the line to fall (start bit begins)
                IDLE: begin
                    if (!rx) begin
                        os_count <= 4'd0;
                        state    <= START;
                    end
                end

                // Confirm start bit at the MIDDLE of the bit period (count=7)
                // to reject glitches, then move to DATA
                START: if (os_tick) begin
                    if (os_count == 4'd7) begin
                        if (!rx) begin        // still low -> valid start bit
                            os_count <= 4'd0;
                            bit_idx  <= 3'd0;
                            state    <= DATA;
                        end else begin        // was a glitch, go back
                            state <= IDLE;
                        end
                    end else begin
                        os_count <= os_count + 1;
                    end
                end

                // Sample each data bit at its middle (count=15, i.e. 16 ticks later)
                DATA: if (os_tick) begin
                    if (os_count == 4'd15) begin
                        os_count <= 4'd0;
                        shift_reg <= {rx, shift_reg[7:1]};  // shift MSB<-rx, LSB first order
                        if (bit_idx == 3'd7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else begin
                        os_count <= os_count + 1;
                    end
                end

                // Sample stop bit at its middle, then output the byte
                STOP: if (os_tick) begin
                    if (os_count == 4'd15) begin
                        rx_data  <= shift_reg;
                        rx_valid <= rx;   // only flag valid if stop bit is 1 (framing check)
                        state    <= IDLE;
                    end else begin
                        os_count <= os_count + 1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule