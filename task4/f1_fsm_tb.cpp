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
		for (int clk = 0; clk < 2; clk++) {
			tfp->dump(2*i + clk);
			top->clk = !top->clk;
			top->eval();
		}
        top->trigger = vbdFlag();
		current_val = top->data_out & 0xFF;
		if (prev_val == 0xFF && current_val = 0x00){
			vbdInitWatch();
			timer = true;
		}

		if (waiting_reaction) {
			if (vbdFlag()) {          // User pressed the switch!
				int reaction_time = vbdElapsed(); // Read time in ms
				vbdHex(3, (reaction_time >> 8) & 0xF);
				vbdHex(2, (reaction_time >> 4) & 0xF);
				vbdHex(1, reaction_time & 0xF);
				waiting_reaction = false;
			} 
		}else {
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
