`timescale 1ns / 1ps
`include "defines.vh"
module aludec(
	input wire [31:0] instr,
	input wire stallD,
	output reg[7:0] alucontrol
	//output reg invalid
    );
	wire [5:0]aluop;
	wire [5:0]funct;
	assign aluop = instr[31:26];
	assign funct = instr[5:0];
	always @(*) begin
		if(!stallD) begin
			case (aluop)
				`EXE_SPECIAL_INST:begin
					case (funct)
						`EXE_AND:  alucontrol <= `EXE_AND_OP;
						`EXE_OR:   alucontrol <= `EXE_OR_OP;
						`EXE_XOR:  alucontrol <= `EXE_XOR_OP;
						`EXE_NOR:  alucontrol <= `EXE_NOR_OP;
						`EXE_ADD:  alucontrol <= `EXE_ADD_OP;
						`EXE_ADDU: alucontrol <= `EXE_ADDU_OP;
						`EXE_SUB:  alucontrol <= `EXE_SUB_OP;
						`EXE_SUBU: alucontrol <= `EXE_SUBU_OP;
						`EXE_SLT:  alucontrol <= `EXE_SLT_OP;
						`EXE_SLTU: alucontrol <= `EXE_SLTU_OP;
						// 移位指令
						`EXE_SLL:  alucontrol <= `EXE_SLL_OP;
						`EXE_SLLV: alucontrol <= `EXE_SLLV_OP;
						`EXE_SRL:  alucontrol <= `EXE_SRL_OP;
						`EXE_SRLV: alucontrol <= `EXE_SRLV_OP;
						`EXE_SRA:  alucontrol <= `EXE_SRA_OP;
						`EXE_SRAV: alucontrol <= `EXE_SRAV_OP;
						// 乘除法
						`EXE_MULT:  alucontrol <= `EXE_MULT_OP;
						`EXE_MULTU: alucontrol <= `EXE_MULTU_OP;
						`EXE_DIV:   alucontrol <= `EXE_DIV_OP;
						`EXE_DIVU:  alucontrol <= `EXE_DIVU_OP;
						// 数据移动
						`EXE_MFHI: alucontrol <= `EXE_MFHI_OP;
						`EXE_MTHI: alucontrol <= `EXE_MTHI_OP;
						`EXE_MFLO: alucontrol <= `EXE_MFLO_OP;
						`EXE_MTLO: alucontrol <= `EXE_MTLO_OP;
						// 跳转
						`EXE_JR:   alucontrol <= `EXE_JR_OP;
						`EXE_JALR: alucontrol <= `EXE_JALR_OP;
						// 内陷指令
						`EXE_SYSCALL: alucontrol <= `EXE_SYSCALL_OP;
						`EXE_BREAK:   alucontrol <= `EXE_BREAK_OP;
						default: 
							alucontrol <= `EXE_NOP_OP;
					endcase
				end
				`EXE_REGIMM_INST: begin
					case (instr[20:16])
						`EXE_BGEZ:   alucontrol <= `EXE_BGEZ_OP;
						`EXE_BGEZAL: alucontrol <= `EXE_BGEZAL_OP;
						`EXE_BLTZ:   alucontrol <= `EXE_BLTZ_OP;
						`EXE_BLTZAL: alucontrol <= `EXE_BLTZAL_OP;
						default: 
							alucontrol <= `EXE_NOP_OP;
					endcase
				end
				// `EXE_NOP:  alucontrol <= `EXE_NOP_OP;
				// 逻辑
				`EXE_ANDI: alucontrol <= `EXE_ANDI_OP;
				`EXE_ORI:  alucontrol <= `EXE_ORI_OP;
				`EXE_XORI: alucontrol <= `EXE_XORI_OP;
				`EXE_LUI:  alucontrol <= `EXE_LUI_OP;
				// 运算
				`EXE_ADDI:  alucontrol <= `EXE_ADDI_OP;
				`EXE_ADDIU: alucontrol <= `EXE_ADDIU_OP;
				`EXE_SLTI:  alucontrol <= `EXE_SLTI_OP;
				`EXE_SLTIU: alucontrol <= `EXE_SLTIU_OP;
				// 分支跳转
				`EXE_J:    alucontrol <= `EXE_J_OP;
				`EXE_JAL:  alucontrol <= `EXE_JAL_OP;
				`EXE_BEQ:  alucontrol <= `EXE_BEQ_OP;
				`EXE_BGTZ: alucontrol <= `EXE_BGTZ_OP;
				`EXE_BLEZ: alucontrol <= `EXE_BLEZ_OP;
				`EXE_BNE:  alucontrol <= `EXE_BNE_OP;
				// 访存
				`EXE_LB:  alucontrol <= `EXE_LB_OP;
				`EXE_LBU: alucontrol <= `EXE_LBU_OP;
				`EXE_LH:  alucontrol <= `EXE_LH_OP;
				`EXE_LHU: alucontrol <= `EXE_LHU_OP;
				`EXE_LW:  alucontrol <= `EXE_LW_OP;
				`EXE_SB:  alucontrol <= `EXE_SB_OP;
				`EXE_SH:  alucontrol <= `EXE_SH_OP;
				`EXE_SW:  alucontrol <= `EXE_SW_OP;
				// 特权指令
				`EXE_SPECIAL3_INST: begin
					case(instr[25:21])
						5'b00100: alucontrol <= `EXE_MTC0_OP;
						5'b00000: alucontrol <= `EXE_MFC0_OP;
						5'b10000: alucontrol <= `EXE_ERET_OP;
						default:
							alucontrol <= `EXE_NOP_OP;
					endcase
				end
				default:
					alucontrol <= `EXE_NOP_OP;
			endcase
		end
		else begin
			alucontrol <= `EXE_NOP_OP;
		end
	end
endmodule
