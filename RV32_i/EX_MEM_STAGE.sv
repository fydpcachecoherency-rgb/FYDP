module EX_MEM_STAGE(
    input logic clk,
    input logic rst,
    
    // alu
    input logic [3: 0] zero,
    input logic [31: 0] result,
    input logic branch_taken,
    
    output logic [3: 0] EX_MEM_zero,
    output logic [31: 0] EX_MEM_result,
    output logic EX_MEM_branch_taken,
    
    // register file
    input logic [4: 0] ID_EX_rs1,
    input logic [4: 0] ID_EX_rs2,
    input logic [4: 0] ID_EX_rd,
    input logic [31: 0] ID_EX_reg_out_1,
    input logic [31: 0] ID_EX_reg_out_2,
    
    output logic [4: 0] EX_MEM_rs1,
    output logic [4: 0] EX_MEM_rs2,
    output logic [4: 0] EX_MEM_rd,
    output logic [31: 0] EX_MEM_reg_out_1,
    output logic [31: 0] EX_MEM_reg_out_2,
    
    // control unit
    input logic ID_EX_reg_we,
    input logic ID_EX_mem_we,
    input logic ID_EX_mem_re,
    input logic ID_EX_mem_reg_w,
    input logic [1: 0] ID_EX_pc_sel,
    input logic ID_EX_jump,
    input logic ID_EX_branch,
    input logic [2: 0] ID_EX_func_3,
    
    output logic EX_MEM_reg_we,
    output logic EX_MEM_mem_we,
    output logic EX_MEM_mem_re,
    output logic EX_MEM_mem_reg_w,
    output logic [1: 0] EX_MEM_pc_sel,
    output logic EX_MEM_jump,
    output logic EX_MEM_branch,
    output logic [2: 0] EX_MEM_func_3,
    
    // prog cntr output
    input logic [31: 0] ID_EX_pc,
    
    output logic [31: 0] EX_MEM_pc,
    
    // immediate
    input logic [31: 0] ID_EX_imm,
    
    output logic [31: 0] EX_MEM_imm
);
    
    always_ff @(posedge clk or posedge rst) begin 
        if (rst) begin
            EX_MEM_reg_out_1     <= 0;
            EX_MEM_reg_out_2     <= 0;
            EX_MEM_rs1           <= 0;
            EX_MEM_rs2           <= 0;
            EX_MEM_rd            <= 0;
            EX_MEM_reg_we        <= 0;
            EX_MEM_mem_we        <= 0;
            EX_MEM_mem_re        <= 0;
            EX_MEM_mem_reg_w     <= 0;
            EX_MEM_pc_sel        <= 0;
            EX_MEM_jump          <= 0;
            EX_MEM_branch        <= 0;
            EX_MEM_func_3        <= 0;
            EX_MEM_zero          <= 0;
            EX_MEM_result        <= 0;
            EX_MEM_branch_taken  <= 0;
            EX_MEM_pc            <= 0;
            EX_MEM_imm           <= 0;
        end
        else begin
            // REGISTER FILE
            EX_MEM_reg_out_1     <= ID_EX_reg_out_1;
            EX_MEM_reg_out_2     <= ID_EX_reg_out_2;
            EX_MEM_rs1           <= ID_EX_rs1;
            EX_MEM_rs2           <= ID_EX_rs2;
            EX_MEM_rd            <= ID_EX_rd;
            
            // CONTROL UNIT
            EX_MEM_reg_we        <= ID_EX_reg_we;
            EX_MEM_mem_we        <= ID_EX_mem_we;
            EX_MEM_mem_re        <= ID_EX_mem_re;
            EX_MEM_mem_reg_w     <= ID_EX_mem_reg_w;
            EX_MEM_pc_sel        <= ID_EX_pc_sel;
            EX_MEM_jump          <= ID_EX_jump;
            EX_MEM_branch        <= ID_EX_branch;
            EX_MEM_func_3        <= ID_EX_func_3;
            
            // ALU
            EX_MEM_zero          <= zero;
            EX_MEM_result        <= result;
            EX_MEM_branch_taken  <= branch_taken;
            
            // PROGRAM COUNTER
            EX_MEM_pc            <= ID_EX_pc;
            
            // IMMEDIATE
            EX_MEM_imm           <= ID_EX_imm;
        end
    end
endmodule