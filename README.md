# Verilog RTL Projects

A progression of digital design projects in Verilog, built and simulated with Icarus Verilog, moving from basic FSM design to serial communication protocols and clock-domain crossing.

## Projects

### 1. Traffic Light Controller (`traffic_light_fsm.v`)
A parameterized Moore FSM cycling RED → GREEN → YELLOW → RED, with configurable durations per state.

**Concepts demonstrated:**
- 2-process FSM coding style (separate state register / next-state logic / output logic)
- `localparam` state encoding
- Parameterized modules (`RED_TIME`, `GREEN_TIME`, `YELLOW_TIME`)
- Self-checking testbench with a one-hot output assertion

**Files:** `traffic_light_fsm.v`, `traffic_light_fsm_tb.v`

**Run it:**
```bash
iverilog -o traffic_sim traffic_light_fsm.v traffic_light_fsm_tb.v
vvp traffic_sim
```

---

### 2. UART Transmitter / Receiver (`uart_tx.v`, `uart_rx.v`)
An 8N1 UART (8 data bits, no parity, 1 stop bit) implementing full serial framing, 16x oversampled receive sampling, and CDC-safe input synchronization.

**Concepts demonstrated:**
- Serial protocol framing (start/data/stop bits, LSB-first)
- 16x oversampling with mid-bit sampling for clock-drift tolerance
- 2-flip-flop synchronizer for crossing an asynchronous input into the local clock domain
- Framing-bit validation (`rx_valid` only asserts on a clean stop bit)
- Self-checking loopback testbench (TX output wired directly to RX input)

**Files:** `uart_tx.v`, `uart_rx.v`, `uart_loopback_tb.v`

**Run it:**
```bash
iverilog -o uart_sim uart_tx.v uart_rx.v uart_loopback_tb.v
vvp uart_sim
```

---

## Viewing waveforms

Each testbench can dump a VCD file for inspection in GTKWave. Add near the top of the `initial` block:
```verilog
$dumpfile("wave.vcd");
$dumpvars(0, <testbench_module_name>);
```
Then:
```bash
gtkwave wave.vcd
```

## Toolchain
- [Icarus Verilog](http://iverilog.icarus.com/) — compilation and simulation
- [GTKWave](http://gtkwave.sourceforge.net/) — waveform viewing

## Author
Nandan Shirur
