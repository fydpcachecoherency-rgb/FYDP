package risc_v_pkg;

// RISC-V OPCODES//
  typedef enum logic [6:0] {
	R_TYPE = 7'h33,
	IA_TYPE = 7'h13,
	IL_TYPE = 7'h03,
	B_TYPE = 7'h63,
	S_TYPE = 7'h23,
	LUI = 7'h37,
	AUIPC = 7'h17,
	JAL = 7'h6f,
	JALR = 7'h67
  }opcode_p;
//ALU OPERATION SELECT//

  typedef enum logic [3:0] {
	ADD,
	SUB,
	SLL,
	SLT,
	SLTU,
	XOR,
	SRL,
	SRA,
	OR,
	AND,
	DEFAULT_alu_instr
  }alu_instr_p;

  typedef enum logic [1:0] {
        L_S_J_U_TYPE,
	BR_TYPE,
 	I_R_TYPE,
	DEFAULT_alu_op
} alu_op_p;
        

endpackage