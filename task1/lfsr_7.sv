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
