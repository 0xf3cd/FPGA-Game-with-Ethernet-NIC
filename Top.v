module Top(
	input clk_100,
	input reset,
	input [14:0]switch,
	input RXD1,
	input RXD0,
	input RXERR,
	input CRS_DV,
	output H_SYNC,
	output V_SYNC,
	output [11:0]RGB,
	output [7:0]atog,
	output [7:0]seg_cs,
	output MDIO,
	output MDC,
	output RESET,
	output Eth_Clk,
	output TXD0,
	output TXD1,
	output TXEN,
); 

	wire clk_cpu;
	//分频器
//	(
//      // Clock out ports
//      output        clk_out1,
//      // Status and control signals
//      input         reset,
//      output        locked,
//     // Clock in ports
//      input         clk_in1
//     );
	clk_wiz_0 clk_div(.clk_out1(clk_cpu), .reset(reset), .locked(), .clk_in1(clk_100));
	//assign clk_cpu = clk_100;
//	reg clk_div = 1'b0;
//	always @(posedge clk_100)
//        clk_div <= clk_div + 1'b1;
        
//    assign clk_cpu = clk_div;

    reg clk_1Hz = 1'b0;
    reg [25:0]timer_clk = 26'b0;
    always @(posedge clk_100) begin
    	if(timer_clk == 26'd49999999) begin
    		timer_clk <= 26'b0;
    		clk_1Hz <= ~clk_1Hz;
    	end else begin
    		timer_clk <= timer_clk + 1'b1;
    		clk_1Hz <= clk_1Hz;
    	end
    end

	wire [31:0]pc;
	wire [31:0]inst;
	wire [31:0]addr;
	wire [31:0]wdata;
	wire we;
	wire [31:0]rdata;
   	CPU CPU_(
	    .clock(clk_cpu),
	    .reset(reset),
	    .instruction(inst),//IMEM读出的指令
	    .read_data(rdata),//DMEM读出的数据
	    .PC(pc),
	    .DMEM_address(addr),//DMEM的读写地址
	    .write_data(wdata),//写入DMEM的数据
	    .DMEM_WRITE(we)//DMEM写有效信号
	);

   	wire [31:0]actual_pc = pc - 32'h00400000;
	imem imem_(actual_pc[12:2], inst);

	wire Timer_we;
	wire [31:0]Timer_out;
	Timer Timer_(
		.clk_cpu(clk_cpu),
		.clk_1Hz(clk_1Hz),
		.wdata(wdata),
		.we(Timer_we),
		.value(Timer_out)
	);

	wire VGA_we;
	VGA VGA_(
		.clk(clk_100),
		.wdata(wdata),
		.we(VGA_we),
		.H_SYNC(H_SYNC),
		.V_SYNC(V_SYNC),
		.RGB(RGB)
	);

	wire Seg_we;
	Seg Seg_(
		.clk(clk_100),
		.wdata(wdata),
		.we(Seg_we),
		.atog(atog),
		.seg_cs(seg_cs)
	);

	wire [31:0]actual_dmem_addr = addr - 32'h10010000;
	wire DMEM_we;
	wire [31:0]DMEM_out;
	dmem dmem_(actual_dmem_addr[10:0], wdata, ~clk_100, DMEM_we, DMEM_out);

	wire EthRst_we;
	wire [31:0]EthRst;
	EthernetReset EthRst_(
		.clk(clk_100),
		.wdata(wdata),
		.we(EthRst_we),
		.EthRst(EthRst)
	);

	wire EthSendData_we;
	wire [31:0]Eth_send_data;
	EthernetSendData ESD(
		.clk(clk_100),
		.wdata(wdata),
		.we(EthSendData_we),
		.send_data(Eth_send_data)
	);

	wire EthSendEna_we;
	wire [31:0]Eth_send_ena;
	EthernetSendData ESD(
		.clk(clk_100),
		.wdata(wdata),
		.we(EthSendEna_we),
		.send_ena(Eth_send_ena)
	);

	wire [31:0]EthNew;
	wire [31:0]EthData1;
	wire [31:0]EthData2;
	wire [31:0]EthSendFinish;
	Ethernet E_(
		.CLK100(clk_100),
		.MDIO(MDIO),
		.MDC(MDC),
		.RESET(RESET),
		.reset(EthRst),
		.RXD1(RXD1),
		.RXD0(RXD0),
		.RXERR(RXERR),
		.CRS_DV(CRS_DV),
		.TXD0(TXD0),
		.TXD1(TXD1),
		.TXEN(TXEN),
		.CLKIN(Eth_Clk),
		.data({EthData1, EthData2}),
		.get_new(EthNew),
		.s_data(Eth_send_data),
		.s_ena(Eth_send_ena),
		.s_finish(EthSendFinish)
	);

	WriteSelect WS(
		.addr(addr),
		.we(we),
		.DMEM_we(DMEM_we),
		.Seg_we(Seg_we),
		.VGA_we(VGA_we),
		.Timer_we(Timer_we),
		.EthRst_we(EthRst_we)
	);

	wire [31:0]swtich_out;
	Switch Swtich_(
		.clk(clk_100),
		.sw(switch),
		.switch(swtich_out)
	);

	wire [31:0]random_out;
	RandomGenerator RG(clk_100, random_out);

	ReadSelect RS(
	.addr(addr),
	.DMEM(DMEM_out),
	.Random(random_out),
	.Switch(swtich_out),
	.Timer(Timer_out),
	.EthNew(EthNew),
	.EthData1(EthData1),
	.EthData2(EthData2),
	.EthSendFinish(EthSendFinish),
	.rdata(rdata)
);
endmodule