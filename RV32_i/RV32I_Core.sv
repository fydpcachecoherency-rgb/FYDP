import risc_v_pkg::*;

module RV32I_Core(
    input logic clk,
    input logic rst
);

    // Prog Cntr signals
    logic [31: 0] pc;
    logic [31: 0] next_pc;
    
    // Instr Mem signals
    logic [31: 0] instr;
    
    // Data Mem signals
    logic [31: 0] d_mem_d_out;
    
    // Control Unit signals
    logic reg_we;
    logic mem_we;
    logic mem_re;
    logic mem_reg_w;
    logic op_b_sel;
    logic [1: 0] op_a_sel;
    alu_op_p alu_op;
    logic [1: 0] pc_sel;
    logic jump;
    logic branch;
    
    // regfile signals
    logic [4: 0] rs1;
    logic [4: 0] rs2;
    logic [4: 0] rd;
    logic [31: 0] reg_out_1;
    logic [31: 0] reg_out_2;
    logic [31: 0] wb_data;
    logic write_en;
    
    // Immediate signal
    logic [31: 0] imm;
    
    // ALU signals
    logic [31: 0] op_a;
    logic [31: 0] op_b;
    logic [31: 0] alu_out;
    logic branch_taken;
    alu_instr_p alu_instr;
    logic [3: 0] zero;
    logic n, z, c, v;
    
//=====================================================================
    // IF_ID_stage
//=====================================================================

    opcode_p IF_ID_opcode;
    logic [4: 0] IF_ID_rs1;
    logic [4: 0] IF_ID_rs2;
    logic [4: 0] IF_ID_rd;
    logic [2: 0] IF_ID_func_3;
    logic [6: 0] IF_ID_func_7;
    logic [31: 0] IF_ID_instr;
    logic [31: 0] IF_ID_pc;
    
//=====================================================================
    // ID_EX_stage
//=====================================================================

    opcode_p ID_EX_opcode;
    
    // register file
    logic [31: 0] ID_EX_reg_out_1;
    logic [31: 0] ID_EX_reg_out_2;
    logic [4: 0] ID_EX_rs1;
    logic [4: 0] ID_EX_rs2;
    logic [4: 0] ID_EX_rd;
    
    // immediate
    logic [31: 0] ID_EX_imm;
    
    // control unit
    logic ID_EX_reg_we;
    logic ID_EX_mem_we;
    logic ID_EX_mem_re;
    logic ID_EX_mem_reg_w;
    alu_op_p ID_EX_alu_op;
    logic ID_EX_op_b_sel;
    logic [1: 0] ID_EX_op_a_sel;
    logic [1: 0] ID_EX_pc_sel;
    logic ID_EX_jump;
    logic ID_EX_branch;
    
    // alu
    logic [2: 0] ID_EX_func_3;
    logic [6: 0] ID_EX_func_7;
    
    // prog cntr output
    logic [31: 0] ID_EX_pc;

//=====================================================================
    // EX_MEM_stage
//=====================================================================
    
    // alu
    logic [3: 0] EX_MEM_zero;
    logic [31: 0] EX_MEM_result;
    logic EX_MEM_branch_taken;
    
    // register file
    logic [4: 0] EX_MEM_rs1;
    logic [4: 0] EX_MEM_rs2;
    logic [4: 0] EX_MEM_rd;
    logic [31: 0] EX_MEM_reg_out_1;
    logic [31: 0] EX_MEM_reg_out_2;
    
    // control unit
    logic EX_MEM_reg_we;
    logic EX_MEM_mem_we;
    logic EX_MEM_mem_re;
    logic EX_MEM_mem_reg_w;
    logic [1: 0] EX_MEM_pc_sel;
    logic EX_MEM_jump;
    logic EX_MEM_branch;
    logic [2: 0] EX_MEM_func_3;
    
    // prog cntr output
    logic [31: 0] EX_MEM_pc;
    
    // immediate
    logic [31: 0] EX_MEM_imm;

//=====================================================================
    // MEM_WB_stage
//=====================================================================
    
    // control unit
    logic MEM_WB_reg_we;
    logic MEM_WB_mem_reg_w;
    logic MEM_WB_jump;
    
    // register file
    logic [4: 0] MEM_WB_rs1;
    logic [4: 0] MEM_WB_rs2;
    logic [4: 0] MEM_WB_rd;
    logic [31: 0] MEM_WB_reg_out_1;
    
    // alu
    logic [31: 0] MEM_WB_result;
    
    // data memory
    logic [31: 0] MEM_WB_d_mem_d_out;
    
    // prog cntr output
    logic [31: 0] MEM_WB_pc;
    
    // immediate
    logic [31: 0] MEM_WB_imm;
    
//=====================================================================
    // Data Hazards Modules
//=====================================================================

// ======================= Forwarding Unit ============================
    
    logic [1: 0] forward_op_a_sel;
    logic [1: 0] forward_op_b_sel;
    
    logic [31: 0] forwarded_op_a;
    logic [31: 0] forwarded_op_b;
    
// ======================= Hazard Detection Unit =======================
    
    logic stall;
    logic IF_ID_flush;
    logic ID_EX_flush;
    logic [31: 0] stall_pc;
    
// =====================================================================
// ======================== INSTANTIATION OF MODULES ===================
// =====================================================================

    Program_Counter p_c(
        .clk(clk), 
        .rst(rst), 
        .next_pc(next_pc), 
        .pc(pc)
    );
    
    Instruction_Memory IM(
        .addr(pc), 
        .instr(instr)
    );
    
    Control_Unit cu(
        .opcode(IF_ID_opcode), 
        .stall(stall),
        .reg_we(reg_we), 
        .mem_we(mem_we), 
        .mem_re(mem_re),
        .mem_reg_w(mem_reg_w), 
        .alu_op(alu_op), 
        .op_a_sel(op_a_sel),
        .op_b_sel(op_b_sel), 
        .pc_sel(pc_sel), 
        .jump(jump), 
        .branch(branch)
    );
                
    Immediate_Gen imm_gen(
        .instr(IF_ID_instr), 
        .imm(imm)
    );
    
    ALU alu(
        .op_1(op_a), 
        .op_2(op_b), 
        .alu_instr(alu_instr),
        .func_3(ID_EX_func_3), 
        .zero(zero), 
        .result(alu_out), 
        .branch_taken(branch_taken)
    );
                
    ALU_Control alu_cntrl(
        .alu_op(ID_EX_alu_op), 
        .func_3(ID_EX_func_3), 
        .func_7(ID_EX_func_7), 
        .alu_instr(alu_instr)
    );
                
    Register_File rf(
        .clk(clk), 
        .rst(rst), 
        .we(MEM_WB_reg_we), 
        .rs1(IF_ID_rs1), 
        .rs2(IF_ID_rs2), 
        .rd(MEM_WB_rd), 
        .data_in(wb_data), 
        .reg_out_1(reg_out_1), 
        .reg_out_2(reg_out_2)
    );
                
    Data_Memory dm(
        .clk(clk), 
        .rst(rst), 
        .byte_en(EX_MEM_func_3), 
        .mem_we(EX_MEM_mem_we), 
        .mem_re(EX_MEM_mem_re), 
        .d_mem_addr(EX_MEM_result), 
        .data_in(EX_MEM_reg_out_2), 
        .data_out(d_mem_d_out)
    );
    
