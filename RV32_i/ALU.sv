import risc_v_pkg::*;
module ALU(input logic [31: 0] op_1, input logic [31: 0] op_2, input alu_instr_p alu_instr, input logic [2: 0] func_3,
output logic [3: 0] zero, output logic [31: 0] result, output logic branch_taken );
    logic [32: 0] wide_result;
    logic n, z, c, v;
    logic [31: 0] shift_op_2;
    logic [5: 0] shift;
    
    assign shift_op_2 = op_2 & 32'h1F;
    assign shift = shift_op_2[5: 0];
    
    always_comb begin
        case(alu_instr)
            ADD: begin
                result = op_1 + op_2;                               // ADD
                wide_result = {1'b0, op_1} + {1'b0, op_2}; 
                
                //carry flag logic
                c = wide_result[32];
                
                // overflow flag 
                // for add: same sign inputs, different sign result
                if ((op_1[31] == op_2[31]) && (wide_result[31] != op_1[31]))
                    v = 1'b1;
                else
                    v = 1'b0;
            end
            SUB: begin
                result = op_1 - op_2;                               // SUB
                wide_result = {1'b0, op_1} - {1'b0, op_2};
                
                //carry flag logic
                c = wide_result[32];
                
                // overflow flag 
                // for sub: different sign inputs, result sign != A's sign
                if ((op_1[31] != op_2[31]) && (wide_result[31] != op_1[31]))
                    v = 1'b1;
                else
                    v = 1'b0;
            end
            SLL: result = op_1 << shift;                         // SLL (shift left logical)
            SLT: result = ($signed(op_1) < $signed(op_2));       // SLT (signed compare)
            SLTU: result = (op_1 < op_2);                         // SLTU (unsigned compare)
            XOR: result = op_1 ^ op_2;                           // XOR
            SRL: result = op_1 >> shift;                         // SRL (shift right logical)
            SRA: result = $signed(op_1) >>> op_2[4: 0];          // SRA (shift right arithmetic)
            OR: result = op_1 | op_2;                           // OR
            AND: result = op_1 & op_2;                           // AND
            default: result = 32'b0;                                 // Default
        endcase

    end
 always_comb begin
    unique case (func_3)

        // BEQ
        3'b000:
            branch_taken = (op_1 == op_2);

        // BNE
        3'b001:
            branch_taken = (op_1 != op_2);

        // BLT - signed
        3'b100:
            branch_taken = ($signed(op_1) < $signed(op_2));

        // BGE - signed
        3'b101:
            branch_taken = ($signed(op_1) >= $signed(op_2));

        // BLTU - unsigned
        3'b110:
            branch_taken = ($unsigned(op_1) < $unsigned(op_2));

        // BGEU - unsigned
        3'b111:
            branch_taken = ($unsigned(op_1) >= $unsigned(op_2));

        default:
            branch_taken = 1'b0;

    endcase
end
                    
    // Zero flag
    assign z = (result == 0) ? 1'b1: 1'b0;

    // Negative flag
    assign n = result[31];
    
    assign zero = {n, z, c, v};
endmodule
