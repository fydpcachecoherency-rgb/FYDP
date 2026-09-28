import risc_v_pkg::*;
module ALU_Control(input alu_op_p alu_op, input logic [2:0] func_3, input logic [6:0] func_7,
    input opcode_p opcode,                 
    output alu_instr_p alu_instr);

    logic is_rtype;
    assign is_rtype = (opcode == R_TYPE);

    always_comb begin
        case(alu_op)
            L_S_J_U_TYPE: alu_instr = ADD;
            BR_TYPE: alu_instr = SUB;
            I_R_TYPE: begin
                case(func_3)
                    3'b000: alu_instr = (is_rtype && func_7==7'b0100000) ? SUB   :
                                        (is_rtype && func_7==7'b0000001) ? MUL   : ADD;
                    3'b001: alu_instr = (is_rtype && func_7==7'b0000001) ? MULH   : SLL;
                    3'b010: alu_instr = (is_rtype && func_7==7'b0000001) ? MULHSU : SLT;
                    3'b011: alu_instr = (is_rtype && func_7==7'b0000001) ? MULHU  : SLTU;
                    3'b100: alu_instr = XOR;
                    3'b101: alu_instr = (func_7==7'b0100000) ? SRA : SRL; // leave unconditional: SRAI/SRLI legitimately use imm[11:5]
                    3'b110: alu_instr = OR;
                    3'b111: alu_instr = AND;
                endcase
            end
            default: alu_instr = ADD;
        endcase
    end
endmodule
