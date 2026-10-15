# Task 4: Full Implementation of F1 Starting Light and Reaction Timer

## Overview

This task integrates all previously designed components into a complete, interactive Formula 1 starting light and human reaction timing system. 

In Formula 1 racing, 5 red lights illuminate sequentially at 1-second intervals. Once all lights are ON, drivers face a suspenseful, unpredictable holding delay (between 0.2s and 3.0s). Suddenly, all lights extinguish simultaneously ("Lights out and away we go!"), signalling the start of the race.

This system mirrors the official starting procedure by integrating:
1. **Clock Divider (`clktick.sv`)**: Generates 1-second clock pulses to pace the light build-up.
2. **7-Bit LFSR (`lfsr_7.sv`)**: Generates a pseudo-random number $K$ between 1 and 127 to provide an unpredictable delay.
3. **Delay Generator (`delay.sv`)**: Holds the lights in the all-ON state for $K$ clock cycles.
4. **Finite State Machine (`f1_fsm.sv`)**: Sequences states $s_0$ through $s_8$ and coordinates the countdown and delay triggers.
5. **Top-Level Integration (`f1_lights.sv`)**: Interconnects all modules using a 2-to-1 multiplexer.
6. **Vbuddy Testbench (`f1_fsm_tb.cpp`)**: Drives the Neopixel light strip, captures reaction time using Vbuddy's internal stopwatch (`vbdInitWatch()` and `vbdElapsed()`), and displays the result in base-10 decimal format on the 7-segment display.

---

## Circuit Architecture

The complete system diagram below illustrates how each hardware component interconnects:

![Formula 1 Starting Light and Reaction Timer Architecture](../images/F1_full.jpg)

### Subsystem Interconnections:
- **`clktick.sv`**: Driven by `clk`, enabled by `seq`. Provides 1-second tick pulses to input `1` of the 2-to-1 MUX.
- **`lfsr_7.sv`**: Constantly clocked with `en = 1'b1`, outputting an unpredictable 7-bit seed (`polynomial`) to `delay.sv`.
- **`delay.sv`**: Triggered by `delay` from the FSM at state $s_8$. Counts down $K$ clock cycles and outputs a single-cycle pulse `delayed_timer` to input `0` of the 2-to-1 MUX.
- **2-to-1 Multiplexer (`assign en = seq ? tick : delayed_timer;`)**: Routes `tick` to the FSM during sequencing ($s_1 \to s_8$), and routes `delayed_timer` when waiting for the random delay at $s_8$.
- **`f1_fsm.sv`**: Receives `trigger` to start from $s_0$, advances on `en`, and outputs `seq`, `delay`, and the 8-bit thermometric light vector `data_out`.

---

## Files Included

### 1. Top-Level Integration Module (`f1_lights.sv`)

```systemverilog
module f1_lights (
	input logic clk, rst, trigger,
	output logic [7:0] data_out
);
	logic tick, seq, delay; 
	clktick timer (.clk(clk), .rst(rst), .en(seq), .N(5'd24), .tick(tick));
	
	logic [6:0] polynomial;
	lfsr_7 vals (.clk(clk), .rst(rst), .en(1'b1), .data_out(polynomial));
	logic delayed_timer;
	delay delay_val (.clk(clk), .rst(rst), .trigger(delay), .n(polynomial), .time_out(delayed_timer));
	
	logic en;
	
	assign en = seq ? tick : delayed_timer;
	
	f1_fsm display (.en(en), .rst(rst), .clk(clk), .trigger(trigger), .data_out(data_out), .seq(seq), .delay(delay));

endmodule 
```

### 2. Finite State Machine (`f1_fsm.sv`)

```systemverilog
module f1_fsm(
	input logic en, rst, clk, trigger,
	output logic [7:0] data_out,
	output logic seq, delay
);
	typedef enum {s0, s1, s2, s3, s4, s5, s6, s7, s8} my_state;
	my_state current_state, next_state;
	
	always_ff @(posedge clk, posedge rst) begin
		if (rst) begin
			current_state <= s0;
		end else begin
			current_state <= next_state;
		end
	end
	
	always_comb begin
		case (current_state)
			s0: if (trigger) next_state = s1;
			s1: if (en) next_state = s2;
			s2: if (en) next_state = s3;
			s3: if (en) next_state = s4;
			s4: if (en) next_state = s5;
			s5: if (en) next_state = s6;
			s6: if (en) next_state = s7;
			s7: if (en) next_state = s8;
			s8: if (en) next_state = s0;
			default: next_state = current_state;
		endcase
	end
	
	always_comb begin
		case (current_state) 
			s0: begin data_out = 8'b0; delay = 1'b0; seq = 1'b0; end
			s1: begin data_out = 8'b1; delay = 1'b0; seq = 1'b1; end
			s2: begin data_out = 8'b11; delay = 1'b0; seq = 1'b1; end
			s3: begin data_out = 8'b111; delay = 1'b0; seq = 1'b1; end
			s4: begin data_out = 8'b1111; delay = 1'b0; seq = 1'b1; end
			s5: begin data_out = 8'b11111; delay = 1'b0; seq = 1'b1; end
			s6: begin data_out = 8'b111111; delay = 1'b0; seq = 1'b1; end
			s7: begin data_out = 8'b1111111; delay = 1'b0; seq = 1'b1; end
			s8: begin data_out = 8'b11111111; delay = 1'b1; seq = 1'b0; end
			default: data_out = 8'b0;
		endcase
	end
	
endmodule
```

