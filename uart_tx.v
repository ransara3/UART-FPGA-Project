// UART Transmitter: 8N1/8E1/8O1, parameterized clock, baud rate, and parity
// PARITY_TYPE: 0=None (8N1), 1=Even (8E1), 2=Odd (8O1)
module uart_tx #(
    parameter integer CLK_FREQ    = 50_000_000,
    parameter integer BAUD_RATE   = 9600,
    parameter integer PARITY_TYPE = 0
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire        tx_start,
    output reg         tx_busy,
    output reg         tx_serial
);

localparam integer CLK_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam [2:0] STATE_IDLE   = 3'd0,
                 STATE_START  = 3'd1,
                 STATE_DATA   = 3'd2,
                 STATE_PARITY = 3'd3,
                 STATE_STOP   = 3'd4;

reg [2:0]  state;
reg [15:0] baud_cnt;
reg [3:0]  bit_cnt;
reg [7:0]  shift_reg;
reg        parity_bit;  // latched at tx_start

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state      <= STATE_IDLE;
        baud_cnt   <= 16'd0;
        bit_cnt    <= 4'd0;
        shift_reg  <= 8'h00;
        parity_bit <= 1'b0;
        tx_serial  <= 1'b1;
        tx_busy    <= 1'b0;
    end else begin
        case (state)
            STATE_IDLE: begin
                tx_serial <= 1'b1;
                tx_busy   <= 1'b0;
                baud_cnt  <= 16'd0;
                bit_cnt   <= 4'd0;
                if (tx_start) begin
                    shift_reg <= data_in;
                    // Compute and latch the parity bit for this frame
                    if (PARITY_TYPE == 1)        // Even: XOR of all data bits
                        parity_bit <= ^data_in;
                    else if (PARITY_TYPE == 2)   // Odd: inverted XOR
                        parity_bit <= ~^data_in;
                    else
                        parity_bit <= 1'b0;
                    tx_busy <= 1'b1;
                    state   <= STATE_START;
                end
            end
            STATE_START: begin
                tx_serial <= 1'b0;
                tx_busy   <= 1'b1;
                if (baud_cnt == CLK_PER_BIT - 1) begin
                    baud_cnt <= 16'd0;
                    state    <= STATE_DATA;
                end else begin
                    baud_cnt <= baud_cnt + 16'd1;
                end
            end
            STATE_DATA: begin
                tx_serial <= shift_reg[0];
                tx_busy   <= 1'b1;
                if (baud_cnt == CLK_PER_BIT - 1) begin
                    baud_cnt  <= 16'd0;
                    shift_reg <= {1'b0, shift_reg[7:1]};
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
                tx_serial <= parity_bit;
                tx_busy   <= 1'b1;
                if (baud_cnt == CLK_PER_BIT - 1) begin
                    baud_cnt <= 16'd0;
                    state    <= STATE_STOP;
                end else begin
                    baud_cnt <= baud_cnt + 16'd1;
                end
            end
            STATE_STOP: begin
                tx_serial <= 1'b1;
                tx_busy   <= 1'b1;
                if (baud_cnt == CLK_PER_BIT - 1) begin
                    baud_cnt <= 16'd0;
                    tx_busy  <= 1'b0;
                    state    <= STATE_IDLE;
                end else begin
                    baud_cnt <= baud_cnt + 16'd1;
                end
            end
            default: state <= STATE_IDLE;
        endcase
    end
end

endmodule
