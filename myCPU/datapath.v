`timescale 1ns / 1ps
`include "defines.vh"
module datapath(
	
	input wire clk,rst,//时钟信号 重置信号
	
	//取指令阶段信号
	output wire[31:0] pcF, //取指令级地址寄存器
	input wire[31:0] instrF,// 取指令级的指令

	//指令译码阶段信号
	input wire pcsrcD,branchD, //译码阶段地址来源 与 条件跳转指令，相等则分支
	input wire jumpD,jalD, jrD, balD, jalrD,//跳转指令
	output wire equalD,//两个寄存器源操作数相等则有效
	output wire[5:0] opD,functD,// 指令的操作码字段 //指令的功能码字段
	input wire invalidD,//异常指令的判断
	output wire flushD,//译码级别刷新信号

	//运算级信号
	input wire memtoregE,//指令执行级的存储器写寄存器控制信号
	input wire alusrcE,regdstE,//执行指令级寄存器来源//指令执行级目标寄存器
	input wire regwriteE,//计算级控制是否写入寄存器
	input wire[7:0] alucontrolE,//计算单元计算类型选择
	output wire flushE,//指令运算级刷新信号

	//内存访问级信号
	input wire memtoregM,//内存操作级的存储器写寄存器控制信号
	input wire regwriteM,//访问内存级控制是否写入寄存器
	output wire[31:0] aluoutM,writedata2M,//运算级的运算结果//待写回内存的值
	input wire[31:0] readdataM,//内存级读出的数据
	input wire cp0weM,//cp0控制读写信号
	output wire flushM,//访存级刷新信号

	//写回级信号
	input wire memtoregW,//写回级的存储器写寄存器控制信号
	input wire regwriteW, //写回级读出的数据
	output wire flushW,

	output wire [4:0] rsE,rtE,rdE,saE,
	output wire [4:0] rsD,rtD,rdD,saD,
	
	output lwstallD,branchstallD,

	output wire stallF,stallD,stallE,
	output wire [31:0] instrD,
	
	input wire hilo_weE,
	input wire div_validE,signed_divE,
	output wire [3:0] selM,
	output wire [31:0] PCW,
	output wire [4:0] writeregW,
	output wire [31:0] resultW,
	input wire [5:0] int,
	output wire flush_except,
	input wire stallreq_from_if,
    input wire stallreq_from_mem,
	output wire stallM,
	output wire [1:0]sizeM
	//input wire m_i_readyF
);
	wire [31:0] instrD;
	//cp0 延迟槽
	wire is_in_delayslotF;
	wire is_in_delayslotD;
	wire is_in_delayslotE;
	wire is_in_delayslotM;

	wire flushF;

	//cp0要在M阶段访问rd寄存器
	wire[4:0] rdM;

	//cp0变量
	wire[`RegBus] count_o,compare_o,status_o,cause_o,epc_o, config_o,prid_o,badvaddr;
	wire[`RegBus] CP0_INDEX,CP0_ENTRYHI,CP0_ENTRYLO0,CP0_ENTRYLO1,CP0_PAGEMASK;
	wire forwardcp0E;
	wire [31:0] cp0dataE,cp0data2E;

	//异常------全部推倒M阶段处理
	wire [7:0] exceptF;
	wire [7:0] exceptD;
	wire [7:0] exceptE;
	wire [7:0] exceptM;
	wire syscallD,breakD,eretD;
	wire [31:0] excepttypeM;
	wire [31:0] newpcM;
	wire [4:0] tlb_except2M;//先添加在这
	wire timer_int_o;
	assign tlb_except2M = 5'b00000;

	//访存
	wire adelM,adesM;//取数据错误，存数据错误
	wire [31:0] bad_addrM;
	wire [5:0] opE;
	wire [5:0] opM;
	wire [31:0] writedataM;
	wire [31:0] finaldataM;
	wire [31:0] resultM;

	//分支跳转
	wire jumpE,jalE, jrE, balE, jalrE,branchE;
	wire [4:0] writereg2E;
	wire [31:0] aluout2E;
	wire [31:0] PCD;
	wire [31:0] PCE;
	wire [31:0] PCM;
