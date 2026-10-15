# Task 1: 4-Bit and 7-Bit Linear Feedback Shift Registers (LFSR)

## Overview

This task implements Pseudo-Random Binary Sequence (PRBS) generators using Linear Feedback Shift Registers (LFSRs). An LFSR is a shift register whose input bit is a linear function (exclusive-OR) of two or more of its previous states (taps). When configured with a primitive polynomial, the LFSR cycles through all possible non-zero binary combinations, generating a maximal-length pseudo-random sequence before repeating. The designs are specified in SystemVerilog for both 4-bit and 7-bit configurations and verified using an automated C++ testbench powered by Google Test (GTest) and Verilator.

## Files Included

### 1. 4-Bit LFSR Module (`lfsr.sv`)

```systemverilog
module lfsr (
	input logic clk, rst, en,
	output [4:1] data_out
);
	logic [4:1] sreg;
	always_ff @(posedge clk, posedge rst) begin
		if (rst) begin
			sreg <= 4'b1;
		end else if (en) begin
			sreg <= {sreg[3:1], sreg[3] ^ sreg[4]};
		end
	end
	assign data_out = sreg;
endmodule
```

### 2. 4-Bit LFSR Testbench (`verify.cpp`)

```cpp
#include "gtest/gtest.h"
#include "Vdut.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

Vdut *top;
VerilatedVcdC *tfp;
unsigned int ticks = 0;

class TestDut : public ::testing::Test
{
public:
    void SetUp() override
    {
        initializeInputs();
        runReset();
    }

    void TearDown() override
    {
    }

    void initializeInputs()
    {
        top->clk = 0;
        top->rst = 0;
        top->en = 1;
    }

    void runReset()
    {
        top->rst = 1;
        runSimulation();
        top->rst = 0;
    }

    // Runs the simulation for a clock cycle, evaluates the DUT, dumps waveform.
    void runSimulation()
    {
        for (int clk = 0; clk < 2; clk++)
        {
            top->eval();
            tfp->dump(2 * ticks + clk);
            top->clk = !top->clk;
        }
        ticks++;

        if (Verilated::gotFinish())
        {
            exit(0);
        }
    }
};

TEST_F(TestDut, InitialStateTest)
{
    top->rst = 1;
    runSimulation();
    EXPECT_EQ(top->data_out, 0b0001);
}

TEST_F(TestDut, SequenceTestMini)
{
    runSimulation();
    EXPECT_EQ(top->data_out, 0b0010);
}

TEST_F(TestDut, SequenceTest)
{
    std::vector<int> expected = {
        0b0001,
        0b0010,
        0b0100,
        0b1001,
        0b0011,
        0b0110,
        0b1101,
        0b1010,
        0b0101,
        0b1011,
        0b0111,
        0b1111,
        0b1110,
        0b1100,
        0b1000,
        0b0001};

    for (int exp : expected)
    {
        EXPECT_EQ(top->data_out, exp);
        runSimulation();
    }
}

int main(int argc, char **argv)
{
    top = new Vdut;
    tfp = new VerilatedVcdC;

    Verilated::traceEverOn(true);
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    testing::InitGoogleTest(&argc, argv);
    auto res = RUN_ALL_TESTS();

    top->final();
    tfp->close();

    delete top;
    delete tfp;

    return res;
}
```

### 3. 7-Bit LFSR Challenge Module (`lfsr_7.sv`)

```systemverilog
module lfsr_7 (
	input logic clk, rst, en,
	output [6:0] data_out
);

	reg [6:0] sreg;
	
	always_ff @(posedge clk, posedge rst) begin
		if (rst) begin
			sreg <= 7'b1;
		end else if (en) begin
			sreg <= {sreg[5:0] , sreg[6] ^ sreg[2]};
		end
	end
	
	assign data_out = sreg;

endmodule
```

### 4. 7-Bit LFSR Testbench (`verify_7.cpp`)

```cpp
#include "gtest/gtest.h"
#include "Vdut.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <cmath>

Vdut *top;
VerilatedVcdC *tfp;
unsigned int ticks = 0;

class TestDut : public ::testing::Test
{
public:
    void SetUp() override
    {
        initializeInputs();
        runReset();
    }

    void TearDown() override
    {
        top->final();
        tfp->close();
    }

    void initializeInputs()
    {
        top->clk = 0;
        top->rst = 0;
        top->en = 1;
    }

    void runReset()
    {
        top->rst = 1;
        runSimulation();
        top->rst = 0;
    }

    // Runs the simulation for a clock cycle, evaluates the DUT, dumps waveform.
    void runSimulation()
    {
        for (int clk = 0; clk < 2; clk++)
        {
            top->eval();
            tfp->dump(2 * ticks + clk);
            top->clk = !top->clk;
        }
        ticks++;

        if (Verilated::gotFinish())
        {
            exit(0);
        }
    }
};

TEST_F(TestDut, InitialStateTest)
{
    top->rst = 1;
    runSimulation();
    EXPECT_EQ(top->data_out, 0b0001);
}

int generateLFSR7(int state)
{
    int b0 = (state >> 0) & 1;
    int b1 = (state >> 1) & 1;
    int b2 = (state >> 2) & 1;
    int b3 = (state >> 3) & 1;
    int b4 = (state >> 4) & 1;
    int b5 = (state >> 5) & 1;
    int b6 = (state >> 6) & 1;

    return (b5 << 6 | b4 << 5 | b3 << 4 | b2 << 3 | b1 << 2 | b0 << 1 |
            (b2 ^ b6));
}

TEST_F(TestDut, SequenceTest)
{
    int exp = 0b000'0001;

    for (int i = 0; i < pow(2, 7); i++)
    {
        exp = generateLFSR7(exp);
        runSimulation();
        EXPECT_EQ(top->data_out, exp);
    }
}

int main(int argc, char **argv)
{
    top = new Vdut;
    tfp = new VerilatedVcdC;

    Verilated::traceEverOn(true);
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    testing::InitGoogleTest(&argc, argv);
    auto res = RUN_ALL_TESTS();

    top->final();
    tfp->close();

    delete top;
    delete tfp;

    return res;
}
```