// =====================================================================
// ======================== INSTANTIATION OF STAGES ====================
// =====================================================================

    IF_ID_STAGE IF_ID(
        .clk(clk), 
        .rst(rst), 
        .stall(stall), 
        .flush(IF_ID_flush),
        .instr(instr), 
        .IF_ID_opcode(IF_ID_opcode), 
        .IF_ID_rs1(IF_ID_rs1), 
        .IF_ID_rs2(IF_ID_rs2), 
        .IF_ID_rd(IF_ID_rd), 
        .IF_ID_func_3(IF_ID_func_3), 
        .IF_ID_func_7(IF_ID_func_7), 
        .IF_ID_instr(IF_ID_instr), 
        .pc(pc), 
        .IF_ID_pc(IF_ID_pc)
    );
    
    ID_EX_STAGE ID_EX(
        .clk(clk), 
        .rst(rst), 
        .stall(stall), 
        .flush(ID_EX_flush),
        .IF_ID_opcode(IF_ID_opcode), 
        .ID_EX_opcode(ID_EX_opcode),
        .reg_out_1(reg_out_1), 
        .reg_out_2(reg_out_2), 
        .IF_ID_rs1(IF_ID_rs1),
        .IF_ID_rs2(IF_ID_rs2), 
        .IF_ID_rd(IF_ID_rd), 
        .ID_EX_reg_out_1(ID_EX_reg_out_1), 
        .ID_EX_reg_out_2(ID_EX_reg_out_2), 
        .ID_EX_rs1(ID_EX_rs1), 
        .ID_EX_rs2(ID_EX_rs2), 
        .ID_EX_rd(ID_EX_rd), 
        .imm(imm), 
        .ID_EX_imm(ID_EX_imm),
        .reg_we(reg_we), 
        .mem_re(mem_re), 
        .mem_we(mem_we), 
        .mem_reg_w(mem_reg_w), 
        .alu_op(alu_op), 
        .op_b_sel(op_b_sel), 
        .op_a_sel(op_a_sel),
        .pc_sel(pc_sel), 
        .jump(jump), 
        .branch(branch),
        .ID_EX_reg_we(ID_EX_reg_we), 
        .ID_EX_mem_we(ID_EX_mem_we), 
        .ID_EX_mem_re(ID_EX_mem_re), 
        .ID_EX_mem_reg_w(ID_EX_mem_reg_w), 
        .ID_EX_alu_op(ID_EX_alu_op),
        .ID_EX_op_b_sel(ID_EX_op_b_sel), 
        .ID_EX_op_a_sel(ID_EX_op_a_sel),
        .ID_EX_pc_sel(ID_EX_pc_sel), 
        .ID_EX_jump(ID_EX_jump), 
        .ID_EX_branch(ID_EX_branch), 
        .IF_ID_func_3(IF_ID_func_3), 
        .IF_ID_func_7(IF_ID_func_7),
        .ID_EX_func_3(ID_EX_func_3), 
        .ID_EX_func_7(ID_EX_func_7),
        .IF_ID_pc(IF_ID_pc), 
        .ID_EX_pc(ID_EX_pc)
    );
                
    EX_MEM_STAGE EX_MEM(
        .clk(clk), 
        .rst(rst), 
        .zero(zero), 
        .result(alu_out), 
        .branch_taken(branch_taken),
        .EX_MEM_zero(EX_MEM_zero), 
        .EX_MEM_result(EX_MEM_result), 
        .EX_MEM_branch_taken(EX_MEM_branch_taken),
        .ID_EX_rs1(ID_EX_rs1), 
        .ID_EX_rs2(ID_EX_rs2),
        .ID_EX_rd(ID_EX_rd), 
        .ID_EX_reg_out_1(ID_EX_reg_out_1), 
        .ID_EX_reg_out_2(forwarded_op_b),
        .EX_MEM_rs1(EX_MEM_rs1), 
        .EX_MEM_rs2(EX_MEM_rs2),
        .EX_MEM_rd(EX_MEM_rd), 
        .EX_MEM_reg_out_1(EX_MEM_reg_out_1),
        .EX_MEM_reg_out_2(EX_MEM_reg_out_2),
        .ID_EX_reg_we(ID_EX_reg_we), 
        .ID_EX_mem_we(ID_EX_mem_we), 
        .ID_EX_mem_re(ID_EX_mem_re), 
        .ID_EX_mem_reg_w(ID_EX_mem_reg_w), 
        .ID_EX_pc_sel(ID_EX_pc_sel), 
        .ID_EX_jump(ID_EX_jump), 
        .ID_EX_branch(ID_EX_branch), 
        .ID_EX_func_3(ID_EX_func_3),
        .EX_MEM_reg_we(EX_MEM_reg_we), 
        .EX_MEM_mem_we(EX_MEM_mem_we), 
        .EX_MEM_mem_re(EX_MEM_mem_re), 
        .EX_MEM_mem_reg_w(EX_MEM_mem_reg_w), 
        .EX_MEM_pc_sel(EX_MEM_pc_sel), 
        .EX_MEM_jump(EX_MEM_jump), 
        .EX_MEM_branch(EX_MEM_branch), 
        .EX_MEM_func_3(EX_MEM_func_3),
        .ID_EX_pc(ID_EX_pc), 
        .EX_MEM_pc(EX_MEM_pc),
        .ID_EX_imm(ID_EX_imm), 
        .EX_MEM_imm(EX_MEM_imm)
    );
                
    MEM_WB_STAGE MEM_WB(
        .clk(clk), 
        .rst(rst), 
        .EX_MEM_reg_we(EX_MEM_reg_we), 
        .EX_MEM_mem_reg_w(EX_MEM_mem_reg_w), 
        .EX_MEM_jump(EX_MEM_jump), 
        .MEM_WB_reg_we(MEM_WB_reg_we), 
        .MEM_WB_mem_reg_w(MEM_WB_mem_reg_w), 
        .MEM_WB_jump(MEM_WB_jump),
        .EX_MEM_rs1(EX_MEM_rs1), 
        .EX_MEM_rs2(EX_MEM_rs2),
        .EX_MEM_rd(EX_MEM_rd), 
        .EX_MEM_reg_out_1(EX_MEM_reg_out_1),
        .MEM_WB_rs1(MEM_WB_rs1), 
        .MEM_WB_rs2(MEM_WB_rs2), 
        .MEM_WB_rd(MEM_WB_rd), 
        .MEM_WB_reg_out_1(MEM_WB_reg_out_1),
        .EX_MEM_result(EX_MEM_result), 
        .MEM_WB_result(MEM_WB_result),
        .d_mem_d_out(d_mem_d_out), 
        .MEM_WB_d_mem_d_out(MEM_WB_d_mem_d_out),
        .EX_MEM_pc(EX_MEM_pc), 
        .MEM_WB_pc(MEM_WB_pc),
        .EX_MEM_imm(EX_MEM_imm), 
        .MEM_WB_imm(MEM_WB_imm)
    );
    
