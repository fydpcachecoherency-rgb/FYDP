module Instruction_Memory(input  logic [31: 0] addr, output logic [31: 0] instr );

    // 1024 words (32-bit each) = 4096 bytes total
    logic [31: 0] imem [0: 2**10 - 1];
    
    initial begin
        integer i;
            for (i = 0; i < 1024; i++) 
                imem[i] = 32'h00000013; // NOP
            $readmemh("MY_CODE.HEX", imem);
    end
    
    // Read Combinational
    // Word-aligned read: drop lower 2 bits of byte address
    assign instr = imem[addr[11: 2]];

endmodule
