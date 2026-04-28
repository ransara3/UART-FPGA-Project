`timescale 1ns / 1ps

module uart_tb;

// Board-specific parameters
localparam CLK_FREQ    = 50_000_000;
localparam BAUD_RATE   = 9600;
localparam PARITY_TYPE = 1;          // 1 = Even Parity

localparam CLK_NS   = 1_000_000_000 / CLK_FREQ;
localparam BIT_TIME = 1_000_000_000 / BAUD_RATE; 

reg        clk = 0;
reg        rst_n = 0;
reg  [7:0] tx_data_in;
reg        tx_start;
wire       tx_busy;

wire       tx_raw_out;   // What the transmitter actually sends
reg        noise_strike; // Our manual error trigger
wire       serial_wire;  // The physical wire with potential noise

wire [7:0] rx_data_out;
wire       rx_valid;
wire       rx_error;
wire       parity_error;

// Generate 50 MHz Clock
always #(CLK_NS/2) clk = ~clk;

// --- THE FAULT INJECTOR ---
// If noise_strike is 0, the wire acts normally.
// If noise_strike is 1, it forcibly inverts the voltage on the wire.
assign serial_wire = noise_strike ? ~tx_raw_out : tx_raw_out;

// Transmitter
uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .PARITY_TYPE(PARITY_TYPE)) tx_inst (
    .clk(clk), .rst_n(rst_n), .data_in(tx_data_in), .tx_start(tx_start),
    .tx_busy(tx_busy), .tx_serial(tx_raw_out)
);

// Receiver
uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE), .PARITY_TYPE(PARITY_TYPE)) rx_inst (
    .clk(clk), .rst_n(rst_n), .rx_serial(serial_wire),
    .data_out(rx_data_out), .rx_valid(rx_valid),
    .rx_error(rx_error), .parity_error(parity_error)
);

initial begin
    $display("==================================================");
    $display(" UART Parity & Error Injection Testbench");
    $display("==================================================");

    noise_strike = 0;
    tx_start     = 0;
    tx_data_in   = 8'h00;
    rst_n        = 0;
    #200; rst_n  = 1; #200;

    // ---------------------------------------------------------
    // TEST 1: Send 'C' (0x43 / 01000011) -> 3 ones. 
    // EXPECT: Parity bit must be '1' to make total even.
    // ---------------------------------------------------------
    $display("Test 1: Sending 'C' (Normal)...");
    @(posedge clk);
    tx_data_in = 8'h43;
    tx_start   = 1;
    @(posedge clk);
    tx_start   = 0;
    wait(tx_busy == 0);
    #(BIT_TIME * 2);

    // ---------------------------------------------------------
    // TEST 2: Send 'A' (0x41 / 01000001) -> 2 ones. 
    // EXPECT: Parity bit must be '0' to keep total even.
    // ---------------------------------------------------------
    $display("Test 2: Sending 'A' (Normal)...");
    @(posedge clk);
    tx_data_in = 8'h41;
    tx_start   = 1;
    @(posedge clk);
    tx_start   = 0;
    wait(tx_busy == 0);
    #(BIT_TIME * 2);

    // ---------------------------------------------------------
    // TEST 3: Send 'C' again, but INJECT NOISE
    // ---------------------------------------------------------
    $display("Test 3: Sending 'C' (Injecting Noise)...");
    @(posedge clk);
    tx_data_in = 8'h43;
    tx_start   = 1;
    @(posedge clk);
    tx_start   = 0;

    // Wait exactly halfway into the data transmission (around bit 4)
    #(BIT_TIME * 5); 
    
    // Strike the wire with noise for half a bit-period!
    noise_strike = 1;
    #(BIT_TIME);
    noise_strike = 0;

    // Wait for transmission to end.
    // EXPECT: Receiver sees the wrong data, checks the parity bit, 
    // realizes the math is broken, and raises parity_error!
    wait(tx_busy == 0);
    #(BIT_TIME * 4);

    $display("==================================================");
    $display(" Simulation Complete. Look at parity_error in Wave!");
    $display("==================================================");
    $stop; 
end

endmodule