`timescale 1ns / 1ps

module forwarding_unit (
    input wire [3:0] id_ex_rs1,
    input wire [3:0] id_ex_rs2,
    input wire [3:0] ex_mem_rd,
    input wire       ex_mem_reg_write,
    input wire [3:0] mem_wb_rd,
    input wire       mem_wb_reg_write,
    
    output reg [1:0] forward_A,
    output reg [1:0] forward_B
);

    always @(*) begin
        // Default: No forwarding
        forward_A = 2'b00;
        forward_B = 2'b00;

        // --- Forward A Logic (Rs1) ---
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_A = 2'b10;
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs1)) begin
            forward_A = 2'b01;
        end

        // --- Forward B Logic (Rs2) ---
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_B = 2'b10;
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs2)) begin
            forward_B = 2'b01;
        end
    end
endmodule
