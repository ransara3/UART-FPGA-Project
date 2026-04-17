# UART FPGA Project

This workspace contains a Verilog UART implementation for EN2111 Electronic Circuit Design.

## Files

- `uart_tx.v` - UART transmitter module (8N1, parameterized clock and baud rate)
- `uart_rx.v` - UART receiver module (8N1, parameterized clock and baud rate)
- `uart_transceiver.v` - Wrapper connecting transmitter and receiver
- `uart_top.v` - Example top-level module with 7-segment display output
- `uart_tb.v` - Testbench for simulation verification

## How to run simulation

1. Use a Verilog simulator such as Icarus Verilog.
2. From the project folder run:
   - `iverilog -o uart_tb uart_tx.v uart_rx.v uart_transceiver.v uart_tb.v`
   - `vvp uart_tb`
3. Open `uart_tb.vcd` in GTKWave to view the timing diagram.

## Notes

- `uart_top.v` is designed for FPGA demonstration and shows how received lower nibble data can be displayed on a single 7-segment digit.
- For hardware implementation, add board-specific pin constraints and connect `uart_rx`, `uart_tx`, `seg`, `an`, and LEDs to the FPGA I/O pins.
