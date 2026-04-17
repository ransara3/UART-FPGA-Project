// UART Transmitter: 8N1, parameterized clock and baud rate
module uart_tx #(
    parameter integer CLK_FREQ = 50000000,
    parameter integer BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire        tx_start,
    output reg         tx_busy,
    output reg         tx_serial
);

localparam integer CLK_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam integer BITS = 8;
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
        tx_serial  <= 1'b1;
        tx_busy    <= 1'b0;
    end else begin
        case (state)
            STATE_IDLE: begin
                tx_serial <= 1'b1;
                tx_busy   <= 1'b0;
                baud_cnt  <= 0;
                bit_cnt   <= 0;
                if (tx_start) begin
                    shift_reg <= data_in;
                    tx_busy   <= 1'b1;
                    state     <= STATE_START;
                end
            end
            STATE_START: begin
                tx_serial <= 1'b0;
                tx_busy   <= 1'b1;
                if (baud_cnt == CLK_PER_BIT - 1) begin
                    baud_cnt <= 0;
                    state    <= STATE_DATA;
                end else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end
            STATE_DATA: begin
                tx_serial <= shift_reg[0];
                tx_busy   <= 1'b1;
                if (baud_cnt == CLK_PER_BIT - 1) begin
                    baud_cnt <= 0;
                    shift_reg <= {1'b0, shift_reg[7:1]};
                    if (bit_cnt == BITS - 1) begin
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
                tx_serial <= 1'b1;
                tx_busy   <= 1'b1;
                if (baud_cnt == CLK_PER_BIT - 1) begin
                    baud_cnt <= 0;
                    state    <= STATE_IDLE;
                    tx_busy  <= 1'b0;
                end else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end
            default: state <= STATE_IDLE;
        endcase
    end
end

endmodule