// ====================================================================================
// ============== INSTANTIATION OF HANDLING DATA and CONTROL HAZARDS ==================
// ====================================================================================

    Forwarding_Unit FWD_U(
        .ID_EX_rs1(ID_EX_rs1), 
        .ID_EX_rs2(ID_EX_rs2), 
        .ID_EX_rd(ID_EX_rd),
        .EX_MEM_rd(EX_MEM_rd), 
        .EX_MEM_reg_we(EX_MEM_reg_we), 
        .EX_MEM_mem_re(EX_MEM_mem_re),
        .MEM_WB_rd(MEM_WB_rd), 
        .MEM_WB_reg_we(MEM_WB_reg_we),
        .forward_op_a_sel(forward_op_a_sel), 
        .forward_op_b_sel(forward_op_b_sel)
    );

   Hazard_Unit HU(
        .IF_ID_opcode(IF_ID_opcode), 
        .IF_ID_rs1(IF_ID_rs1), 
        .IF_ID_rs2(IF_ID_rs2),
        .ID_EX_opcode(ID_EX_opcode), 
        .ID_EX_rd(ID_EX_rd), 
        .ID_EX_mem_re(ID_EX_mem_re), 
        .branch_taken(ID_EX_branch & branch_taken), 
        .pc(pc), 
        .ID_EX_pc(ID_EX_pc),
        .stall(stall),
        .IF_ID_flush(IF_ID_flush), 
        .ID_EX_flush(ID_EX_flush),
        .stall_pc(stall_pc)
    );
// ====================================================================================
    
    // Flags negative, zero, carry, overflow
    assign n = EX_MEM_zero[3];
    assign z = EX_MEM_zero[2];
    assign c = EX_MEM_zero[1];
    assign v = EX_MEM_zero[0];
    
    
    // Forwarded operand A
    always_comb begin
        unique case (forward_op_a_sel)
            2'b00: forwarded_op_a = ID_EX_reg_out_1;       // No forwarding
            2'b01: forwarded_op_a = d_mem_d_out;   // Forward from MEM/WB stage (load output)
            2'b10: forwarded_op_a = EX_MEM_result;         // Forward from EX/MEM ALU
            2'b11: forwarded_op_a = wb_data;               // Forward from WB stage
        endcase
    end
    
    // For ALU operand A
    always_comb begin
        unique case (ID_EX_op_a_sel)
            2'b00: op_a = forwarded_op_a;
            2'b01: op_a = ID_EX_pc;                        // for pc + imm
            2'b10: op_a = ID_EX_pc;                        // for pc + imm
            2'b11: op_a = 32'b0;
        endcase
    end
    
    // Forwarded operand B
    always_comb begin
        unique case (forward_op_b_sel)
            2'b00: forwarded_op_b = ID_EX_reg_out_2;       // No forwarding
            2'b01: forwarded_op_b = d_mem_d_out;   // Forward from MEM/WB stage (load output)
            2'b10: forwarded_op_b = EX_MEM_result;         // Forward from EX/MEM ALU  
            2'b11: forwarded_op_b = wb_data;               // Forward from WB stage
        endcase
    end
    
    // For ALU operand B
    assign op_b = (ID_EX_op_b_sel) ? ID_EX_imm : forwarded_op_b;
    
    // Writeback Mux for Register File
    always_comb begin
        if (MEM_WB_jump)
            wb_data = MEM_WB_pc + 4;                       // JAL/JALR return address
        else begin
            if (MEM_WB_mem_reg_w)
                wb_data = MEM_WB_d_mem_d_out;              // Load instruction output
            else
                wb_data = MEM_WB_result;                   // ALU execution output
        end
    end
    
    // Next PC selection logic
    always_comb begin
        unique case (ID_EX_pc_sel)
            2'b00: begin
                if (stall)
                    next_pc = stall_pc;
                else
                    next_pc = pc + 4;
            end
            2'b01: next_pc = ID_EX_pc + ID_EX_imm;        // JAL target
            2'b10: next_pc = ID_EX_reg_out_1+ ID_EX_imm;  // JALR target using forwarded rs1
            2'b11: begin
                if (ID_EX_branch & branch_taken)
                    next_pc = ID_EX_pc + ID_EX_imm;        // Branch taken target
                else
                    next_pc = pc + 4;
            end
        endcase
    end

endmodule
