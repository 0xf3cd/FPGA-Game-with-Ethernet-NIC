module EthernetSendData(
	input clk,
	input [31:0]wdata,
	input we,
	output reg [31:0]send_data = 32'b0
);
	always @(negedge clk) begin
		if(we) begin
			send_data <= wdata;
		end else begin
			send_data <= send_data;
		end
	end
endmodule