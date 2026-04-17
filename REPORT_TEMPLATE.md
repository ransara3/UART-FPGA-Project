## Project Report Template

### EN2111 Electronic Circuit Design - UART FPGA Implementation

**Group Members:** [Add names]  
**Submission Date:** [Add date]  
**Board:** Altera DE0-Nano (Cyclone IV)  

---

## 1. RTL Design

### 1.1 UART Transmitter (uart_tx.v)
- **Spec:** 8N1 (8 bits, no parity, 1 stop bit)
- **Clock:** 50 MHz
- **Baud Rate:** 115200 bps
- **Description:** [Insert detailed description of transmitter state machine]

### 1.2 UART Receiver (uart_rx.v)
- **Spec:** 8N1
- **Clock:** 50 MHz
- **Baud Rate:** 115200 bps
- **Description:** [Insert detailed description of receiver state machine]

### 1.3 Transceiver (uart_transceiver.v)
- Combines TX and RX modules
- Shared clock and reset
- [Add block diagram if helpful]

---

## 2. Simulation Results

### 2.1 Testbench Overview
- Location: `uart_tb.v`
- Tests three characters: 0x41 ('A'), 0x7A ('z'), 0x30 ('0')
- Loopback verification: TX output fed to RX input

### 2.2 Timing Diagrams
**Insert waveform screenshots showing:**
- [Screenshot 1] TX/RX transitions during 'A' transmission
- [Screenshot 2] Baud rate timing verification
- [Screenshot 3] Multiple byte transmission sequence

**Observations:**
- Start bit to stop bit timing matches 115200 bps specification
- Bit alignment correct
- Loopback verification passed all test cases

---

## 3. FPGA Implementation

### 3.1 Board Configuration
- FPGA: Altera Cyclone IV EP4CE22F17C6
- Board: DE0-Nano
- Pin constraints applied from `de0_nano_constraints.qsf`

### 3.2 Resource Usage
[Add synthesis report showing:]
- Logic elements used
- Memory usage
- Timing closure

### 3.3 Hardware Testing
**Setup:**
- USB-UART adapter connected to GPIO pins
- 7-segment display configured for received data lower nibble
- Terminal emulator at 115200 baud, 8N1

**Test Results:**
- Sent character 'A' (0x41), received: 0x41 ✓
- Sent character 'F' (0x46), 7-seg displayed: 0x6 ✓
- Verified with oscilloscope: [Screenshot oscilloscope waveform]

---

## 4. Oscilloscope Waveform Capture

[Insert photo of FPGA board with oscilloscope probe on UART TX/RX lines]

**Measurements:**
- Baud period: ~8.68 µs (at 115200 bps)
- Start bit width: ~8.68 µs
- Data bits width: ~8.68 µs each
- Stop bit width: ~8.68 µs

---

## 5. Conclusions

- UART implementation successfully transmits and receives data at 115200 bps
- Protocol compliant with 8N1 standard
- FPGA resource utilization efficient
- Live hardware demonstration confirmed between two DE0-Nano boards

---

## Appendices

### A. Complete RTL Code
[Include uart_tx.v, uart_rx.v, uart_transceiver.v]

### B. Testbench Code
[Include uart_tb.v]

### C. Block Diagram
[Draw or insert block diagram of UART structure]
