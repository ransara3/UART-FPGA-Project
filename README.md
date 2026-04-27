# UART FPGA Project

Verilog UART implementation for the DE0-Nano (Cyclone IV EP4CE22F17C6) FPGA board.  
Supports configurable parity (None / Even / Odd), full-duplex loopback, dual 7-segment hex display, and a parity-error indicator.

---

## Features

- **Configurable parity** — set `PARITY_TYPE` parameter at instantiation:
  - `0` = None — standard 8N1 (10 bits per frame)
  - `1` = Even — 8E1 (11 bits per frame)
  - `2` = Odd  — 8O1 (11 bits per frame)
- **Parity error display** — both 7-segment displays show `—` (middle segment only) when a parity mismatch is detected; clears automatically on the next valid frame
- **Framing error detection** — `rx_error` asserted when the stop bit is not high
- **Dual 7-segment output** — upper nibble on `SEG_UPPER`, lower nibble on `SEG_LOWER`
- **Full-duplex loopback** — TX and RX operate independently; testbench wires TX → RX for self-test
- **Double-flop synchroniser** on RX input for metastability protection
- **Parameterised clock & baud rate** — default 50 MHz / 9600 baud

---

## Repository Files

| File | Description |
|---|---|
| `uart_tx.v` | Transmitter — 8N1 / 8E1 / 8O1, `PARITY_TYPE` parameter |
| `uart_rx.v` | Receiver  — 8N1 / 8E1 / 8O1, outputs `rx_valid`, `rx_error`, `parity_error` |
| `uart_transceiver.v` | Wrapper connecting TX and RX, exposes all ports |
| `uart_top.v` | DE0-Nano top-level: KEYs, DIP switches, LEDs, dual 7-seg, parity error display |
| `uart_tb.v` | Simulation testbench — loopback, multi-byte tests, parity/framing error checks |
| `uart2.qsf` | Quartus project settings & **full pin assignments** for DE0-Nano |
| `uart_timing.sdc` | Timing constraints (SDC) |

---

## Pin Assignments (DE0-Nano)

All assignments are included in `uart2.qsf`. Key mappings:

| Signal | Pin | Description |
|---|---|---|
| `CLOCK_50` | PIN_R8 | 50 MHz system clock |
| `KEY[0]` | PIN_J15 | Active-low reset |
| `KEY[1]` | PIN_E1 | Send byte (falling-edge triggered) |
| `GPIO_0_TX` | PIN_D3 | UART TX output |
| `GPIO_0_RX` | PIN_A8 | UART RX input |
| `LED[7:0]` | PIN_L3…PIN_A15 | Received byte (binary) |
| `EXT_SW[7:0]` | GPIO-1 pins | 8-bit DIP switch input |
| `SEG_UPPER[6:0]` | PIN_B5…PIN_C3 | Upper nibble hex display |
| `SEG_LOWER[6:0]` | PIN_A7…PIN_A5 | Lower nibble hex display |

---

## How to Run Simulation

1. Install [Icarus Verilog](http://iverilog.icarus.com/).
2. From the project folder:
   ```bash
   iverilog -o uart_sim uart_tx.v uart_rx.v uart_transceiver.v uart_tb.v
   vvp uart_sim
   ```
3. Open `uart_tb.vcd` in **GTKWave** to inspect the waveform.

The testbench runs with `PARITY_TYPE = 1` (even parity) by default and reports `[PASS]` / `[FAIL]` for each test byte. Change the localparam in `uart_tb.v` to `0` or `2` to test other modes.

---

## Running in Quartus Prime (DE0-Nano)

### 1. Create a New Project
1. Open **Quartus Prime Lite**
2. **File → New Project Wizard**
3. Set the working directory to where your `.v` files are
4. Project name: `uart2`
5. Click **Next**

### 2. Add Source Files
6. Add these files (any order):
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
12. Top-Level Entity: `uart_top`
13. Click **OK**

### 5. Import Pin Assignments
14. **Assignments → Import Assignments**
15. Select **`uart2.qsf`**
16. Click **OK**

This imports all pin locations and IO standards for CLOCK_50, KEY, LED, GPIO, EXT_SW, SEG_UPPER, and SEG_LOWER.

### 6. Set Parity Mode (optional)
To change parity mode, edit the parameter in `uart_top.v`:
```verilog
parameter integer PARITY_TYPE = 0  // 0=None, 1=Even, 2=Odd
```

### 7. Compile the Design
17. **Processing → Start Compilation** (`Ctrl+L`)
18. Verify **0 errors** in the Messages panel
19. Review the Compilation Report for resource usage

### 8. Simulate in ModelSim
20. **Assignments → Settings → EDA Tool Settings → Simulation**
    - Tool: **ModelSim-Altera**, Format: **Verilog HDL**
21. **Test Benches → New**:
    - Test bench name: `uart_tb`
    - Top-level module: `uart_tb`
    - Add file: `uart_tb.v`
22. **Tools → Run Simulation Tool → RTL Simulation**
23. ModelSim opens — add signals to waveform and run

### 9. Program the FPGA
24. Connect DE0-Nano via USB
25. **Tools → Programmer**
26. **Hardware Setup** → select **USB-Blaster**
27. **Add File** → `output_files/uart2.sof`
28. Check **Program/Configure** → click **Start**

### 10. Hardware Testing
29. Set DIP switches `EXT_SW[7:0]` to the byte you want to send
30. Press **KEY[1]** to transmit
31. The received byte appears on:
    - **LED[7:0]** — binary representation
    - **SEG_UPPER** — upper nibble in hex
    - **SEG_LOWER** — lower nibble in hex
32. **Parity error**: if a parity mismatch is detected, both displays show `—` (middle bar only) until the next valid frame is received

Two-board loopback wiring:
```
Board A TX (PIN_D3)  ──→  Board B RX (PIN_A8)
Board B TX (PIN_D3)  ──→  Board A RX (PIN_A8)
GND  ──────────────────── GND
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| "Can't find module" | Add all `.v` files to the project |
| "Top-level entity not set" | Assignments → Settings → set `uart_top` |
| Pin assignment warnings | Import `uart2.qsf` — contains all pin assignments including 7-seg |
| SEG_UPPER / SEG_LOWER undefined | Ensure `uart2.qsf` was imported |
| Both displays show `—` | Parity error detected — check sender parity setting matches receiver |
| No USB-Blaster found | Install USB-Blaster driver from Quartus install folder |
| Simulation hangs | Check `PARITY_TYPE` localparam in `uart_tb.v` matches expected mode |
- For hardware implementation, add board-specific pin constraints and connect `uart_rx`, `uart_tx`, `seg`, `an`, and LEDs to the FPGA I/O pins.