//除法
	wire div_stallE;
	wire [63:0] div_resultE;
	//wire stallE;

	//取指令阶段信号

	//地址控制信号
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD;
	wire [31:0] pcnext2FD;

	//指令译码阶段信号
	wire [31:0] pcplus4D;
	wire [1:0]forwardaD,forwardbD;
	
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;

	//运算级信号
	wire [1:0] forwardaE,forwardbE;
	
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE;
	wire overflow;
	wire zero;

	//内存访问级信号
	wire [4:0] writeregM;

	//写回级信号
	//wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW;//resultW;

	//hilo寄存器输入输出
	wire [63:0] hilo_inE;
	wire [63:0] hilo_outE;
	// wire [63:0] hilo_outM;
	// assign hilo_inE=64'h0000000000000000;

	//CP0
	//wire [31:0] cp0_inE;
	wire [31:0] cp0_outE;
	wire [31:0] cp0_outM;
	//assign cp0_inE=32'h00000000;



	//冒险模块
	hazard h(

		//取指令阶段信号
		.stallF(stallF),
		.flushF(flushF),
		//指令译码阶段信号
		.rsD(rsD),
		.rtD(rtD),
		.branchD(branchD), 
		.jumpD(jumpD),
		.jalD(jalD),
		.jrD(jrD),
		.balD(balD),
		.jalrD(jalrD),
		.forwardaD(forwardaD),
		.forwardbD(forwardbD),
		.stallD(stallD),
		.flushD(flushD),
		
		//运算级信号
		.rsE(rsE),
		.rtE(rtE),
		.writeregE(writereg2E),
		.regwriteE(regwriteE),
		.memtoregE(memtoregE),
		.forwardaE(forwardaE),
		.forwardbE(forwardbE),
		.flushE(flushE),
		
		//内存访问级信号
		.writeregM(writeregM),
		.regwriteM(regwriteM),
		.memtoregM(memtoregM),
		.flushM(flushM),

		//写回级信号
		.writeregW(writeregW),
		.regwriteW(regwriteW),
		.flushW(flushW),

		.lwstallD(lwstallD),
		.branchstallD(branchstallD),
		.div_stallE(div_stallE),
		.stallE(stallE),
		.cp0weM(cp0weM),
		.rdM(rdM),
		.rdE(rdE),
		.excepttypeM(excepttypeM),
		.cp0_epcM(epc_o),
		.newpcM(newpcM),
		.forwardcp0E(forwardcp0E),
		.flush_except(flush_except),
		.stallreq_from_if(stallreq_from_if),
		.stallreq_from_mem(stallreq_from_mem),
		.stallM(stallM)
	);

	//下一个指令地址计算
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);  //地址计算部分
	mux2 #(32) pcmux(pcnextbrFD, {pcplus4D[31:28],instrD[25:0],2'b00}, jumpD|jalD, pcnextFD);  //地址计算部分
	mux2 #(32) pcjrmux(pcnextFD, srca2D, jrD|jalrD, pcnext2FD);

	//寄存器访问
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);


	//取指触发器
	pc #(32) pcreg(clk,rst,~stallF,flushF,pcnext2FD,newpcM,pcF);  //地址计算部分
	adder pcadd1(pcF,32'b100,pcplus4F);  //地址计算部分

	//取值发生异常，地址错误
	assign exceptF = (pcF[1:0] == 2'b00) ? 8'b00000000 : 8'b10000000;
	//判断指令是否在延迟槽中
	assign is_in_delayslotF = (jumpD|jalrD|jrD|jalD|branchD);

	//译指触发器
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);  //地址计算部分
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(32) r3D(clk,rst,~stallD,flushD,pcF,PCD);
	flopenrc #(8)  r4D(clk,rst,~stallD,flushD,exceptF,exceptD);
	flopenrc #(1)  r5D(clk,rst,~stallD,flushD,is_in_delayslotF,is_in_delayslotD);

	// 参考吕玉凤的视频
	signext se(instrD[15:0],instrD[29:28], signimmD); //32位符号扩展立即数
	sl2 immsh(signimmD,signimmshD); //地址计算部分

	adder pcadd2(pcplus4D,signimmshD,pcbranchD);  //地址计算部分

	//mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	//mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	mux4 #(32) forwardadmux(srcaD,aluout2E,resultM,resultW,forwardaD,srca2D);
	mux4 #(32) forwarddmux(srcbD,aluout2E,resultM,resultW,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,opD,rtD,equalD);
	//CP0前推
	mux2 #(32) forwardcp0mux(cp0dataE,cp0_outM,forwardcp0E,cp0data2E);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD=instrD[10:6];

	//syscall、break、eret
	assign syscallD = (opD == 6'b000000 && functD == 6'b001100)&& (~stallD);
	assign breakD = (opD == 6'b000000 && functD == 6'b001101)&& (~stallD);
	assign eretD = (instrD == 32'b01000010000000000000000000011000)&& (~stallD);
	wire invalid2D;
	assign invalid2D = invalidD && ~stallD;
	//运算级信号触发器
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(5)  r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5)  r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5)  r6E(clk,rst,~stallE,flushE,rdD,rdE);
	flopenrc #(5)  r7E(clk,rst,~stallE,flushE,saD,saE);
	flopenrc #(6)  r8E(clk,rst,~stallE,flushE,{jumpD,jalD, jrD, balD, jalrD,branchD},{jumpE,jalE, jrE, balE, jalrE,branchE});
	flopenrc #(32) r9E(clk,rst,~stallE,flushE,PCD,PCE);
	flopenrc #(6)  raE(clk,rst,~stallE,flushE,opD,opE);
	flopenrc #(8)  rbE(clk,rst,~stallE,flushE,{exceptD[7],syscallD,breakD,eretD,invalid2D,exceptD[2:0]},exceptE);
	flopenrc #(1)  rcE(clk,rst,~stallE,flushE,is_in_delayslotD,is_in_delayslotE);

	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	alu alu(srca2E,srcb3E,saE,hilo_inE,cp0data2E,alucontrolE,aluoutE,hilo_outE,cp0_outE,overflow,zero);
	div_self_align div(~clk, rst, srca2E,srcb3E, div_validE, signed_divE, div_stallE, div_resultE);
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE);

	mux2 #(5) wrmux2(writeregE, 5'b11111, jalE|balE, writereg2E);
	mux2 #(32) wrmux3(aluoutE, PCE+8, jalE|jrE|jalrE|balE, aluout2E);
	// 出发选择器
	wire div_signal;
	wire [63:0] hilo_out2E;
	assign div_signal = ((alucontrolE == `EXE_DIV_OP)|(alucontrolE == `EXE_DIVU_OP))? 1 : 0;
	mux2 #(64) div_mux(hilo_outE, div_resultE, div_signal,hilo_out2E);

	//内存访问级信号触发器
	flopenrc #(32) r1M(clk,rst,~stallM,flushM,srcb2E,writedataM);
	flopenrc #(32) r2M(clk,rst,~stallM,flushM,aluout2E,aluoutM);
	flopenrc #(32) r9M(clk,rst,~stallM,flushM,cp0_outE,cp0_outM);
	flopenrc #(5)  r3M(clk,rst,~stallM,flushM,writereg2E,writeregM);
	flopenrc #(32) r4M(clk,rst,~stallM,flushM,PCE,PCM);
	flopenrc #(6)  r5M(clk,rst,~stallM,flushM,opE,opM);
	flopenrc #(8)  r6M(clk,rst,~stallM,flushM,{exceptE[7:3],overflow,exceptE[1:0]},exceptM);
	flopenrc #(5)  r7M(clk,rst,~stallM,flushM,rdE,rdM);
	flopenrc #(1)  r8M(clk,rst,~stallM,flushM,is_in_delayslotE,is_in_delayslotM);
 
	// flopr #(64) r4M(clk,rst,hilo_outE, hilo_outM); 删除了hilo_outM, 因为会晚一个周期
	hilo_reg hilo(clk, rst, (hilo_weE&(~flushE)), hilo_out2E[63:32], hilo_out2E[31:0],  hilo_inE[63:32], hilo_inE[31:0]);

	memsel select(PCM,opM,aluoutM,writedataM,readdataM,selM,writedata2M,finaldataM,bad_addrM,adelM,adesM,sizeM);
	
	// 异常类型判断
	exception exp(rst,exceptM,tlb_except2M,adelM,adesM,status_o,cause_o,excepttypeM);
	
	// cp0寄存器
	cp0 CP0(
		.clk(clk),
		.rst(rst),

		.we_i(cp0weM),
		.waddr_i(rdM),
		.raddr_i(rdE),
		.data_i(cp0_outM),

		.int_i(int),

		.excepttype_i(excepttypeM),
		.current_inst_addr_i(PCM),
		.is_in_delayslot_i(is_in_delayslotM),
		.bad_addr_i(bad_addrM),

		.data_o(cp0dataE),
		.count_o(count_o),
		.compare_o(compare_o),
		.status_o(status_o),
		.cause_o(cause_o),
		.epc_o(epc_o),
		.config_o(config_o),
		.prid_o(prid_o),
		.badvaddr(badvaddr),
		.timer_int_o(timer_int_o)
	);

	mux2 #(32) resmux(aluoutM, finaldataM, memtoregM, resultM);
	//写回级信号触发器
	floprc #(32) r1W(clk,rst,flushW,aluoutM,aluoutW);
	floprc #(32) r2W(clk,rst,flushW,readdataM,readdataW);
	floprc #(5)  r3W(clk,rst,flushW,writeregM,writeregW);
	floprc #(32) r4W(clk,rst,flushW,resultM,resultW);
	floprc #(32) r5W(clk,rst,flushW,PCM,PCW);
endmodule