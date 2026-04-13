`timescale 1ns / 1ps

module hazard_unit (
    // Inputs from the ID/EX Pipeline Register
    input wire id_ex_mem_read,     // Is the instruction in EX a LOAD?
    input wire [3:0] id_ex_rd,     // The destination register of the EX instruction
    
    // Inputs from the IF/ID Pipeline Register (The instruction currently decoding)
    input wire [3:0] if_id_rs1,    // Source register 1 being read
    input wire [3:0] if_id_rs2,    // Source register 2 being read
    
    // Outputs to control the pipeline
    output reg stall               // 1 = Freeze PC and IF/ID, flush ID/EX (insert bubble)
);

    always @(*) begin
        // DATA HAZARD CONDITION:
        // If the instruction ahead of us is reading from memory, AND its destination 
        // matches either of our source registers, we must stall for one cycle.
        if (id_ex_mem_read && ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin
            stall = 1'b1;
        end else begin
            stall = 1'b0;
        end
    end
endmodule