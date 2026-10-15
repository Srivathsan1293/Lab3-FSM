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
