import risc_v_pkg::*;
module ALU_Control(input alu_op_p alu_op, input logic [2: 0] func_3, input logic [6: 0] func_7,
output alu_instr_p alu_instr);
    always_comb begin
        case(alu_op)
            L_S_J_U_TYPE: alu_instr = ADD;
            BR_TYPE: begin
                alu_instr = SUB;
	    end
            I_R_TYPE: begin
                case(func_3)
                    3'b000: begin
                        if (func_7 == 7'b0100000)
                            alu_instr = SUB;        // sub
                        else
                            alu_instr = ADD;        // add
                    end
                    3'b001: alu_instr = SLL;        // sll
                    3'b010: alu_instr = SLT;        // slt
                    3'b011: alu_instr = SLTU;        // sltu
                    3'b100: alu_instr = XOR;        // xor
                    3'b101: begin
                        if(func_7 == 7'b0100000)
                            alu_instr = SRA;        // sra
                        else
                            alu_instr = SRL;        // srl
                    end      
                    3'b110: alu_instr = OR;        // or
                    3'b111: alu_instr = AND;        // and
                endcase
            end
            
            default: alu_instr = ADD;
        endcase
    end
endmodule
