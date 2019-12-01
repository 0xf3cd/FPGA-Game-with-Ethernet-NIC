`timescale 1ns / 1ps

module Divider5MHz(
	input clk,
	output reg clk_5 = 1'b0
);
	reg [3:0]count = 4'b0;

	always @(posedge clk) begin
		if(count == 4'd9) begin
			count <= 4'b0;
			clk_5 <= ~clk_5;
		end else begin
			count <= count + 1'b1;
			clk_5 <= clk_5;
		end
	end
endmodule

module Divider50MHz(
	input clk,
	output reg clk_50 = 1'b0
);

	always @(posedge clk) begin
		clk_50 <= ~clk_50;
	end
endmodule

module InterWeave(
	input [7:0]r1,
	input [7:0]r0,
	output [15:0]r
);
	assign r = {r1[4], r0[4], r1[5], r0[5], r1[6], r0[6], r1[7], r0[7], r1[0], r0[0], r1[1], r0[1], r1[2], r0[2], r1[3], r0[3]};
endmodule

module mem(
	input clk,
	input [31:0]send_data,
	input [6:0]addr,
	output [7:0]out_data
);
	reg [7:0]memory[127:0];
	integer i;
	initial begin
		for(i = 0; i < 7; i = i + 1) begin
			memory[i] = 8'hAA;
		end
		memory[7] = 8'hAB;
		for(i = 8; i < 128; i = i + 1) begin
			memory[i] = 8'b0;
		end
	end

	always @(negedge clk) begin
		memory[8] <= send_data[31:24];
		memory[9] <= send_data[23:16];
		memory[10] <= send_data[15:8];
		memory[11] <= send_data[7:0];
	end

	assign out_data = memory[addr];
endmodule

module Ethernet(
	input CLK100,
	output MDIO,
	output MDC,
	output RESET,
	input [31:0]reset,
	input RXD1,
	input RXD0,
	input RXERR,
	input CRS_DV,
	output reg TXD0,
	output reg TXD1,
	output reg TXEN,
	output CLKIN,
	output reg [63:0]data,
	output reg [31:0]get_new,
	input [31:0]s_data,
	input [31:0]s_ena,
	output reg [31:0]s_finish
);
	wire clk5;
	wire clk50;
	Divider5MHz div5(CLK100, clk5);
	Divider50MHz div50(CLK100, clk50);

	assign MDIO = 1;
	assign MDC = clk5;
	assign CLKIN = clk50;
	assign RESET = 1;

	wire r_valid;
	assign r_valid = CRS_DV & RXD1 & RXD0;

	parameter IDLE = 8'b00000001;
	parameter RECEIVE = 8'b00000010;
	parameter DATA1 = 8'b00000100;
	parameter DATA2 = 8'b00001000;
	parameter DATA3 = 8'b00010000;
	parameter DATA4 = 8'b00100000;
	parameter REND = 8'b01000000;
	parameter SEND = 8'b10000000;

	reg [7:0]current_state = IDLE; 
	reg [7:0]next_state;
	reg r_ena = 1'b0;
	reg [7:0]count = 8'b0;
	reg [31:0]r1_data = 32'b0;
	reg [31:0]r0_data = 32'b0;

	reg [6:0]address;
	wire [7:0]mem_out;
	reg [7:0]to_send;
	mem mem_(clk50, s_data, address, mem_out);

	always @(negedge clk50) begin
		current_state <= next_state;
	end

	always @(*) begin
		case(current_state)
			IDLE: begin
				if(r_valid == 1'b1) begin
					next_state = RECEIVE;
				end else if(s_ena) begin
					next_state = DATA1;
				end else begin
					next_state = IDLE;
				end
			end
			RECEIVE: begin
				if(count == 8'd32) begin
					next_state = REND;
				end else begin
					next_state = RECEIVE;
				end
			end
			DATA1: begin
				next_state = DATA2;
			end
			DATA2: begin
				next_state = DATA3;
			end
			DATA3: begin
				next_state = DATA4;
			end
			DATA4: begin
				if(address == 7'd68) begin
					next_state = SEND;
				end else begin
					next_state = DATA1;
				end
			end
			REND: begin
				if(reset == 1'b1) begin
					next_state = IDLE;
				end else begin
					next_state = REND;
				end
			end
			SEND: begin
				if(reset == 1'b1) begin
					next_state = IDLE;
				end else begin
					next_state = SEND;
				end
			end
			default: begin
				next_state = IDLE;
			end
		endcase
	end

	always @(*) begin
		if(current_state == RECEIVE) begin
			r_ena = 1'b1;
		end else begin
			r_ena = 1'b0;
		end
	end

	always @(posedge clk50) begin
		if(current_state == IDLE) begin
			count <= 8'b0;
		end else begin
			count <= count + 1'b1;
		end
	end

	always @(posedge clk50) begin
		if(r_ena == 1'b1) begin
			r1_data <= {r1_data[30:0], RXD1};
			r0_data <= {r0_data[30:0], RXD0};
		end else begin
			r1_data <= r1_data;
			r0_data <= r0_data;
		end
	end
	
	wire [63:0]data_from_PC;
	InterWeave IW1(r1_data[7:0], r0_data[7:0], data_from_PC[15:0]);
	InterWeave IW2(r1_data[15:8], r0_data[15:8], data_from_PC[31:16]);
	InterWeave IW3(r1_data[23:16], r0_data[23:16], data_from_PC[47:32]);
	InterWeave IW4(r1_data[31:24], r0_data[31:24], data_from_PC[63:48]);
	always @(negedge clk50) begin
		data <= data_from_PC;
	end

	always @(posedge clk50) begin
		if(current_state == REND) begin
			get_new <= 32'b1;
		end else begin
			get_new <= 32'b0;
		end
	end

	always @(posedge clk50) begin
		if(current_state == SEND) begin
			s_finish <= 32'b1;
		end else begin
			s_finish <= 32'b0;
		end
	end

	always @(posedge clk50) begin
		if(current_state == DATA4) begin
			address <= address + 1'b1;
		end else if(current_state == IDLE) begin
			address <= 7'b0;
		end else begin
			address <= address;
		end
	end

	always @(*) begin //锁存器
		if(current_state == DATA1) begin
			to_send = mem_out;
		end else begin
			to_send = to_send;
		end
	end

	always @(*) begin
		case(current_state)
			DATA1: begin
				TXEN = 1'b1;
			end
			DATA2: begin
				TXEN = 1'b1;
			end
			DATA3: begin
				TXEN = 1'b1;
			end
			DATA4: begin
				TXEN = 1'b1;
			end
			default: begin
				TXEN = 1'b0;
			end
		endcase
	end

	always @(*) begin
		case(current_state)
			DATA1: begin
				TXD0 = to_send[7];
				TXD1 = to_send[6];
			end
			DATA2: begin
				TXD0 = to_send[5];
				TXD1 = to_send[4];
			end
			DATA3: begin
				TXD0 = to_send[3];
				TXD1 = to_send[2];
			end
			DATA4: begin
				TXD0 = to_send[1];
				TXD1 = to_send[0];
			end
			default: begin
				TXD0 = to_send[7];
				TXD1 = to_send[6];
			end
		endcase
	end
endmodule