### 3. Hardware Testbench & Reaction Timer (`f1_fsm_tb.cpp`)

```cpp
#include "Vf1_lights.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "vbuddy.cpp"

int main(int argc, char **argv, char **env) {
	int current_val = 0;
	int prev_val = 0;
	bool timer = false;
	
	Verilated::commandArgs(argc, argv);
	Vf1_lights* top = new Vf1_lights;
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	top->trace(tfp, 99);
	tfp->open("f1_lights.vcd");

	if (vbdOpen() != 1) return(-1);
	vbdHeader("Lab 3:f1 lights");
	vbdSetMode(1);
		
	top->clk = 0;
	top->rst = 0;
	top->trigger = 0;
        
	for (int i = 0; i < 1000000; i++) {
		top->rst = (i < 2);
		for (int clk = 0; clk < 2; clk++) {
			tfp->dump(2*i + clk);
			top->clk = !top->clk;
			top->eval();
		}
		current_val = top->data_out & 0xFF;
		if ((prev_val == 0xFF) && (current_val == 0x00)){
			vbdInitWatch();
			timer = true;
		}

		if (timer) {
			if (vbdFlag()) {          // User pressed the switch!
				int reaction_time = vbdElapsed(); // Read time in ms
				vbdHex(4, (reaction_time / 1000) % 10);  //software BCD
				vbdHex(3, (reaction_time / 100)  % 10);  
				vbdHex(2, (reaction_time / 10)   % 10);  
				vbdHex(1,  reaction_time         % 10);  
				timer = false;
			} 
		} else {
			top->trigger = vbdFlag();
		}

		vbdBar(current_val);
		prev_val = current_val;
		vbdCycle(i+1);
		 
		if ((Verilated::gotFinish()) || (vbdGetkey()=='q'))  exit(0);
		
	}
	vbdClose();
	tfp->close();
	exit(0);
}
```

---

## Detailed System Operation

### 1. Sequence Initiation (State $s_0$)
- In idle state $s_0$, all lights are off (`data_out = 8'b0`), `seq = 0`, and `delay = 0`.
- The user taps the Vbuddy rotary switch in one-shot mode (`vbdSetMode(1)`).
- `top->trigger` is asserted high for one clock cycle, moving the FSM from $s_0 \to s_1$.

### 2. Automatic Countdown ($s_1 \to s_8$)
- From states $s_1$ through $s_7$, `seq` is asserted high (`seq = 1'b1`).
- This enables `clktick.sv` and selects input `1` on the multiplexer (`en = tick`).
- Every ~1 second, `clktick` generates a 1-cycle pulse `tick`, advancing the FSM to light up the Neopixels one by one (`8'b00000001` through `8'b11111111`).

### 3. Random Delay Holding ($s_8$)
- Once all 8 lights turn ON at $s_8$:
  - `seq` falls to `1'b0`, switching the MUX to select `delayed_timer` (input `0`).
  - `delay` asserts high (`1'b1`), which triggers the `delay.sv` counter.
- `delay.sv` samples the 7-bit value from `lfsr_7.sv` as its countdown target $K$.
- Because the 7-bit LFSR has been shifting continuously at full clock speed, its value when entering $s_8$ is entirely unpredictable (between 1 and 127 clock cycles).
- The system holds in $s_8$ with all 8 lights illuminated for this random duration.

### 4. Lights Out & Reaction Timing ($s_8 \to s_0$)
- When the delay counter reaches zero, `delay.sv` outputs a single-cycle pulse `time_out = 1`.
- This pulse passes through the MUX into `en`, causing the FSM to transition from $s_8 \to s_0$ (all lights turn OFF simultaneously).
- The testbench detects this transition by comparing `prev_val == 0xFF` against `current_val == 0x00`.
- At this exact clock cycle, the testbench invokes `vbdInitWatch()` to start Vbuddy's internal millisecond hardware stopwatch and sets `timer = true`.

### 5. Reaction Capture and Software BCD Display
- The player spots the lights extinguishing and presses the rotary switch as fast as possible.
- The testbench senses `vbdFlag() == true`, calls `vbdElapsed()`, and retrieves the reaction time in milliseconds.
- To display the score cleanly in base-10 decimal on Vbuddy's 7-segment displays without complex hardware BCD conversion:
  - Thousands digit: `(reaction_time / 1000) % 10`
  - Hundreds digit: `(reaction_time / 100) % 10`
  - Tens digit: `(reaction_time / 10) % 10`
  - Units digit: `reaction_time % 10`
- The reaction score (e.g. `0245` ms) is output directly to displays `vbdHex(4)` through `vbdHex(1)`.

---

## Challenge Completed: ✓

The implementation successfully demonstrates:
1. Complete top-level integration combining `clktick.sv`, `f1_fsm.sv`, `lfsr_7.sv`, and `delay.sv`.
2. Multiplexer-controlled enable routing switching between fixed 1-second ticks and pseudo-random delay timeouts.
3. Realistic Formula 1 race start sequence with an unpredictable hold time governed by a 7-bit LFSR.
4. Precision reaction time measurement using Vbuddy's version 1.1 hardware stopwatch (`vbdInitWatch` and `vbdElapsed`).
5. Real-time decimal readout on 7-segment displays using software BCD digit extraction.