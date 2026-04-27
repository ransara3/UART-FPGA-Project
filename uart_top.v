// ============================================================================
// Top-level UART module for DE0-Nano (Cyclone IV EP4CE22F17C6)
//
// Hardware connections:
//   KEY[0]        = Reset (active-low, press once on power-up)
//   KEY[1]        = Press to transmit (active-low)
//   EXT_SW[7:0]   = External 8-bit DIP switch on GPIO_1
//   LED[7:0]      = Shows EXACT 8-bit received byte
//   GPIO_0_TX (PIN_D3)   = UART TX output
//   GPIO_0_RX (PIN_A8)   = UART RX input
//   SEG_UPPER[6:0] = 7-seg display for bits [7:4] (Common-Cathode, 1=ON)
//                   Shows  --  (middle segment only) on parity error
//   SEG_LOWER[6:0] = 7-seg display for bits [3:0] (Common-Cathode, 1=ON)
//                   Shows  --  (middle segment only) on parity error
// ============================================================================
module uart_top #(
    parameter integer CLK_FREQ    = 50_000_000,
    parameter integer BAUD_RATE   = 9600,
    parameter integer PARITY_TYPE = 1  // 0=None (8N1), 1=Even (8E1), 2=Odd (8O1)
)(
    input  wire        CLOCK_50,
    input  wire [1:0]  KEY,
    input  wire [7:0]  EXT_SW,     
    output wire [7:0]  LED,
    output wire        GPIO_0_TX,
    input  wire        GPIO_0_RX,
    output wire [6:0]  SEG_UPPER,  // Added upper display
    output wire [6:0]  SEG_LOWER   // Added lower display
);

wire clk   = CLOCK_50;
wire rst_n = KEY[0];

wire [7:0] rx_data;
wire       rx_valid;
wire       rx_error;
wire       parity_error;  // high for one cycle on parity mismatch
wire       tx_busy;
wire       tx_wire;

// ---- RX/TX Connections ----
wire rx_line = GPIO_0_RX; 
assign GPIO_0_TX = tx_wire;

// ---- KEY[1] edge detector (triggers on press, i.e. falling edge) ----
reg [2:0] key1_sync;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        key1_sync <= 3'b111;
    else
        key1_sync <= {key1_sync[1:0], KEY[1]};
end
wire key1_pressed = (key1_sync[2:1] == 2'b10);

// ---- TX data from external 8-bit DIP switches ----
wire [7:0] tx_data  = EXT_SW[7:0]; 
wire       tx_start = key1_pressed & ~tx_busy;

// ---- UART Transceiver ----
uart_transceiver #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .PARITY_TYPE(PARITY_TYPE)
) uart_inst (
    .clk(clk),
    .rst_n(rst_n),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .tx_busy(tx_busy),
    .tx(tx_wire),
    .rx(rx_line),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .rx_error(rx_error),
    .parity_error(parity_error)
);

// ---- Latch received byte ----
reg [7:0] rx_latch;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_latch <= 8'h00;
    else if (rx_valid)
        rx_latch <= rx_data;
end

// ---- Parity error latch: set on parity_error, cleared on next good frame ----
reg parity_err_latch;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        parity_err_latch <= 1'b0;
    else if (parity_error)
        parity_err_latch <= 1'b1;
    else if (rx_valid)
        parity_err_latch <= 1'b0;
end

// ---- ALL 8 LEDs mapped directly to received data ----
assign LED = rx_latch;

// ---- 7-Segment decoder outputs ----
wire [6:0] seg_upper_hex;
wire [6:0] seg_lower_hex;

seven_seg_decoder_hex seg_dec_upper (
    .nibble(rx_latch[7:4]),
    .seg(seg_upper_hex)
);

seven_seg_decoder_hex seg_dec_lower (
    .nibble(rx_latch[3:0]),
    .seg(seg_lower_hex)
);

// ---- Override both displays with middle segment (dash) on parity error ----
// seg = {g,f,e,d,c,b,a} -> 7'b1000000 = only middle segment ON
assign SEG_UPPER = parity_err_latch ? 7'b1000000 : seg_upper_hex;
assign SEG_LOWER = parity_err_latch ? 7'b1000000 : seg_lower_hex;

endmodule

// ============================================================================
// 4-bit Hex to 7-Segment Decoder 
// COMMON-CATHODE (Active-High: 1 = ON, 0 = OFF)
// seg = {g, f, e, d, c, b, a}
// ============================================================================
module seven_seg_decoder_hex(
    input  wire [3:0] nibble,
    output reg  [6:0] seg
);
always @(*) begin
    case (nibble)
        4'h0: seg = 7'b0111111; // 0
        4'h1: seg = 7'b0000110; // 1
        4'h2: seg = 7'b1011011; // 2
        4'h3: seg = 7'b1001111; // 3
        4'h4: seg = 7'b1100110; // 4
        4'h5: seg = 7'b1101101; // 5
        4'h6: seg = 7'b1111101; // 6
        4'h7: seg = 7'b0000111; // 7
        4'h8: seg = 7'b1111111; // 8
        4'h9: seg = 7'b1101111; // 9
        4'hA: seg = 7'b1110111; // A
        4'hB: seg = 7'b1111100; // b
        4'hC: seg = 7'b0111001; // C
        4'hD: seg = 7'b1011110; // d
        4'hE: seg = 7'b1111001; // E
        4'hF: seg = 7'b1110001; // F
        default: seg = 7'b0000000; // Turn off entirely if undefined
    endcase
end
endmodule