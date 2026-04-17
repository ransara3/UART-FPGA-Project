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

## Running in Quartus Prime (DE0-Nano)

### 1. Create a New Project
1. Open **Quartus Prime Lite**
2. **File → New Project Wizard**
3. Set working directory to where your `.v` files are
4. Project name: `Uart`
5. Click **Next**

### 2. Add Source Files
6. Click **Add All** or browse and add these 4 files (any order):
   - `uart_tx.v`
   - `uart_rx.v`
   - `uart_transceiver.v`
   - `uart_top.v`
7. Click **Next**

### 3. Select FPGA Device
8. Family: **Cyclone IV E**
9. Device: **EP4CE22F17C6**
10. Click **Next → Finish**

### 4. Set Top-Level Entity
11. **Assignments → Settings → General**
12. Set Top-Level Entity to: `uart_top`
13. Click **OK**

### 5. Import Pin Assignments
14. **Assignments → Import Assignments**
15. Browse and select `de0_nano_constraints.qsf`
16. Click **OK**

### 6. Compile the Design
17. **Processing → Start Compilation** (or `Ctrl+L`)
18. Wait for compilation — check for 0 errors in Messages panel
19. Review the **Compilation Report** for resource usage

### 7. Simulate in ModelSim
20. **Assignments → Settings → EDA Tool Settings → Simulation**
21. Tool name: **ModelSim-Altera**, Format: **Verilog HDL**
22. Click **OK**
23. **Assignments → Settings → EDA Tool Settings → Simulation → Test Benches**
24. Click **New**:
    - Test bench name: `uart_tb`
    - Top-level module: `uart_tb`
    - Click **Add** → select `uart_tb.v`
25. Click **OK → OK**
26. **Tools → Run Simulation Tool → RTL Simulation**
27. ModelSim opens — capture waveform screenshot for report

### 8. Program the FPGA
28. Connect DE0-Nano via USB
29. **Tools → Programmer**
30. **Hardware Setup** → select **USB-Blaster**
31. **Add File** → `output_files/Uart.sof`
32. Check **Program/Configure** → click **Start**

### 9. Hardware Testing
33. Set DIP switches SW[3:0] to choose a hex digit
34. Press KEY[1] to send byte `0x4X` (e.g. SW=0001 → sends 'A')
35. Connect two boards:
    ```
    Board A TX (PIN_A8)  ──→  Board B RX (PIN_D3)
    Board B TX (PIN_A8)  ──→  Board A RX (PIN_D3)
    GND  ────────────────────  GND
    ```
36. Received byte shows on LEDs (binary) and 7-segment display (hex nibble)

### Troubleshooting

| Problem | Fix |
|---------|-----|
| "Can't find module" error | Make sure all 4 `.v` files are added to project |
| "Top-level entity not set" | Assignments → Settings → set `uart_top` |
| Pin assignment warnings | Import `de0_nano_constraints.qsf` |
| No USB-Blaster found | Install USB-Blaster driver from Quartus install folder |

## Notes

- `uart_top.v` is designed for FPGA demonstration and shows how received lower nibble data can be displayed on a single 7-segment digit.
- For hardware implementation, add board-specific pin constraints and connect `uart_rx`, `uart_tx`, `seg`, `an`, and LEDs to the FPGA I/O pins.
