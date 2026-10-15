#include "Vdelayed_f1.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "vbuddy.cpp"

int main(int argc, char **argv, char **env) {
	Verilated::commandArgs(argc, argv);
	Vdelayed_f1* top = new Vdelayed_f1;
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	top->trace(tfp, 99);
	tfp->open("delayed_f1.vcd");

	if (vbdOpen() != 1) return(-1);
	vbdHeader("Lab 3:f1 lights");
	vbdSetMode(0);
		
	top->clk = 0;
	top->rst = 0;
        top->en = 0;

	for (int i = 0; i < 1000000; i++) {
		// 1. ALWAYS dump time, toggle the clock, and evaluate the model
		for (int clk = 0; clk < 2; clk++) {
			tfp->dump(2*i + clk);
			top->clk = !top->clk;
			top->eval();
		}
              
                top->en = vbdFlag();
		vbdBar(top->data_out & 0xFF);
		vbdCycle(i+1);
		 
		if ((Verilated::gotFinish()) || (vbdGetkey()=='q'))  exit(0);
	}
	vbdClose();
	tfp->close();
	exit(0);
}
