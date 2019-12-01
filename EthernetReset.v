module EthernetReset(
	input clk,
	input [31:0]wdata,
	input we,
	output reg [31:0]EthRst = 32'b0
);
	always @(negedge clk) begin
		if(we) begin
			EthRst <= wdata;
		end else begin
			EthRst <= EthRst;
		end
	end
endmodule