`timescale 1ns / 1ps
module hazard(
    input [4:0] rsD, rtD,
    input [4:0] rsE, rtE,
    input wire branchD,jumpD, jalD, jrD,balD,jalrD,
    input [4:0] writeregE,
    input regwriteE,
    input memtoregE,
    input [4:0] writeregM,
    input regwriteM,
    input memtoregM,
    input [4:0] writeregW,
    input regwriteW,
    output stallF,
    output [1:0] forwardaD, forwardbD,
    output stallD,
    output [1:0] forwardaE, forwardbE,
    output flushF,flushD,flushE,flushM,flushW,
    output lwstallD,
    output branchstallD,
    input wire div_stallE,
    output wire stallE,
    input wire cp0weM,
    input wire [4:0] rdM,
    input wire [4:0] rdE,
    input [31:0] excepttypeM,
	input wire [31:0] cp0_epcM,
	output reg [31:0] newpcM,
    output wire forwardcp0E,
    output wire flush_except,
    input wire stallreq_from_if,
    input wire stallreq_from_mem,
    output wire stallM
    
    );
    wire jalrstallD;
    //wire flush_except;
    assign flush_except = (excepttypeM != 32'b0 );

    assign forwardaE= (rsE!=0 & rsE==writeregM & regwriteM)? 2'b10:
					  (rsE!=0 & rsE==writeregW & regwriteW)? 2'b01: 2'b00;
	assign forwardbE= (rtE!=0 & rtE==writeregM & regwriteM)? 2'b10:
					  (rtE!=0 & rtE==writeregW & regwriteW)? 2'b01: 2'b00;
    assign stallF = (lwstallD | branchstallD | div_stallE | jalrstallD |stallreq_from_if | stallreq_from_mem);
    assign stallD = stallF;//(lwstallD | branchstallD | div_stallE | jalrstallD);//|stallreq_from_if| stallreq_from_mem);
    assign stallE = div_stallE|stallreq_from_mem;
    assign stallM = stallreq_from_mem;

    assign branchstallD = branchD & ( regwriteE  &  (writeregE == rsD | writeregE == rtD)  |  memtoregM & (writeregM == rsD | writeregM == rtD) );
    assign jalrstallD = (jalrD & regwriteE & (writeregE==rsD)) | (jalrD & memtoregM & (writeregM==rsD));
    assign lwstallD = (((rsD == rtE) | (rtD == rtE)) & memtoregE);

    assign flushF = flush_except;
    assign flushD = flush_except;
    assign flushE = (lwstallD|flush_except| branchstallD);
	assign flushM = flush_except;
	assign flushW = flush_except | stallreq_from_mem ;

	//assign forwardaD = (rsD != 0) & (rsD == writeregM) & regwriteM;
	//assign forwardbD = (rtD != 0) & (rtD == writeregM) & regwriteM;
    assign forwardaD =	(rsD==0)? 2'b00:
						(rsD == writeregE & regwriteE)?2'b01:
						(rsD == writeregM & regwriteM)?2'b10:
						(rsD == writeregW & regwriteW)?2'b11:2'b00;
	assign forwardbD =	(rtD==0)?2'b00:
						(rtD == writeregE & regwriteE)?2'b01:
						(rtD == writeregM & regwriteM)?2'b10:
						(rtD == writeregW & regwriteW)?2'b11:2'b00;

    assign forwardcp0E = ((cp0weM)&(rdM == rdE)&(rdE != 0))?1:0;

    //异常处理地址bfc00380
    always @(*) begin
        if(excepttypeM != 32'b0) begin
            if(excepttypeM == 32'h0000000e) begin
                newpcM <= cp0_epcM;
            end
            else begin
                newpcM <= 32'hBFC00380;//10 jump200
            end
        end
    end
endmodule
