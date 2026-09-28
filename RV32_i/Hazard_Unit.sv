module Hazard_Unit(
    input logic [6:0] IF_ID_opcode,         // Current instruction opcode
    input logic [4:0] IF_ID_rs1,            // Current instruction rs1
    input logic [4:0] IF_ID_rs2,            // Current instruction rs2
    
    input logic [6:0] ID_EX_opcode,     // Previous instruction opcode
    input logic [4:0] ID_EX_rd,         // Previous instruction destination register
    input logic ID_EX_mem_re,           // Previous instruction is a load
    
    input logic branch_taken,
    
    // PC for stalling
    input logic [31:0] pc,
    
    // PC for flushing
    input logic [31:0] ID_EX_pc,
    
    output logic stall,
    output logic IF_ID_flush,
    output logic ID_EX_flush,
    output logic [31:0] stall_pc
);

    always_comb begin
    
        // Check if previous instruction (in EX stage) is a LOAD
        if (ID_EX_mem_re == 1'b1 && ID_EX_rd != 5'b00000) begin
            
            // Check current instruction type and register dependencies
            case (IF_ID_opcode)
                7'b0110011: begin // R-type
                    if (ID_EX_rd == IF_ID_rs1 || ID_EX_rd == IF_ID_rs2) begin
                        stall = 1'b1;
                        IF_ID_flush = 1'b0;
                        ID_EX_flush = 1'b0;
                        stall_pc = pc; // Keep same PC (don't increment)
                    end
                end
                
                7'b0010011: begin // I-type
                    if (ID_EX_rd == IF_ID_rs1) begin
                        stall = 1'b1;
                        IF_ID_flush = 1'b0;
                        ID_EX_flush = 1'b0;
                        stall_pc = pc; // Keep same PC (don't increment)
                    end
                end
                
                7'b0100011: begin // S-type
                    if (ID_EX_rd == IF_ID_rs1 || ID_EX_rd == IF_ID_rs2) begin
                        stall = 1'b1;
                        IF_ID_flush = 1'b0;
                        ID_EX_flush = 1'b0;
                        stall_pc = pc; // Keep same PC (don't increment)
                    end
                end
                
                7'b0000011: begin // Load instructions
                    if (ID_EX_rd == IF_ID_rs1) begin
                        stall = 1'b1;
                        IF_ID_flush = 1'b0;
                        ID_EX_flush = 1'b0;
                        stall_pc = pc; // Keep same PC (don't increment)
                    end
                end
                
                7'b1100011: begin // Branch instructions 
                    if (ID_EX_rd == IF_ID_rs1 || ID_EX_rd == IF_ID_rs2) begin
                        stall = 1'b1;
                        IF_ID_flush = 1'b0;
                        ID_EX_flush = 1'b0;
                        stall_pc = pc; // Keep same PC (don't increment)
                    end
                end
                
                7'b1100111: begin // JALR
                    if (ID_EX_rd == IF_ID_rs1) begin
                        stall = 1'b1;
                        stall_pc = pc; // Keep same PC (don't increment)
                    end
                end
                
                default: begin
                    stall = 1'b0;
                end
            endcase
        end
        
        // Hazard Detection for branch
        if (branch_taken) begin
            stall = 1'b0;
            IF_ID_flush = 1'b1;
            ID_EX_flush = 1'b1;
            stall_pc = pc; // Keep same PC (don't increment)
        end
        
        // Hazard Detection for jump
        else if(ID_EX_opcode == 7'b1101111 || ID_EX_opcode == 7'b1100111)begin
            stall = 1'b0;
            IF_ID_flush = 1'b1;
            ID_EX_flush = 1'b1;
            stall_pc = pc; // Keep same PC (don't increment)
        end
        
        else begin
            stall = 1'b0;
            IF_ID_flush = 1'b0;
            ID_EX_flush = 1'b0;
            stall_pc = pc; // Keep same PC (don't increment)
        end
    end
endmodule