## LFSR Mechanism & Principles

### What is a Linear Feedback Shift Register (LFSR)?

An LFSR is a cascade of flip-flops that shifts its internal bit values synchronously on every active clock edge while an enable signal is high:

1. **Feedback Tap Operation**: A linear function—typically an XOR operation—is performed on designated bits (taps) of the shift register.
2. **Serial Input Feed**: The XOR result is fed back into the serial input (flip-flop 1 / bit 0).
3. **Pseudo-Random Pattern**: Because XOR is deterministic, the output appears random but follows a repeatable mathematical pattern.
4. **Non-Zero Requirement**: If the register ever enters the all-zero state (`0000`), the feedback ($0 \oplus 0 = 0$) causes the register to remain trapped in `0` indefinitely. For this reason, the asynchronous reset must initialize the register to a non-zero seed value (e.g. `1`).

### 4-Bit LFSR Polynomial and Progression

The 4-bit LFSR is defined by the primitive polynomial:
$$1 + X^3 + X^4$$

- **Feedback Taps**: Outputs from flip-flop 4 ($Q_4$) and flip-flop 3 ($Q_3$) are XORed together.
- **Next LSB**: $D_1 = Q_4 \oplus Q_3$ (expressed in 1-indexed notation as `sreg[3] ^ sreg[4]`).
- **Maximal Sequence Length**: The cycle visits all $2^4 - 1 = 15$ non-zero states before looping back to the seed:
  `0001` $\to$ `0010` $\to$ `0100` $\to$ `1001` $\to$ `0011` $\to$ `0110` $\to$ `1101` $\to$ `1010` $\to$ `0101` $\to$ `1011` $\to$ `0111` $\to$ `1111` $\to$ `1110` $\to$ `1100` $\to$ `1000` $\to$ `0001`

### 7-Bit LFSR Polynomial and Challenge Implementation

The 7-bit challenge circuit expands the sequence length using the primitive polynomial:
$$1 + X^3 + X^7$$

- **Feedback Taps**: Taps are taken from stage 3 and stage 7.
- **In 0-Indexed Notation (`[6:0]`)**:
  - Stage 7 corresponds to bit `6` (`sreg[6]`)
  - Stage 3 corresponds to bit `2` (`sreg[2]`)
  - The feedback bit is `sreg[6] ^ sreg[2]`
- **Shift Operation**: Lower bits `sreg[5:0]` shift left, and the feedback bit fills the new LSB.
- **Maximal Sequence Length**: Cycles through $2^7 - 1 = 127$ unique states before repeating.

## Verification via Google Test (GTest)

### Testbench Architecture

Testing is automated using GTest combined with Verilator:

1. **`TestDut` Fixture**:
   - `SetUp()` initializes input signals (`clk = 0`, `rst = 0`, `en = 1`) and pulses reset before every test case.
   - `runSimulation()` advances the clock by 1 full cycle (low-to-high-to-low), calls `top->eval()` to recompute logic, and dumps state transitions to `waveform.vcd`.
2. **`InitialStateTest`**: Verifies that asserting asynchronous reset forces `data_out` to `1` (`0b0001`).
3. **`SequenceTest`**: 
   - Compares the simulation output `top->data_out` against the reference values.
   - For the 4-bit LFSR, iterates through the precomputed 15-state vector.
   - For the 7-bit LFSR, compares `top->data_out` dynamically against a software model (`generateLFSR7`) over 128 clock cycles.

## Waveform Inspection

When running the simulation via `verify.sh`, waveform transitions are captured in `waveform.vcd`:
- Confirms asynchronous reset immediately forces the register to `1`.
- Confirms state changes happen exclusively on the positive edge of `clk` when `en == 1`.
- Shows proper shifting and feedback bit injection into the LSB.

## Challenge Completed: ✓

The implementation successfully demonstrates:
1. 4-bit LFSR implementation with asynchronous reset to a non-zero state (`1`).
2. Correct XOR feedback tapping according to primitive polynomial $1 + X^3 + X^4$.
3. Maximal-length 15-cycle pseudo-random sequence verified via Google Test.
4. 7-bit LFSR challenge design implemented with primitive polynomial $1 + X^3 + X^7$.
5. Full 127-state sequence verification dynamically validated against an algorithmic reference model.
