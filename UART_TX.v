// ============================================================
// UART Transmitter
// 8 data bits, 1 start bit, 1 stop bit, no parity
// baud_tick: a single-cycle pulse generated at the baud rate
//            (feed it from a baud rate generator / clock divider)
// ============================================================
module uart_tx (
    input  wire       clk,
    input  wire       rst,
    input  wire        baud_tick,   // 1-cycle pulse at bit rate
    input  wire        tx_start,    // pulse to begin transmission
    input  wire [7:0]  tx_data,
    output reg          tx,         // serial line (idle = 1)
    output reg          tx_busy
);

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [2:0] bit_idx;      // counts 0-7 for the 8 data bits
    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            tx       <= 1'b1;   // idle line is HIGH
            tx_busy  <= 1'b0;
            bit_idx  <= 3'd0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        tx_busy   <= 1'b1;
                        state     <= START;
                    end
                end

                START: if (baud_tick) begin
                    tx      <= 1'b0;      // start bit = 0
                    bit_idx <= 3'd0;
                    state   <= DATA;
                end

                DATA: if (baud_tick) begin
                    tx        <= shift_reg[0];
                    shift_reg <= shift_reg >> 1;
                    if (bit_idx == 3'd7)
                        state <= STOP;
                    else
                        bit_idx <= bit_idx + 1;
                end

                STOP: if (baud_tick) begin
                    tx      <= 1'b1;      // stop bit = 1
                    tx_busy <= 1'b0;
                    state   <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule