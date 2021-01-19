`timescale 1ns / 1ps
`include "defines.vh"
module maindec(
	input wire stallD,
	input wire[31:0] instr,
	output wire memtoreg,memen,memwrite,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,jal,jr,bal,jalr,
	output wire hilo_we,
	output wire div_valid,
	output wire signed_div,
	output reg invalid,
	output wire cp0we
    );
	wire [5:0] op,func;
	wire [4:0] rs,rt,rd;
	reg[12:0] controls;
	assign op=instr[31:26];
	assign rs=instr[25:21];
	assign rt=instr[20:16];
	assign rd=instr[15:11];
	assign func=instr[5:0];
	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,jal,jr,bal,jalr,hilo_we,memen} = controls;
	assign div_valid =( (op == `EXE_SPECIAL_INST&&func==`EXE_DIV)||(op==`EXE_SPECIAL_INST&&func==`EXE_DIVU))&&~stallD;
	assign signed_div = (op==`EXE_SPECIAL_INST&&func==`EXE_DIV)&&~stallD;
	assign cp0we = ((op==`EXE_SPECIAL3_INST)&(rs==`EXE_MTC0))?1:0; // always？
	//op觉得控制信号
	always @(*) begin
		invalid <= 0;
		if (stallD) begin
			controls <= 13'b0000000000000;
		end
		if (~stallD) begin
			controls <= 13'b0000000000000;
			case (op)
				`EXE_SPECIAL_INST: begin
					case(func)
							`EXE_AND:     controls <= 13'b1100000000000;
							`EXE_OR:      controls <= 13'b1100000000000;
							`EXE_XOR:     controls <= 13'b1100000000000;
							`EXE_NOR:     controls <= 13'b1100000000000;
							`EXE_SLL:     controls <= 13'b1100000000000;
							`EXE_SLLV:    controls <= 13'b1100000000000;
							`EXE_SRLV:    controls <= 13'b1100000000000;
							`EXE_SRL:     controls <= 13'b1100000000000;
							`EXE_SRA:     controls <= 13'b1100000000000;
							`EXE_SRAV:    controls <= 13'b1100000000000;
							`EXE_MFHI:    controls <= 13'b1100000000000;
							`EXE_MFLO:    controls <= 13'b1100000000000;
							`EXE_MTHI:    controls <= 13'b0000000000010;
							`EXE_MTLO:    controls <= 13'b0000000000010;
							`EXE_ADD:     controls <= 13'b1100000000000;
							`EXE_ADDU:    controls <= 13'b1100000000000;
					 		`EXE_SUB:     controls <= 13'b1100000000000;
							`EXE_SUBU:    controls <= 13'b1100000000000;
							`EXE_SLT:     controls <= 13'b1100000000000;
							`EXE_SLTU:    controls <= 13'b1100000000000;
							`EXE_MULT:    controls <= 13'b0000000000010;
							`EXE_MULTU:   controls <= 13'b0000000000010;
							`EXE_DIV:     controls <= 13'b0000000000010;
							`EXE_DIVU:    controls <= 13'b0000000000010;
							`EXE_JR:      controls <= 13'b0000000010000;
							`EXE_JALR:    controls <= 13'b1100000000100;
							`EXE_BREAK:   controls <= 13'b0000000000000;
							`EXE_SYSCALL: controls <= 13'b0000000000000;
							default:      invalid <= 1;//异常指令controls <= 13'b0000000000000;
						endcase
				end
				`EXE_REGIMM_INST: begin
					case(rt)
						`EXE_BGEZ:   controls <= 13'b0001000000000;
						`EXE_BGEZAL: controls <= 13'b1001000001000; 
						`EXE_BLTZ:   controls <= 13'b0001000000000;//修改了bal
						`EXE_BLTZAL: controls <= 13'b1001000001000;
						default:     invalid <= 1;//controls <= 13'b0000000000000;
					endcase
				end
				// I_TYPE指令
				`EXE_ANDI:  controls <= 13'b1010000000000;
				`EXE_XORI:  controls <= 13'b1010000000000;
				`EXE_LUI:   controls <= 13'b1010000000000;
				`EXE_ORI:   controls <= 13'b1010000000000;
				`EXE_ADDI:  controls <= 13'b1010000000000;
				`EXE_ADDIU: controls <= 13'b1010000000000;
				`EXE_SLTI:  controls <= 13'b1010000000000;
				`EXE_SLTIU: controls <= 13'b1010000000000;
				`EXE_BEQ:   controls <= 13'b0001000000000;
				`EXE_BGTZ:  controls <= 13'b0001000000000;
				`EXE_BLEZ:  controls <= 13'b0001000000000;
				`EXE_BNE:   controls <= 13'b0001000000000;
				// BGEZ更改判断逻辑


				`EXE_LB:  controls <= 13'b1010010000001;
				`EXE_LBU: controls <= 13'b1010010000001;
				`EXE_LH:  controls <= 13'b1010010000001;
				`EXE_LHU: controls <= 13'b1010010000001;
				`EXE_LW:  controls <= 13'b1010010000001;
				`EXE_SB:  controls <= 13'b0010100000001;
				`EXE_SH:  controls <= 13'b0010100000001;
				`EXE_SW:  controls <= 13'b0010100000001;
				//J_TYPE指令
				`EXE_J:   controls <= 13'b0000001000000;
				`EXE_JAL: controls <= 13'b1000000100000;

				//mfc0和mtc0
				`EXE_SPECIAL3_INST: begin
					case(rs)
						`EXE_MTC0: controls <= 13'b0000000000000;
						`EXE_MFC0: controls <= 13'b1000000000000;		//要往寄存器里面写东西
						default: invalid <= 1;
					endcase
				end
				default:  invalid <= 1;//controls <= 13'b0000000000000;
			endcase
		end
	end
endmodule
