
module Register_File(input logic clk, input logic rst, input logic we, input logic [4: 0] rs1, input logic [4: 0] rs2, input logic [4: 0] rd, input logic  [31: 0] data_in,
output logic [31: 0] reg_out_1, output logic [31: 0] reg_out_2 );
    
 int i;
 logic [31: 0] regs [0: 31];
    
    // write on clk edge
 always_ff @(negedge clk or posedge rst) begin
    if(rst) begin
       for (i = 0 ; i<=31 ; i=i+1) begin
                regs[i] <= 0;
       end
    end
    else begin
       if(we) begin
          if(rd != 00)
              regs[rd] <= data_in;
          else
              regs[rd] <= 0;
       end
    end
 end
    
    // read combinational
  assign reg_out_1 = (rs1 != 0) ? regs[rs1] : 5'b00000; // if access x0 so it is zero
  assign reg_out_2 = (rs2 != 0) ? regs[rs2] : 5'b00000; // if access x0 so it is zero
    
endmodule