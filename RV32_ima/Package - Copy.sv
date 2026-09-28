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
	JALR = 7'h67,
	AMO  = 7'h2f
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
	MUL,
	MULH,
	MULHSU,
	MULHU,
	DEFAULT_alu_instr
  }alu_instr_p;

  typedef enum logic [4:0] {
    AMO_ADD  = 5'b00000,
    AMO_SWAP = 5'b00001,
    AMO_LR   = 5'b00010,
    AMO_SC   = 5'b00011,
    AMO_XOR  = 5'b00100,
    AMO_OR   = 5'b01000,
    AMO_AND  = 5'b01100,
    AMO_MIN  = 5'b10000,
    AMO_MAX  = 5'b10100,
    AMO_MINU = 5'b11000,
    AMO_MAXU = 5'b11100
} amo_op_p;

  typedef enum logic [2:0] {
        L_S_J_U_TYPE,
	BR_TYPE,
 	I_R_TYPE,
	AMO_TYPE,
	DEFAULT_alu_op
} alu_op_p;
        

endpackage