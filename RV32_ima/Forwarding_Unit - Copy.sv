module Forwarding_Unit(
    // ID_EX stage register addresses
    input logic [4:0] ID_EX_rs1,
    input logic [4:0] ID_EX_rs2,
    input logic [4:0] ID_EX_rd,
 
    
    // EX_MEM stage signals
    input logic [4:0] EX_MEM_rd,
    input logic EX_MEM_reg_we,
    input logic EX_MEM_mem_re,
    input logic EX_MEM_amo_en,
   
    // MEM_WB stage signals
    input logic [4:0] MEM_WB_rd,
    input logic MEM_WB_reg_we,
    
    // Forwarding control outputs
    output logic [1:0] forward_op_a_sel,
    output logic [1:0] forward_op_b_sel
);

    // Forward operand A (rs1) logic
    always_comb begin
        // Priority: EX/MEM stage forwarding first (most recent)
        if (EX_MEM_rd == ID_EX_rs1 && EX_MEM_reg_we == 1'b1 && ID_EX_rs1 != 5'b00000) begin
            if (EX_MEM_mem_re == 1'b1 || EX_MEM_amo_en == 1'b1)
                forward_op_a_sel = 2'b01; // Forward from memory (load hazard - need stall)
            else
                forward_op_a_sel = 2'b10; // Forward from EX/MEM ALU result
        end
        // MEM/WB stage forwarding (lower priority)
        else begin
            if (MEM_WB_rd == ID_EX_rs1 && MEM_WB_reg_we == 1'b1 && ID_EX_rs1 != 5'b00000) 
                forward_op_a_sel = 2'b11; // Forward from WB stage
            else 
                forward_op_a_sel = 2'b00; // No forwarding needed
        end
    end
    
    // Forward operand B (rs2) logic
    always_comb begin
        // Priority: EX/MEM stage forwarding first (most recent)
        if (EX_MEM_rd == ID_EX_rs2 && EX_MEM_reg_we == 1'b1 && ID_EX_rs2 != 5'b00000) begin
            if (EX_MEM_mem_re == 1'b1 || EX_MEM_amo_en == 1'b1)
                forward_op_b_sel = 2'b01; // Forward from memory (load hazard also need stall)
            else
                forward_op_b_sel = 2'b10; // Forward from EX_MEM ALU result
        end
        // MEM/WB stage forwarding (lower priority)
        else begin
            if (MEM_WB_rd == ID_EX_rs2 && MEM_WB_reg_we == 1'b1 && ID_EX_rs2 != 5'b00000) 
                forward_op_b_sel = 2'b11; // Forward from WB stage
            else 
                forward_op_b_sel = 2'b00; // No forwarding needed
        end
    end

endmodule
