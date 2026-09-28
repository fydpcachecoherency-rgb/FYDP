import risc_v_pkg::*;
module Immediate_Gen( input  logic [31:0] instr, output logic [31:0] imm );
 opcode_p opcode;
 assign opcode = opcode_p'(instr[6:0]);
    
 always_comb begin
    case (opcode)
        IA_TYPE,IL_TYPE, JALR: begin 
                // I-type immediate: sign-extend bits [31:20]
                imm = {{20{instr[31]}}, instr[31:20]};
                   end
            
        S_TYPE: begin 
                // S-type immediate: sign-extend {bits[31:25], bits[11:7]}
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
                   end
            
        B_TYPE: begin 
                // B-type immediate: sign-extend {bit[31], bit[7], bits[30:25], bits[11:8], 1'b0}
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
                   end
            
        LUI,AUIPC: begin
                // U-type immediate: {bits[31:12], 12'b0}
                imm = {instr[31:12], 12'b0};
                    end
            
        JAL: begin 
                // J-type immediate: sign-extend {bit[31], bits[19:12], bit[20], bits[30:21], 1'b0}
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
                    end
            
         default: begin
                imm = 32'h0;
                 end
    endcase
 end
    
endmodule
