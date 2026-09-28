import risc_v_pkg::*;

module ID_EX_STAGE(
    input logic clk,
    input logic rst,
    input logic stall,
    input logic flush,
    
    input opcode_p IF_ID_opcode,
    
    output opcode_p ID_EX_opcode,
    
    // register file
    input logic [31: 0] reg_out_1,
    input logic [31: 0] reg_out_2,
    input logic [4: 0] IF_ID_rs1,
    input logic [4: 0] IF_ID_rs2,
    input logic [4: 0] IF_ID_rd,
    
    output logic [31: 0] ID_EX_reg_out_1,
    output logic [31: 0] ID_EX_reg_out_2,
    output logic [4: 0] ID_EX_rs1,
    output logic [4: 0] ID_EX_rs2,
    output logic [4: 0] ID_EX_rd,
    
    // immediate
    input logic [31: 0] imm,
    
    output logic [31: 0] ID_EX_imm,
    
    // control unit
    input logic reg_we,
    input logic mem_we,
    input logic mem_re,
    input logic mem_reg_w,
    input alu_op_p alu_op,             
    input logic op_b_sel,
    input logic [1: 0] op_a_sel,
    input logic [1: 0] pc_sel,
    input logic jump,
    input logic branch,
    
    output logic ID_EX_reg_we,
    output logic ID_EX_mem_we,
    output logic ID_EX_mem_re,
    output logic ID_EX_mem_reg_w,
    output alu_op_p ID_EX_alu_op,      
    output logic ID_EX_op_b_sel,
    output logic [1: 0] ID_EX_op_a_sel,
    output logic [1: 0] ID_EX_pc_sel,
    output logic ID_EX_jump,
    output logic ID_EX_branch,
    
    // alu
    input logic [2: 0] IF_ID_func_3,
    input logic [6: 0] IF_ID_func_7,
    
    output logic [2: 0] ID_EX_func_3,
    output logic [6: 0] ID_EX_func_7,
    
    // prog cntr output
    input logic [31: 0] IF_ID_pc,
    
    output logic [31: 0] ID_EX_pc
);
    
    always_ff @(posedge clk or posedge rst) begin 
        if (rst) begin
            ID_EX_opcode    <= opcode_p'(0);
            ID_EX_reg_out_1 <= 0;
            ID_EX_reg_out_2 <= 0;
            ID_EX_rs1       <= 0;
            ID_EX_rs2       <= 0;
            ID_EX_rd        <= 0;
            ID_EX_imm       <= 0;
            ID_EX_reg_we    <= 0;
            ID_EX_mem_we    <= 0;
            ID_EX_mem_re    <= 0;
            ID_EX_mem_reg_w <= 0;
            ID_EX_alu_op    <= DEFAULT_alu_op;
            ID_EX_op_b_sel  <= 0;
            ID_EX_op_a_sel  <= 0;
            ID_EX_pc_sel    <= 0;
            ID_EX_jump      <= 0;
            ID_EX_branch    <= 0;
            ID_EX_func_3    <= 0;
            ID_EX_func_7    <= 0;
            ID_EX_pc        <= 0;
        end
        else begin
            if (stall) begin
                ID_EX_opcode    <= ID_EX_opcode;
                ID_EX_reg_out_1 <= ID_EX_reg_out_1;
                ID_EX_reg_out_2 <= ID_EX_reg_out_2;
                ID_EX_rs1       <= ID_EX_rs1;
                ID_EX_rs2       <= ID_EX_rs2;
                ID_EX_rd        <= ID_EX_rd;
                ID_EX_imm       <= ID_EX_imm;
                ID_EX_reg_we    <= ID_EX_reg_we;
                ID_EX_mem_we    <= ID_EX_mem_we;
                ID_EX_mem_re    <= ID_EX_mem_re;
                ID_EX_mem_reg_w <= ID_EX_mem_reg_w;
                ID_EX_alu_op    <= ID_EX_alu_op;
                ID_EX_op_b_sel  <= ID_EX_op_b_sel;
                ID_EX_op_a_sel  <= ID_EX_op_a_sel;
                ID_EX_pc_sel    <= ID_EX_pc_sel;
                ID_EX_jump      <= ID_EX_jump;
                ID_EX_branch    <= ID_EX_branch;
                ID_EX_func_3    <= ID_EX_func_3;
                ID_EX_func_7    <= ID_EX_func_7;
                ID_EX_pc        <= ID_EX_pc;
            end
            else if (flush) begin
                ID_EX_opcode    <= opcode_p'(0);
                ID_EX_reg_out_1 <= 0;
                ID_EX_reg_out_2 <= 0;
                ID_EX_rs1       <= 0;
                ID_EX_rs2       <= 0;
                ID_EX_rd        <= 0;
                ID_EX_imm       <= 0;
                ID_EX_reg_we    <= 0;
                ID_EX_mem_we    <= 0;
                ID_EX_mem_re    <= 0;
                ID_EX_mem_reg_w <= 0;
                ID_EX_alu_op    <= DEFAULT_alu_op;
                ID_EX_op_b_sel  <= 0;
                ID_EX_op_a_sel  <= 0;
                ID_EX_pc_sel    <= 0;
                ID_EX_jump      <= 0;
                ID_EX_branch    <= 0;
                ID_EX_func_3    <= 0;
                ID_EX_func_7    <= 0;
                ID_EX_pc        <= 0;
            end
            else begin
                ID_EX_opcode    <= IF_ID_opcode;
                ID_EX_reg_out_1 <= reg_out_1;
                ID_EX_reg_out_2 <= reg_out_2;
                ID_EX_rs1       <= IF_ID_rs1;
                ID_EX_rs2       <= IF_ID_rs2;
                ID_EX_rd        <= IF_ID_rd;
                ID_EX_imm       <= imm;
                ID_EX_reg_we    <= reg_we;
                ID_EX_mem_we    <= mem_we;
                ID_EX_mem_re    <= mem_re;
                ID_EX_mem_reg_w <= mem_reg_w;
                ID_EX_alu_op    <= alu_op;
                ID_EX_op_b_sel  <= op_b_sel;
                ID_EX_op_a_sel  <= op_a_sel;
                ID_EX_pc_sel    <= pc_sel;
                ID_EX_jump      <= jump;
                ID_EX_branch    <= branch;
                ID_EX_func_3    <= IF_ID_func_3;
                ID_EX_func_7    <= IF_ID_func_7;
                ID_EX_pc        <= IF_ID_pc;
            end
        end
    end
endmodule