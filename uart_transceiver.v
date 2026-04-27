// UART Transceiver wrapper connecting transmitter and receiver
// PARITY_TYPE: 0=None (8N1), 1=Even (8E1), 2=Odd (8O1)
module uart_transceiver #(
    parameter integer CLK_FREQ    = 50_000_000,
    parameter integer BAUD_RATE   = 9600,
    parameter integer PARITY_TYPE = 0
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  tx_data,
    input  wire        tx_start,
    output wire        tx_busy,
    output wire        tx,

    input  wire        rx,
    output wire [7:0]  rx_data,
    output wire        rx_valid,
    output wire        rx_error,
    output wire        parity_error
);

uart_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .PARITY_TYPE(PARITY_TYPE)
) tx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(tx_data),
    .tx_start(tx_start),
    .tx_busy(tx_busy),
    .tx_serial(tx)
);

uart_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .PARITY_TYPE(PARITY_TYPE)
) rx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rx_serial(rx),
    .data_out(rx_data),
    .rx_valid(rx_valid),
    .rx_error(rx_error),
    .parity_error(parity_error)
);

endmodule
