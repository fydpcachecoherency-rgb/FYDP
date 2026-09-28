import risc_v_pkg::*;

module IF_ID_STAGE(
    input logic clk,
    input logic rst,
    input logic stall,
    input logic flush,
    
    // instr mem
    input logic [31: 0] instr,
    
    output opcode_p IF_ID_opcode,     
    output logic [4: 0] IF_ID_rs1,
    output logic [4: 0] IF_ID_rs2,
    output logic [4: 0] IF_ID_rd,
    output logic [2: 0] IF_ID_func_3,
    output logic [6: 0] IF_ID_func_7,
    output logic [31: 0] IF_ID_instr,
    output amo_op_p IF_ID_amo_op,
    output logic IF_ID_aq,
    output logic IF_ID_rl,
    
    // prog cntr
    input logic [31: 0] pc,
    
    output logic [31: 0] IF_ID_pc,
    output logic IF_ID_valid
);
        
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            IF_ID_opcode  <= opcode_p'(0);
            IF_ID_rs1     <= 0;
            IF_ID_rs2     <= 0;
            IF_ID_rd      <= 0;
            IF_ID_func_3  <= 0;
            IF_ID_func_7  <= 0;
            IF_ID_instr   <= 0;
            IF_ID_pc      <= 0;
	    IF_ID_valid   <=0;
	    IF_ID_amo_op  <= amo_op_p'(0);
	    IF_ID_aq      <= 0;
	    IF_ID_rl      <= 0;
        end
        else if (stall) begin
             IF_ID_opcode  <= IF_ID_opcode;
             IF_ID_rs1     <= IF_ID_rs1;
             IF_ID_rs2     <= IF_ID_rs2;
             IF_ID_rd      <= IF_ID_rd;
             IF_ID_func_3  <= IF_ID_func_3;
             IF_ID_func_7  <= IF_ID_func_7;
             IF_ID_instr   <= IF_ID_instr;
             IF_ID_pc      <= IF_ID_pc;
	     IF_ID_valid   <= IF_ID_valid;
	     IF_ID_amo_op  <= IF_ID_amo_op;
	     IF_ID_aq      <= IF_ID_aq;
	     IF_ID_rl      <= IF_ID_rl;	
        end
        else if (flush) begin
             IF_ID_opcode  <= opcode_p'(0);
             IF_ID_rs1     <= 0;
             IF_ID_rs2     <= 0;
             IF_ID_rd      <= 0;
             IF_ID_func_3  <= 0;
             IF_ID_func_7  <= 0;
             IF_ID_instr   <= 0;
             IF_ID_pc      <= 0;
             IF_ID_valid   <= 0;
	     IF_ID_amo_op  <= amo_op_p'(0);
	     IF_ID_aq      <= 0;
	     IF_ID_rl      <= 0;
        end
        else begin
             IF_ID_opcode  <= opcode_p'(instr[6: 0]); // FIXED: Explicit cast
             IF_ID_rs1     <= instr[19: 15];
             IF_ID_rs2     <= instr[24: 20];
             IF_ID_rd      <= instr[11: 7];
             IF_ID_func_3  <= instr[14: 12];
             IF_ID_func_7  <= instr[31: 25];
             IF_ID_instr   <= instr;
             IF_ID_pc      <= pc;
             IF_ID_valid   <= 1'b1;
	     IF_ID_amo_op  <= amo_op_p'(instr[31:27]);
	     IF_ID_aq      <= instr[26];
	     IF_ID_rl      <= instr[25];
        end
    end
endmodule
