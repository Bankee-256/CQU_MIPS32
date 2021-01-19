`timescale 1ns / 1ps
module controller(
	input wire clk,rst,
	
	//decode stage
	input wire[31:0] instrD,
	output wire pcsrcD,branchD,jumpD, jalD, jrD, balD, jalrD,
	input stallD,
	input equalD,
	input stallE,
	
	//execute stage
	input wire flushE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire[7:0] alucontrolE,

	//mem stage
	output wire memtoregM,memwriteM,regwriteM,
	output wire cp0weM,
	input wire flushM,
	
	//write back stage
	output wire memtoregW,regwriteW,
	input wire flushW,

    output wire hilo_weE,
	output wire div_validE,signed_divE,
	output wire memenM,
	output wire invalidD,
	input wire stallM
);
	
	//decode stage
	wire memtoregD,memwriteD,alusrcD,regdstD,regwriteD,memenD;
	wire memenE;
	wire[7:0] alucontrolD;
	wire div_validD, signed_divD;
	wire cp0weD;
	//execute stage
	wire memwriteE;
	wire cp0weE;
	//hilo
    wire hilo_weD;
	wire [7:0] alucontrolM;
	maindec md(stallD, instrD, memtoregD, memenD, memwriteD, branchD, alusrcD, regdstD, regwriteD,jumpD, jalD, jrD, balD, jalrD,hilo_weD,div_validD,signed_divD,invalidD,cp0weD);
	//maindec md(
	//	stallD,instrD,
	//	memtoregD,memenD,memwriteD,
	//	branchD,alusrcD,
	//	regdstD,regwriteD,
	//	jumpD,jalD,jrD,balD,
	//	hilo_weD
	//);

	aludec ad(instrD,stallD,alucontrolD);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	flopenrc #(18) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,hilo_weD,div_validD,signed_divD,memenD,cp0weD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,hilo_weE,div_validE,signed_divE,memenE,cp0weE}
	);

	flopenrc #(20) regM(
		clk,rst,
		~stallM,
		flushM,
		{memtoregE,memwriteE,regwriteE,memenE,cp0weE,alucontrolE},
		{memtoregM,memwriteM,regwriteM,memenM,cp0weM,alucontrolM}
	);

	floprc #(20) regW(
		clk,rst,
		flushW,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
	);

endmodule