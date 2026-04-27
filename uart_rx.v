// UART Receiver: 8N1/8E1/8O1, parameterized clock, baud rate, and parity
// PARITY_TYPE: 0=None (8N1), 1=Even (8E1), 2=Odd (8O1)
module uart_rx #(
    parameter integer CLK_FREQ    = 50_000_000,
    parameter integer BAUD_RATE   = 9600,
    parameter integer PARITY_TYPE = 0
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx_serial,
    output reg  [7:0]  data_out,
    output reg         rx_valid,
    output reg         rx_error,
    output reg         parity_error  // parity mismatch (valid stop, wrong parity)
);

localparam integer CLK_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam integer HALF_BIT    = CLK_PER_BIT / 2;
// Sample stop bit at 3/4 of the bit period to prevent back-to-back frame lockups
localparam integer STOP_WAIT   = (CLK_PER_BIT * 3) / 4;

localparam [2:0] STATE_IDLE   = 3'd0,
                 STATE_START  = 3'd1,
                 STATE_DATA   = 3'd2,
                 STATE_PARITY = 3'd3,
                 STATE_STOP   = 3'd4;

reg [2:0]  state;
reg [15:0] baud_cnt;
reg [3:0]  bit_cnt;
reg [7:0]  shift_reg;
reg        parity_err_latch;  // holds parity result until stop-bit check

// Double-flop synchronizer registers
reg rx_sync_1;
reg rx_sync_2;

// Expected parity computed combinationally from the fully-received data bits
wire expected_parity = (PARITY_TYPE == 1) ? ^shift_reg    // Even
                                           : ~^shift_reg;  // Odd

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state            <= STATE_IDLE;
        baud_cnt         <= 16'd0;
        bit_cnt          <= 4'd0;
        shift_reg        <= 8'h00;
        data_out         <= 8'h00;
        rx_valid         <= 1'b0;
        rx_error         <= 1'b0;
        parity_error     <= 1'b0;
        parity_err_latch <= 1'b0;
        rx_sync_1        <= 1'b1;  // UART idles high
        rx_sync_2        <= 1'b1;
    end else begin
        // Double-flop the asynchronous input for metastability protection
        rx_sync_1 <= rx_serial;
        rx_sync_2 <= rx_sync_1;

        // Default: de-assert single-cycle output pulses
        rx_valid     <= 1'b0;
        rx_error     <= 1'b0;
        parity_error <= 1'b0;

        case (state)
            STATE_IDLE: begin
                if (!rx_sync_2) begin
                    state    <= STATE_START;
                    baud_cnt <= 16'd0;
                end
            end

            STATE_START: begin
                if (baud_cnt == HALF_BIT - 1) begin
                    if (!rx_sync_2) begin
                        baud_cnt         <= 16'd0;
                        bit_cnt          <= 4'd0;
                        parity_err_latch <= 1'b0;  // clear for new frame
                        state            <= STATE_DATA;
                    end else begin
                        state <= STATE_IDLE;  // false start bit
                    end
                end else begin
                    baud_cnt <= baud_cnt + 16'd1;
                end
            end

            STATE_DATA: begin
                if (baud_cnt == CLK_PER_BIT - 1) begin
                    baud_cnt  <= 16'd0;
                    shift_reg <= {rx_sync_2, shift_reg[7:1]};
                    if (bit_cnt == 4'd7) begin
                        bit_cnt <= 4'd0;
                        // Go to parity state only when parity is enabled
                        state   <= (PARITY_TYPE != 0) ? STATE_PARITY : STATE_STOP;
                    end else begin
                        bit_cnt <= bit_cnt + 4'd1;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 16'd1;
                end
            end

            STATE_PARITY: begin
                if (baud_cnt == CLK_PER_BIT - 1) begin
                    baud_cnt <= 16'd0;
                    // Sample received parity bit and compare with expected
                    if (rx_sync_2 != expected_parity)
                        parity_err_latch <= 1'b1;
                    state <= STATE_STOP;
                end else begin
                    baud_cnt <= baud_cnt + 16'd1;
                end
            end

            STATE_STOP: begin
                // Check stop bit early to prevent back-to-back frame lockups
                if (baud_cnt == STOP_WAIT - 1) begin
                    baud_cnt <= 16'd0;
                    if (rx_sync_2) begin
                        // Valid stop bit — check parity result
                        if (!parity_err_latch) begin
                            data_out <= shift_reg;
                            rx_valid <= 1'b1;
                        end else begin
                            parity_error <= 1'b1;  // parity mismatch
                        end
                    end else begin
                        rx_error <= 1'b1;  // framing error: stop bit not high
                    end
                    state <= STATE_IDLE;
                end else begin
                    baud_cnt <= baud_cnt + 16'd1;
                end
            end

            default: state <= STATE_IDLE;
        endcase
    end
end

endmodule