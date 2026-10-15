module delayed_f1 (
	input logic rst, clk, en,
	output logic [7:0] data_out
);
	logic tick;
	clktick timer (.clk(clk), .rst(rst), .en(en), .N(16'h16), .tick(tick));
	
	f1_fsm lights (.en(tick), .rst(rst), .clk(clk), .data_out(data_out));


endmodule
