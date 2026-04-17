// UART Receiver: 8N1, parameterized clock and baud rate
module uart_rx #(
    parameter integer CLK_FREQ = 50000000,
    parameter integer BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx_serial,
    output reg [7:0]  data_out,
    output reg         rx_valid,
    output reg         rx_error
);

localparam integer CLK_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam integer HALF_BIT = CLK_PER_BIT / 2;
localparam [1:0] STATE_IDLE  = 2'd0,
                 STATE_START = 2'd1,
                 STATE_DATA  = 2'd2,
                 STATE_STOP  = 2'd3;

reg [1:0] state;
reg [15:0] baud_cnt;
reg [3:0] bit_cnt;
reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state      <= STATE_IDLE;
        baud_cnt   <= 0;
        bit_cnt    <= 0;
        shift_reg  <= 8'h00;
        data_out   <= 8'h00;
        rx_valid   <= 1'b0;
        rx_error   <= 1'b0;
    end else begin
        rx_valid <= 1'b0;
        rx_error <= 1'b0;
        case (state)
            STATE_IDLE: begin
                if (!rx_serial) begin
                    state    <= STATE_START;
                    baud_cnt <= 0;
                end
            end
            STATE_START: begin
                if (baud_cnt == HALF_BIT - 1) begin
                    if (!rx_serial) begin
                        baud_cnt <= 0;
                        bit_cnt  <= 0;
                        state    <= STATE_DATA;
                    end else begin
                        state <= STATE_IDLE;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end
            STATE_DATA: begin
                if (baud_cnt == CLK_PER_BIT - 1) begin
                    baud_cnt <= 0;
                    shift_reg <= {rx_serial, shift_reg[7:1]};
                    if (bit_cnt == 7) begin
                        bit_cnt <= 0;
                        state   <= STATE_STOP;
                    end else begin
                        bit_cnt <= bit_cnt + 1;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end
            STATE_STOP: begin
                if (baud_cnt == CLK_PER_BIT - 1) begin
                    baud_cnt <= 0;
                    if (rx_serial) begin
                        data_out <= shift_reg;
                        rx_valid <= 1'b1;
                        state    <= STATE_IDLE;
                    end else begin
                        rx_error <= 1'b1;
                        state    <= STATE_IDLE;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end
            default: state <= STATE_IDLE;
        endcase
    end
end

endmodule
