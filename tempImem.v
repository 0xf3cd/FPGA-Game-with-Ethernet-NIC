module imem(
	input [10:0]addr,
	output reg[31:0]inst
);
	always @(*) begin
		if(addr <= 11'd10) begin
			inst = 32'b0;
		end else begin
			inst = 32'b1;
		end
	end

endmodule