import risc_v_pkg::*; 
module Control_Unit( input opcode_p opcode, input logic stall,input amo_op_p amo_op,
output logic amo_en, output logic reg_we, output logic mem_we, output logic mem_re, output logic mem_reg_w, output alu_op_p alu_op, output logic op_b_sel,
output logic [1: 0] op_a_sel, output logic [1: 0] pc_sel, output logic jump, output logic branch);
    
    always_comb begin
        if(stall) begin
            reg_we = 1'b0;
            mem_we = 1'b0;
            mem_re = 1'b0;
            mem_reg_w = 1'b0;
            alu_op = DEFAULT_alu_op;
            op_b_sel = 1'b0;
            op_a_sel = 2'b00;
            pc_sel = 2'b00;
            jump = 1'b0;
            branch = 1'b0;
	    amo_en = 1'b0;
        end
        else begin
            if(opcode == R_TYPE ) begin // R-type
                reg_we = 1'b1;
                mem_reg_w = 1'b0;
                mem_we = 1'b0;
                mem_re = 1'b0;
                alu_op = I_R_TYPE;
                op_b_sel = 1'b0;
                op_a_sel = 2'b00;
                pc_sel = 2'b00;
                jump = 1'b0;
                branch = 1'b0;
		amo_en =1'b0;
            end
            
            else if(opcode == IA_TYPE ) begin // I-type
                reg_we = 1'b1;
                mem_reg_w = 1'b0;
                mem_we = 1'b0;
                mem_re = 1'b0;
                alu_op = I_R_TYPE;
                op_b_sel = 1'b1;
                op_a_sel = 2'b00;
                pc_sel = 2'b00;
                jump = 1'b0;
                branch = 1'b0;
		amo_en =1'b0;
            end
            else if(opcode == S_TYPE) begin // store
                reg_we = 1'b0;
                mem_reg_w = 1'b0;
                mem_we = 1'b1;
                mem_re = 1'b0;
                alu_op = L_S_J_U_TYPE;
                op_a_sel = 2'b00;
                op_b_sel = 1'b1;
                pc_sel = 2'b00;
                jump = 1'b0;
                branch = 1'b0;
		amo_en =1'b0;
            end
            else if(opcode == IL_TYPE) begin // load
                reg_we = 1'b1;
                mem_reg_w = 1'b1;
                mem_we = 1'b0;
                mem_re = 1'b1;
                alu_op =L_S_J_U_TYPE;
                op_a_sel = 2'b00;
                op_b_sel = 1'b1;
                pc_sel = 2'b00;
                jump = 1'b0;
                branch = 1'b0;
		amo_en =1'b0;
            end
            else if(opcode == JAL) begin // Jal
                reg_we = 1'b1;
                mem_reg_w = 1'b0;
                mem_we = 1'b0;
                mem_re = 1'b0;
                alu_op = L_S_J_U_TYPE;
                op_b_sel = 1'b1;
                op_a_sel = 2'b00;
                pc_sel = 2'b01;
                jump = 1'b1;
                branch = 1'b0;
		amo_en =1'b0;
            end
            else if(opcode == JALR) begin // Jalr
                reg_we = 1'b1;
                mem_reg_w = 1'b0;
                mem_we = 1'b0;
                mem_re = 1'b0;
                alu_op = L_S_J_U_TYPE;
                op_b_sel = 1'b1;
                op_a_sel = 2'b00;
                pc_sel = 2'b10;
                jump = 1'b1;
                branch = 1'b0;
		amo_en =1'b0;
            end
            else if(opcode == B_TYPE) begin // Branch
                reg_we = 1'b0;
                mem_reg_w = 1'b0;
                mem_we = 1'b0;
                mem_re = 1'b0;
                alu_op = BR_TYPE;
                op_b_sel = 1'b0;
                op_a_sel = 2'b00;
                pc_sel = 2'b11;
                jump = 1'b1;
                branch = 1'b1;
		amo_en =1'b0;
            end
            else if(opcode == LUI) begin // lui
                reg_we = 1'b1;
                mem_reg_w = 1'b0;
                mem_we = 1'b0;
                mem_re = 1'b0;
                alu_op = L_S_J_U_TYPE;
                op_b_sel = 1'b1;
                op_a_sel = 2'b11;
                pc_sel = 2'b00;
                jump = 1'b0;
                branch = 1'b0;
		amo_en =1'b0;
            end
            else if(opcode == AUIPC) begin // auipc
                reg_we = 1'b1;
                mem_reg_w = 1'b0;
                mem_we = 1'b0;
                mem_re = 1'b0;
                alu_op = L_S_J_U_TYPE;
                op_b_sel = 1'b1;
                op_a_sel = 2'b01;
                pc_sel = 2'b00;
                jump = 1'b0;
                branch = 1'b0;
		amo_en =1'b0;
            end
            else if(opcode == AMO) begin // amo
                reg_we = 1'b1;
                mem_reg_w = 1'b1;
                mem_we = 1'b0;
                mem_re = (amo_op == AMO_SC)? 1'b0 : 1'b1;
                alu_op = L_S_J_U_TYPE;
                op_b_sel = 1'b1;
                op_a_sel = 2'b00;
                pc_sel = 2'b00;
                jump = 1'b0;
                branch = 1'b0;
		amo_en = 1'b1;
	    end
            else begin
                reg_we = 1'b0;
                mem_reg_w = 1'b0;
                mem_we = 1'b0;
                mem_re = 1'b0;
                alu_op = DEFAULT_alu_op;
                op_b_sel = 1'b0;
                op_a_sel = 2'b00;
                pc_sel = 2'b00;
                jump = 1'b0;
                branch = 1'b0;
		amo_en =1'b0;
            end
        end
    end
    
endmodule
