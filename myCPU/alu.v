`timescale 1ns / 1ps
`include "defines.vh"
module alu(
	input wire[31:0] a,b,
	input wire[4:0] sa, // imm add a sa signal in datapath
	input wire [63:0] hilo_in, // add signal
	input wire [31:0] cp0_in, // add signal
	input wire[7:0] alucontrol,
	output reg[31:0] y,
	output reg[63:0] hilo_out, // add signal
	output reg[31:0] cp0_out, // add signal
	output reg overflow,
	output wire zero
    );

	wire[31:0] s,bout;
	// assign bout = op[2] ? ~b : b;
	// assign s = a + bout + op[2];
	always @(*) begin
		case (alucontrol)
			`EXE_AND_OP:   y <= a & b;
			`EXE_ANDI_OP:  y <= a & b;
			`EXE_OR_OP:    y <= a | b;
			`EXE_ORI_OP:   y <= a | b;
			`EXE_XOR_OP:   y <= a ^ b;
			`EXE_XORI_OP:  y <= a ^ b;
			`EXE_NOR_OP:   y <= ~(a | b); // 打成感叹号了
			`EXE_LUI_OP:   y <= {b[15:0], 16'b0};
			
			`EXE_ADD_OP:   y <= a + b;
			`EXE_ADDU_OP:  y <= a + b;
			`EXE_ADDI_OP:  y <= a + b;
			`EXE_ADDIU_OP: y <= a + b;
			`EXE_SUB_OP:   y <= a - b;
			`EXE_SUBU_OP:  y <= a - b;
			`EXE_SLT_OP:   y <= ($signed(a) < $signed(b));
			`EXE_SLTI_OP:  y <= ($signed(a) < $signed(b));
			`EXE_SLTU_OP:  y <= (a < b);
			`EXE_SLTIU_OP: y <= (a < b);
			`EXE_SLL_OP:   y <= b << sa;
			`EXE_SLLV_OP:  y <= b << a[4:0]; 
			`EXE_SRL_OP:   y <= b >> sa;
			`EXE_SRLV_OP:  y <= b >> a[4:0];
			`EXE_SRA_OP:   y <= $signed(b) >>> sa;
			`EXE_SRAV_OP:  y <= $signed(b) >>> a[4:0];
			`EXE_MULT_OP:  hilo_out <= $signed(a) * $signed(b);
			`EXE_MULTU_OP: hilo_out <= a * b;
			`EXE_MFHI_OP:  y <= hilo_in[63:32];
			`EXE_MTHI_OP:  hilo_out <= {a, hilo_in[31:0]};
			`EXE_MFLO_OP:  y <= hilo_in[31:0];
			`EXE_MTLO_OP:  hilo_out <= {hilo_in[63:32], a};
			`EXE_MFC0_OP:  y <= cp0_in;
			`EXE_MTC0_OP:  cp0_out <= b;
			//op==`EXE_SB_OP|op==`EXE_SH_OP|op==`EXE_SW_OP)
			`EXE_LW_OP:    y <= a+b;
			`EXE_LB_OP:    y <= a+b;
			`EXE_LBU_OP:   y <= a+b;
			`EXE_LH_OP:    y <= a+b;
			`EXE_LHU_OP:   y <= a+b;
			`EXE_SB_OP:    y <= a+b;
			`EXE_SH_OP:    y <= a+b;
			`EXE_SW_OP:    y <= a+b;
			default : begin
				y <= 32'b0;
				cp0_out <= 32'b0;
			end
		endcase	
	end
	assign zero = (y == 32'b0);

	always @(*) begin
		case (alucontrol)
			`EXE_ADD_OP:overflow <= a[31] & b[31] & ~y[31] |
							~a[31] & ~b[31] & y[31];
			`EXE_ADDI_OP:overflow <= a[31] & b[31] & ~y[31] |
							~a[31] & ~b[31] & y[31];
			`EXE_SUB_OP:overflow <= ~a[31] & b[31] & y[31] |
							a[31] & ~b[31] & ~y[31];
			default : overflow <= 0;
		endcase	
	end
endmodule
