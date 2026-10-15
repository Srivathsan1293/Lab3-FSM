# Google Test (GTest) Reference Guide

This guide provides a reference for using Google Test (GTest) in C++ and Verilator testbenches for digital hardware verification.

---

## 1. What is GTest?

Google Test (GTest) is an industry-standard C++ testing framework. In hardware verification, Verilator compiles SystemVerilog into a C++ model (often named `Vdut`), and GTest is used as the test harness to:
- Drive inputs into the DUT (Device Under Test) on each clock cycle.
- Automatically check outputs against expected values.
- Report detailed failure messages with expected vs. actual values.
- Integrate into automated test and CI/CD pipelines.

---

## 2. Core Concepts

### A. Test Fixture (`class ... : public ::testing::Test`)
A **Test Fixture** is a C++ class that shares common code across multiple test cases.

```cpp
class TestDut : public ::testing::Test {
protected:
    void SetUp() override {
        // Runs BEFORE every single test case (TEST_F)
        // Ideal for resetting hardware and setting initial inputs
    }

    void TearDown() override {
        // Runs AFTER every single test case (TEST_F)
        // Ideal for closing trace files, freeing memory, etc.
    }
};
```

### B. Test Cases (`TEST` vs `TEST_F`)
- **`TEST(TestSuiteName, TestName)`**: For standalone tests that do **not** need a fixture.
- **`TEST_F(TestFixtureName, TestName)`**: For tests that **use a fixture**. Each test case gets a fresh instance of the fixture class, ensuring tests are isolated and do not contaminate each other.

### C. Assertions (`EXPECT_*` vs `ASSERT_*`)

| Macro | Description | Failure Behavior |
| :--- | :--- | :--- |
| `EXPECT_EQ(a, b)` | Check $a == b$ | Logs failure, **continues** the test |
| `ASSERT_EQ(a, b)` | Check $a == b$ | Logs failure, **immediately aborts** current test |
| `EXPECT_NE(a, b)` | Check $a \neq b$ | Logs failure, continues |
| `EXPECT_TRUE(cond)`| Check condition is true | Logs failure, continues |
| `EXPECT_FALSE(cond)`| Check condition is false | Logs failure, continues |
| `EXPECT_LT(a, b)` | Check $a < b$ | Logs failure, continues |
| `EXPECT_LE(a, b)` | Check $a \le b$ | Logs failure, continues |
| `EXPECT_GT(a, b)` | Check $a > b$ | Logs failure, continues |
| `EXPECT_GE(a, b)` | Check $a \ge b$ | Logs failure, continues |

> **Rule of Thumb**: Use `EXPECT_*` by default so you can see all failing assertions across the sequence. Use `ASSERT_*` only if a failure makes continuing the test meaningless (e.g. pointer is null).

---

## 3. General Hardware Verification Template (Verilator + GTest)

Below is the standard pattern used in `verify.cpp` files throughout this lab:

```cpp
#include "gtest/gtest.h"
#include "Vdut.h"              // Verilator compiled top-level module
#include "verilated.h"
#include "verilated_vcd_c.h"   // Waveform dumping

Vdut *top;
VerilatedVcdC *tfp;
unsigned int ticks = 0;

class TestDut : public ::testing::Test {
public:
    void SetUp() override {
        initializeInputs();
        runReset();
    }

    void TearDown() override {
        // Cleanup after each test if needed
    }

    void initializeInputs() {
        top->clk = 0;
        top->rst = 0;
        top->en = 1;
    }

    void runReset() {
        top->rst = 1;
        runSimulation();
        top->rst = 0;
    }

    // Toggles clock for 1 full cycle, updates DUT, dumps waveforms
    void runSimulation() {
        for (int clk = 0; clk < 2; clk++) {
            top->eval();
            if (tfp) tfp->dump(2 * ticks + clk);
            top->clk = !top->clk;
        }
        ticks++;

        if (Verilated::gotFinish()) exit(0);
    }
};

// Test 1: Check initial state after reset
TEST_F(TestDut, InitialStateTest) {
    top->rst = 1;
    runSimulation();
    EXPECT_EQ(top->data_out, 0b0001);
}

// Test 2: Check sequence over multiple clock cycles
TEST_F(TestDut, SequenceTest) {
    std::vector<int> expected = {
        0b0001,
        0b0010,
        0b0100,
        0b1001
    };

    for (int exp : expected) {
        EXPECT_EQ(top->data_out, exp);
        runSimulation();
    }
}

// Test runner main function
int main(int argc, char **argv) {
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

---

## 4. Compilation & Linking Reference

### Pure C++ GTest (Task 0 style)
```bash
# Linux (Arch / CachyOS / Ubuntu)
g++ -o test_main main.cpp -lgtest -lgtest_main -pthread

# macOS (Homebrew)
g++ -std=c++17 -o test_main main.cpp \
    -isystem /opt/homebrew/Cellar/googletest/1.17.0/include \
    -L/opt/homebrew/Cellar/googletest/1.17.0/lib \
    -lgtest -lgtest_main -pthread
```

### With Verilator (Tasks 1 & 2 style)
When invoking `verilator`, pass the GTest flags via `-CFLAGS` and `-LDFLAGS`:

```bash
verilator   -Wall --trace \
            -cc dut.sv \
            --exe verify.cpp \
            --prefix "Vdut" \
            -o Vdut \
            -CFLAGS "-std=c++17" \
            -LDFLAGS "-lgtest -lgtest_main -pthread"

make -j -C obj_dir/ -f Vdut.mk
./obj_dir/Vdut
```

---

## 5. Helpful Command-Line Options

When running a compiled GTest binary, you can pass arguments to control test execution:

- **Run only a specific test**:
  ```bash
  ./obj_dir/Vdut --gtest_filter=TestDut.InitialStateTest
  ```
- **Run all tests matching a pattern**:
  ```bash
  ./obj_dir/Vdut --gtest_filter=TestDut.*Sequence*
  ```
- **List all available tests without running them**:
  ```bash
  ./obj_dir/Vdut --gtest_list_tests
  ```
- **Stop on the first failure**:
  ```bash
  ./obj_dir/Vdut --gtest_break_on_failure
  ```
- **Repeat tests multiple times (stress testing)**:
  ```bash
  ./obj_dir/Vdut --gtest_repeat=10
  ```
