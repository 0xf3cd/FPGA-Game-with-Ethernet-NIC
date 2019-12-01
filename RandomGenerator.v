module RandomGenerator(CLK, RANDOM_RESULT);
	input CLK;
	output [31:0]RANDOM_RESULT;

	/*
	经验证，反馈系数为0111000111010110时随机循环达到最大，为65535
	*/

	reg [15:0]RANDOM_RESULT1 = 16'hf073;
	always @(posedge CLK)begin
		RANDOM_RESULT1[0] <= RANDOM_RESULT1[15];
		RANDOM_RESULT1[1] <= RANDOM_RESULT1[0] ^ RANDOM_RESULT1[15];
		RANDOM_RESULT1[2] <= RANDOM_RESULT1[1] ^ RANDOM_RESULT1[15];
		RANDOM_RESULT1[3] <= RANDOM_RESULT1[2] ^ RANDOM_RESULT1[15];
		RANDOM_RESULT1[4] <= RANDOM_RESULT1[3];
		RANDOM_RESULT1[5] <= RANDOM_RESULT1[4];
		RANDOM_RESULT1[6] <= RANDOM_RESULT1[5];
		RANDOM_RESULT1[7] <= RANDOM_RESULT1[6] ^ RANDOM_RESULT1[15];
		RANDOM_RESULT1[8] <= RANDOM_RESULT1[7] ^ RANDOM_RESULT1[15];
		RANDOM_RESULT1[9] <= RANDOM_RESULT1[8] ^ RANDOM_RESULT1[15];
		RANDOM_RESULT1[10] <= RANDOM_RESULT1[9];
		RANDOM_RESULT1[11] <= RANDOM_RESULT1[10] ^ RANDOM_RESULT1[15];
		RANDOM_RESULT1[12] <= RANDOM_RESULT1[11];
		RANDOM_RESULT1[13] <= RANDOM_RESULT1[12] ^ RANDOM_RESULT1[15];
		RANDOM_RESULT1[14] <= RANDOM_RESULT1[13] ^ RANDOM_RESULT1[15];
		RANDOM_RESULT1[15] <= RANDOM_RESULT1[14];
	end

	reg [15:0]RANDOM_RESULT2 = 16'h004a;
	always @(posedge CLK)begin
		RANDOM_RESULT2[0] <= RANDOM_RESULT2[15];
		RANDOM_RESULT2[1] <= RANDOM_RESULT2[0] ^ RANDOM_RESULT2[15];
		RANDOM_RESULT2[2] <= RANDOM_RESULT2[1] ^ RANDOM_RESULT2[15];
		RANDOM_RESULT2[3] <= RANDOM_RESULT2[2] ^ RANDOM_RESULT2[15];
		RANDOM_RESULT2[4] <= RANDOM_RESULT2[3];
		RANDOM_RESULT2[5] <= RANDOM_RESULT2[4];
		RANDOM_RESULT2[6] <= RANDOM_RESULT2[5];
		RANDOM_RESULT2[7] <= RANDOM_RESULT2[6] ^ RANDOM_RESULT2[15];
		RANDOM_RESULT2[8] <= RANDOM_RESULT2[7] ^ RANDOM_RESULT2[15];
		RANDOM_RESULT2[9] <= RANDOM_RESULT2[8] ^ RANDOM_RESULT2[15];
		RANDOM_RESULT2[10] <= RANDOM_RESULT2[9];
		RANDOM_RESULT2[11] <= RANDOM_RESULT2[10] ^ RANDOM_RESULT2[15];
		RANDOM_RESULT2[12] <= RANDOM_RESULT2[11];
		RANDOM_RESULT2[13] <= RANDOM_RESULT2[12] ^ RANDOM_RESULT2[15];
		RANDOM_RESULT2[14] <= RANDOM_RESULT2[13] ^ RANDOM_RESULT2[15];
		RANDOM_RESULT2[15] <= RANDOM_RESULT2[14];
	end

	assign RANDOM_RESULT = {RANDOM_RESULT1, RANDOM_RESULT2};
endmodule