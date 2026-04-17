# DE0-Nano UART Project Setup Guide

## Board: Altera DE0-Nano (Cyclone IV EP4CE22F17C6)

### Tools Required
- Intel Quartus Prime Lite (free) — Download from Intel/Altera website
- ModelSim (included with Quartus) — For simulation
- Icarus Verilog + GTKWave (optional, for quick command-line simulation)

## Project Files
| File | Purpose |
|------|---------|
| `uart_tx.v` | UART Transmitter (8N1, 9600 baud) |
| `uart_rx.v` | UART Receiver (8N1, 9600 baud) |
| `uart_transceiver.v` | Combined TX/RX wrapper |
| `uart_top.v` | Top-level for DE0-Nano with 7-seg + LEDs |
| `uart_tb.v` | Simulation testbench (loopback, 7 test cases) |
| `de0_nano_constraints.qsf` | Pin assignments for DE0-Nano |
| `uart_timing.sdc` | Clock timing constraints |

## Hardware Pin Mapping

| Signal | DE0-Nano Pin | Description |
|--------|-------------|-------------|
| CLOCK_50 | PIN_R8 | 50 MHz system clock |
| KEY[0] | PIN_J15 | Reset (active-low) |
| KEY[1] | PIN_E1 | Transmit button (press to send) |
| SW[3:0] | M1, T8, B9, M15 | Data switches (lower nibble) |
| LED[7:0] | A15, A13, B13, A11, D1, F3, B1, L3 | Received byte (binary) |
| GPIO_0_TX | PIN_A8 | UART TX → other board's RX |
| GPIO_0_RX | PIN_D3 | UART RX ← other board's TX |
| GPIO_0_SEG[6:0] | B8, C3, A2, A3, B3, B4, A4 | External 7-segment display |

## How to Use (On the FPGA)

1. Set SW[3:0] to the hex digit you want to send (the byte sent is `0x4X`,
   e.g. SW=0001 → sends `0x41` = ASCII 'A')
2. Press and release KEY[1] to transmit
3. The other board receives the byte:
   - LEDs show the full 8-bit value in binary
   - 7-segment display shows the lower hex nibble

## Step 1: Quick Simulation (Icarus Verilog)

```bash
# Compile
iverilog -o uart_sim uart_tx.v uart_rx.v uart_transceiver.v uart_tb.v

# Run
vvp uart_sim

# View waveforms (for report screenshots)
gtkwave uart_tb.vcd
```

Expected output:
```
============================================
  UART Testbench  |  50 MHz  |  9600 baud
============================================
[PASS] Test 1 (ASCII A): Sent 0x41, Received 0x41
[PASS] Test 2 (ASCII z): Sent 0x7a, Received 0x7a
...
  *** ALL TESTS PASSED ***
============================================
```

## Step 2: Simulation in ModelSim (via Quartus)

1. Open Intel Quartus Prime
2. **File → New Project Wizard**
   - Project name: `uart_de0nano`
   - FPGA device: **EP4CE22F17C6**
3. Add source files: `uart_tx.v`, `uart_rx.v`, `uart_transceiver.v`, `uart_top.v`
4. Set testbench: `uart_tb.v`
5. **Tools → Run Simulation Tool → RTL Simulation**
6. Capture waveform screenshots for your report

## Step 3: FPGA Implementation

1. Set `uart_top` as top-level entity
2. Copy pin assignments from `de0_nano_constraints.qsf` into your project
   (or use **Assignments → Import Assignments**)
3. **Processing → Start Compilation**
4. After successful compilation → check resource usage in Compilation Report
5. **Tools → Programmer** → load `.sof` file → program via USB-Blaster

## Step 4: Two-Board Hardware Test

### Wiring between Board A and Board B:
```
Board A GPIO_0_TX (PIN_A8) ────→ Board B GPIO_0_RX (PIN_D3)
Board B GPIO_0_TX (PIN_A8) ────→ Board A GPIO_0_RX (PIN_D3)
Board A GND      ───────────────── Board B GND
```

### External 7-Segment Display Wiring:
Connect a **common-anode** 7-segment display to GPIO_0_SEG[6:0] pins.
Each segment output is active-low (0=ON, 1=OFF).
Connect the common anode to 3.3V through a current-limiting resistor.

### Test Procedure:
1. Program both boards with the same `.sof` file
2. On Board A: set SW = 0001, press KEY[1] → sends 0x41 ('A')
3. Board B should show: LED = 01000001, 7-seg = '1'
4. Repeat from Board B to Board A
5. Capture oscilloscope waveform on TX/RX lines for report

## Step 5: Oscilloscope Capture (for report)

1. Connect oscilloscope probe to GPIO_0_TX (PIN_A8)
2. Set oscilloscope: trigger on falling edge, timebase ~200µs/div
3. Send a byte (press KEY[1])
4. You should see: idle HIGH → start bit LOW → 8 data bits → stop bit HIGH
5. Measure bit period ≈ 104 µs (for 9600 baud)
6. Take photo/screenshot for report
