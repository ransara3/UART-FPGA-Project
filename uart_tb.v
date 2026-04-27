`timescale 1ns / 1ps

// ============================================================================
// UART Transceiver Testbench
//   - 50 MHz clock (matching DE0-Nano)
//   - 9600 baud (matching uart_top default)
//   - Loopback: TX output wired to RX input
//   - Sends multiple test bytes and checks each one
//   - Prints PASS/FAIL summary
// ============================================================================
module uart_tb;

localparam CLK_FREQ   = 50_000_000;
localparam BAUD_RATE  = 9600;
localparam PARITY_TYPE = 1;               // 0=None, 1=Even, 2=Odd
localparam CLK_NS    = 1_000_000_000 / CLK_FREQ;  // 20 ns period
localparam BIT_TIME  = 1_000_000_000 / BAUD_RATE;  // ~104167 ns per bit
// Frame = 1 start + 8 data + (1 parity if enabled) + 1 stop
localparam FRAME_BITS = (PARITY_TYPE != 0) ? 11 : 10;
localparam FRAME_TIME = BIT_TIME * FRAME_BITS;

reg clk = 0;
reg rst_n = 0;
reg [7:0] tx_data;
reg tx_start;
wire tx_busy;
wire tx_serial;
wire [7:0] rx_data;
wire rx_valid;
wire rx_error;
wire parity_error;

// Loopback: TX output feeds RX input
uart_transceiver #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .PARITY_TYPE(PARITY_TYPE)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .tx_busy(tx_busy),
    .tx(tx_serial),
    .rx(tx_serial),       // loopback
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .rx_error(rx_error),
    .parity_error(parity_error)
);

// 50 MHz clock: period = 20 ns
always #(CLK_NS/2) clk = ~clk;

// Counters
integer pass_cnt = 0;
integer fail_cnt = 0;
integer test_num = 0;

// ---- Task: send one byte and verify reception ----
task send_and_check(input [7:0] value, input [8*20-1:0] label);
begin
    test_num = test_num + 1;
    @(posedge clk);
    tx_data  <= value;
    tx_start <= 1'b1;
    @(posedge clk);
    tx_start <= 1'b0;

    // Wait for transmission + reception to complete
    #(FRAME_TIME * 2);

    if (rx_error) begin
        $display("[FAIL] Test %0d (%0s): Framing error (bad stop bit)",
                 test_num, label);
        fail_cnt = fail_cnt + 1;
    end else if (parity_error) begin
        $display("[FAIL] Test %0d (%0s): Parity error detected",
                 test_num, label);
        fail_cnt = fail_cnt + 1;
    end else if (rx_data === value) begin
        $display("[PASS] Test %0d (%0s): Sent 0x%02X, Received 0x%02X",
                 test_num, label, value, rx_data);
        pass_cnt = pass_cnt + 1;
    end else begin
        $display("[FAIL] Test %0d (%0s): Sent 0x%02X, Received 0x%02X",
                 test_num, label, value, rx_data);
        fail_cnt = fail_cnt + 1;
    end

    // Small gap between frames
    #(BIT_TIME * 2);
end
endtask

// ---- Main test sequence ----
initial begin
    $dumpfile("uart_tb.vcd");
    $dumpvars(0, uart_tb);

    // Reset
    rst_n    = 0;
    tx_data  = 8'h00;
    tx_start = 1'b0;
    #200;
    rst_n = 1;
    #100;

    $display("============================================");
    $display("  UART Testbench  |  %0d MHz  |  %0d baud  |  Parity=%0d",
             CLK_FREQ / 1_000_000, BAUD_RATE, PARITY_TYPE);
    $display("============================================");

    // Test 1 – ASCII 'A' (0x41) – typical printable character
    send_and_check(8'h41, "ASCII A");

    // Test 2 – ASCII 'z' (0x7A) – another printable character
    send_and_check(8'h7A, "ASCII z");

    // Test 3 – ASCII '0' (0x30) – digit character
    send_and_check(8'h30, "ASCII 0");

    // Test 4 – 0x00 – all zeros (edge case)
    send_and_check(8'h00, "All zeros");

    // Test 5 – 0xFF – all ones (edge case)
    send_and_check(8'hFF, "All ones");

    // Test 6 – 0xAA – alternating bits 10101010
    send_and_check(8'hAA, "Alt bits AA");

    // Test 7 – 0x55 – alternating bits 01010101
    send_and_check(8'h55, "Alt bits 55");

    // ---- Summary ----
    $display("============================================");
    $display("  Results: %0d PASSED, %0d FAILED out of %0d tests",
             pass_cnt, fail_cnt, test_num);
    if (fail_cnt == 0)
        $display("  *** ALL TESTS PASSED ***");
    else
        $display("  *** SOME TESTS FAILED ***");
    $display("============================================");

    #1000;
    $finish;
end

// ---- Timeout watchdog ----
initial begin
    #(FRAME_TIME * 30);
    $display("ERROR: Simulation timed out!");
    $finish;
end

endmodule
