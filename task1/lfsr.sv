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

