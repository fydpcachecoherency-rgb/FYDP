import risc_v_pkg::*;

module MEM_WB_STAGE(
    input logic clk,
    input logic rst,
    input amo_op_p EX_MEM_amo_op,
    input logic EX_MEM_aq,
    input logic EX_MEM_rl,
    input logic [31:0] atomic_wb_data,
    
    // control unit
    input logic EX_MEM_reg_we,
    input logic EX_MEM_mem_reg_w,
    input logic EX_MEM_jump,
    input logic [31:0] EX_MEM_instr,
    input logic EX_MEM_valid,
    input logic EX_MEM_amo_en,

    output logic MEM_WB_amo_en,
    output logic MEM_WB_reg_we,
    output logic MEM_WB_mem_reg_w,
    output logic MEM_WB_jump,
    
    // register file
    input logic [4: 0] EX_MEM_rs1,
    input logic [4: 0] EX_MEM_rs2,
    input logic [4: 0] EX_MEM_rd,
    input logic [31: 0] EX_MEM_reg_out_1,
    
    output logic [4: 0] MEM_WB_rs1,
    output logic [4: 0] MEM_WB_rs2,
    output logic [4: 0] MEM_WB_rd,
    output logic [31: 0] MEM_WB_reg_out_1,
    
    // alu
    input logic [31: 0] EX_MEM_result,
    
    output logic [31: 0] MEM_WB_result,
    
    // data memory
    input logic [31: 0] d_mem_d_out,
    
    output logic [31: 0] MEM_WB_d_mem_d_out,
    
    // prog cntr output
    input logic [31: 0] EX_MEM_pc,
    
    output logic [31: 0] MEM_WB_pc,
    
    // immediate
    input logic [31: 0] EX_MEM_imm,
    
    output logic [31: 0] MEM_WB_imm,
    output logic [31:0] MEM_WB_instr,
    output logic MEM_WB_valid,
    output amo_op_p MEM_WB_amo_op,
    output logic MEM_WB_aq,
    output logic MEM_WB_rl,
    output logic [31: 0] MEM_WB_atomic_wb_data
    
);
    
    always_ff @(posedge clk or posedge rst) begin 
        if (rst) begin
            MEM_WB_rs1          <= 0;
            MEM_WB_rs2          <= 0;
            MEM_WB_rd           <= 0;
            MEM_WB_reg_out_1    <= 0;
            MEM_WB_reg_we       <= 0;
            MEM_WB_mem_reg_w    <= 0;
            MEM_WB_jump         <= 0;
            MEM_WB_result       <= 0;
            MEM_WB_d_mem_d_out  <= 0;
            MEM_WB_pc           <= 0;
            MEM_WB_imm          <= 0;
	    MEM_WB_instr        <= 0;
	    MEM_WB_valid        <= 0;
	    MEM_WB_amo_op        <= amo_op_p'(0);
	    MEM_WB_aq            <= 0;
	    MEM_WB_rl            <= 0;
	    MEM_WB_amo_en        <= 0;
	    MEM_WB_atomic_wb_data <= 0;
        end
        else begin
            // REGISTER FILE
            MEM_WB_rs1          <= EX_MEM_rs1;
            MEM_WB_rs2          <= EX_MEM_rs2;
            MEM_WB_rd           <= EX_MEM_rd;
            MEM_WB_reg_out_1    <= EX_MEM_reg_out_1;
            
            // CONTROL UNIT
            MEM_WB_reg_we       <= EX_MEM_reg_we;
            MEM_WB_mem_reg_w    <= EX_MEM_mem_reg_w;
            MEM_WB_jump         <= EX_MEM_jump;
            
            // ALU
            MEM_WB_result       <= EX_MEM_result;
            
            // DATA MEMORY
            MEM_WB_d_mem_d_out  <= d_mem_d_out;
            
            // PROGRAM COUNTER
            MEM_WB_pc           <= EX_MEM_pc;
            
            // IMMEDIATE
            MEM_WB_imm          <= EX_MEM_imm;
	    MEM_WB_instr        <= EX_MEM_instr;
            MEM_WB_valid        <= EX_MEM_valid;
	    MEM_WB_amo_op       <= EX_MEM_amo_op;
	    MEM_WB_aq           <= EX_MEM_aq;
	    MEM_WB_rl           <= EX_MEM_rl;
	    MEM_WB_amo_en       <= EX_MEM_amo_en;
	    MEM_WB_atomic_wb_data <= atomic_wb_data;
        end
    end
endmodule
