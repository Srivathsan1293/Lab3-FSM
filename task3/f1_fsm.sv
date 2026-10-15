module f1_fsm(
	input logic en, rst, clk, 
	output logic [7:0] data_out
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
			s0: if (en) next_state = s1;
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
			s0: data_out = 8'b0;
			s1: data_out = 8'b1;
			s2: data_out = 8'b11;
			s3: data_out = 8'b111;
			s4: data_out = 8'b1111;
			s5: data_out = 8'b11111;
			s6: data_out = 8'b111111;
			s7: data_out = 8'b1111111;
			s8: data_out = 8'b11111111;
			default: data_out = 8'b0;
		endcase
	end
	
endmodule

