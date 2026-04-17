// ============================================================================
// Top-level UART module for DE0-Nano (Cyclone IV EP4CE22F17C6)
//
// Hardware connections:
//   KEY[0]   = Reset (active-low)
//   KEY[1]   = Press to transmit (active-low, active on release)
//   SW[3:0]  = 4-bit data to send (lower nibble; upper nibble fixed to 0x4)
//   LED[7:0] = Last received byte displayed in binary
//   GPIO_0[0]= UART TX output  --> connect to other board's RX
//   GPIO_0[1]= UART RX input   <-- connect to other board's TX
//   GPIO_0[8:2]= 7-segment display (active-low: seg[6]=g ... seg[0]=a)
//
// Operation:
//   1. Set SW[3:0] to desired hex digit (0-F)
//   2. Press and release KEY[1] to transmit byte 0x4X
//   3. Received byte appears on LEDs and 7-segment display
// ============================================================================
module uart_top #(
    parameter integer CLK_FREQ  = 50_000_000,
    parameter integer BAUD_RATE = 9600
)(
    input  wire        CLOCK_50,       // 50 MHz clock
    input  wire [1:0]  KEY,            // Push buttons (active-low)
    input  wire [3:0]  SW,             // DIP switches
    output wire [7:0]  LED,            // LEDs
    output wire        GPIO_0_TX,      // UART TX (GPIO_0[0])
    input  wire        GPIO_0_RX,      // UART RX (GPIO_0[1])
    output wire [6:0]  GPIO_0_SEG      // 7-seg display (GPIO_0[8:2])
);

// ---- Internal signals ----
wire clk   = CLOCK_50;
wire rst_n = KEY[0];                   // KEY[0] active-low reset

wire [7:0] rx_data;
wire rx_valid;
wire rx_error;
wire tx_busy;

// ---- Button edge detector for KEY[1] (send on release) ----
reg [2:0] key1_sync;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        key1_sync <= 3'b111;
    else
        key1_sync <= {key1_sync[1:0], KEY[1]};
end
wire key1_rising = (key1_sync[2:1] == 2'b01); // released (low->high)

// ---- Transmit data: upper nibble 0x4, lower nibble from switches ----
wire [7:0] tx_data = {4'h4, SW[3:0]};  // e.g. SW=0001 sends 0x41='A'
wire       tx_start = key1_rising & ~tx_busy;

// ---- UART Transceiver ----
uart_transceiver #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) uart_inst (
    .clk(clk),
    .rst_n(rst_n),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .tx_busy(tx_busy),
    .tx(GPIO_0_TX),
    .rx(GPIO_0_RX),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .rx_error(rx_error)
);

// ---- Latch received data so it stays visible on LEDs / 7-seg ----
reg [7:0] rx_latch;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_latch <= 8'h00;
    else if (rx_valid)
        rx_latch <= rx_data;
end

assign LED = rx_latch;

// ---- 7-Segment display shows lower nibble of received byte ----
seven_seg_decoder seg_dec (
    .nibble(rx_latch[3:0]),
    .seg(GPIO_0_SEG)
);

endmodule

// ============================================================================
// 7-Segment Decoder (active-low outputs for common-anode display)
//   seg[0]=a, seg[1]=b, ... seg[6]=g
//   0 = segment ON, 1 = segment OFF
// ============================================================================
module seven_seg_decoder(
    input  wire [3:0] nibble,
    output reg  [6:0] seg       // {g, f, e, d, c, b, a}
);

always @(*) begin
    case (nibble)
        //                     gfedcba
        4'h0: seg = 7'b1000000;
        4'h1: seg = 7'b1111001;
        4'h2: seg = 7'b0100100;
        4'h3: seg = 7'b0110000;
        4'h4: seg = 7'b0011001;
        4'h5: seg = 7'b0010010;
        4'h6: seg = 7'b0000010;
        4'h7: seg = 7'b1111000;
        4'h8: seg = 7'b0000000;
        4'h9: seg = 7'b0010000;
        4'hA: seg = 7'b0001000;
        4'hB: seg = 7'b0000011;
        4'hC: seg = 7'b1000110;
        4'hD: seg = 7'b0100001;
        4'hE: seg = 7'b0000110;
        4'hF: seg = 7'b0001110;
        default: seg = 7'b1111111;
    endcase
end

endmodule
