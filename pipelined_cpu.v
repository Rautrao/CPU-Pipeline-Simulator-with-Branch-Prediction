`timescale 1ns / 1ps

module pipelined_cpu (
    input wire clk,
    input wire reset
);

    // --- ARCHITECTURE DEFINITIONS ---
    // Instruction Format: [15:12] Opcode | [11:8] Rs1 | [7:4] Rs2 | [3:0] Rd/Imm
    // Opcodes: 0001 (ADD), 0010 (SUB), 0011 (LOAD), 0100 (STORE), 0101 (BEQ)

    // --- PIPELINE WIRES & REGISTERS ---
    
    // FETCH STAGE
    reg [15:0] pc; // current program counter 
    reg [15:0] instr_mem [0:31]; // 32-word Instruction Memory
    wire [15:0] fetch_instr;  // Stroing current instruction
    wire predict_taken;  // --
    
    // IF/ID PIPELINE REGISTER
    reg [15:0] if_id_pc; // Stored PC 
    reg [15:0] if_id_instr; // Stored Instruction
    reg if_id_predicted_taken; //  --
    
    // DECODE STAGE
    reg [15:0] reg_file [0:15]; // 16 General Purpose Registers  (opcode : 4, Reg1 : 4, Reg2, 4 Reg3: 4)
    wire stall; 
    
    // ID/EX PIPELINE REGISTER
    reg [15:0] id_ex_pc; // Stored PC in ID/EX 
    reg [3:0]  id_ex_opcode; // ID/EX Opcode field : 4-bits
    reg [15:0] id_ex_val1, id_ex_val2; // there two registers hold 16 bit data comming form both register 
    reg [3:0]  id_ex_rd;  // Destination Register which contains Base Address
    reg [3:0]  id_ex_rs1, id_ex_rs2; // Source registers for forwarding
    reg id_ex_predicted_taken;  
    reg id_ex_is_branch; // is set/unset by control unit if the opcode field contains 0101 (BEQ)
    
    // EXECUTE STAGE
    reg [15:0] alu_result; // 16 bit result of ALU 
    reg branch_actual_taken; 
    reg branch_mispredicted;
    wire [15:0] branch_target; 
    reg [15:0] alu_mux_A, alu_mux_B; 
    
    // EX/MEM PIPELINE REGISTER
    reg [3:0]  ex_mem_opcode;
    reg [15:0] ex_mem_alu_res;
    reg [15:0] ex_mem_val2;
    reg [3:0]  ex_mem_rd;
    
    // MEMORY STAGE
    reg [15:0] data_mem [0:31]; // 32-word Data Memory
    reg [15:0] mem_read_data;
    
    // MEM/WB PIPELINE REGISTER
    reg [3:0]  mem_wb_opcode;
    reg [15:0] mem_wb_alu_res;
    reg [15:0] mem_wb_mem_data;
    reg [3:0]  mem_wb_rd;

    // --- MODULE INSTANTIATIONS ---
    
    branch_predictor bp (
        .clk(clk), .reset(reset),
        .pc_fetch(pc), .prediction_taken(predict_taken),
        .pc_execute(id_ex_pc), .is_branch_ex(id_ex_is_branch), .actual_taken(branch_actual_taken)
    );

    hazard_unit hu (
        .id_ex_mem_read(id_ex_opcode == 4'b0011), .id_ex_rd(id_ex_rd),
        .if_id_rs1(if_id_instr[11:8]), .if_id_rs2(if_id_instr[7:4]),
        .stall(stall)
    );

    wire [1:0] forward_A;
    wire [1:0] forward_B;
    wire ex_mem_reg_write = (ex_mem_opcode == 4'b0001 || ex_mem_opcode == 4'b0010 || ex_mem_opcode == 4'b0011);
    wire mem_wb_reg_write = (mem_wb_opcode == 4'b0001 || mem_wb_opcode == 4'b0010 || mem_wb_opcode == 4'b0011);

    forwarding_unit fu (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forward_A(forward_A),
        .forward_B(forward_B)
    );

    // --- INITIALIZATION FOR TESTBENCH ---
    initial begin
        // Hardcode a simple program into ROM
        // 0: LOAD R1, R0 (Assume R0 is 0, loads address 0)
        // 1: ADD R2, R1, R1
        // 2: BEQ R2, R1, Target(4) -> (0101 | 0010 | 0001 | 0100)
        // 3: SUB R3, R2, R1
        // 4: STORE R2, R3
        instr_mem[0] = 16'b0011_0000_0000_0001; 
        instr_mem[1] = 16'b0001_0001_0001_0010; 
        instr_mem[2] = 16'b0101_0010_0001_0100; // Branch
        instr_mem[3] = 16'b0010_0010_0001_0011; 
        instr_mem[4] = 16'b0100_0010_0011_0000; 
        
        reg_file[0] = 16'd0; // 
        reg_file[1] = 16'd5; // Pre-load R1 for testing
        reg_file[2] = 16'd5; // Pre-load R2 to force BEQ to be true
    end 

    assign fetch_instr = instr_mem[pc[4:0]];
    assign branch_target = id_ex_pc + id_ex_rd; // Simple target calculation

    // --- ARCHITECTURE DEFINITIONS ---
    // Instruction Format: [15:12] Opcode | [11:8] Rs1 | [7:4] Rs2 | [3:0] Rd/Imm
    // Opcodes: 0001 (ADD), 0010 (SUB), 0011 (LOAD), 0100 (STORE), 0101 (BEQ)

    // --- MAIN PIPELINE CLOCK LOOP ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 0;
            if_id_instr <= 0; id_ex_opcode <= 0; ex_mem_opcode <= 0; mem_wb_opcode <= 0;
            branch_mispredicted <= 0;
        end else begin
            
            // 5. WRITEBACK (WB) STAGE
            if (mem_wb_opcode == 4'b0001 || mem_wb_opcode == 4'b0010) begin
                reg_file[mem_wb_rd] <= mem_wb_alu_res; // Write ALU result
            end else if (mem_wb_opcode == 4'b0011) begin
                reg_file[mem_wb_rd] <= mem_wb_mem_data; // Write LOAD data
            end

            // 4. MEMORY (MEM) STAGE
            mem_wb_opcode <= ex_mem_opcode;
            mem_wb_rd <= ex_mem_rd;
            mem_wb_alu_res <= ex_mem_alu_res;
            
            if (ex_mem_opcode == 4'b0011) begin // LOAD
                mem_wb_mem_data <= data_mem[ex_mem_alu_res[4:0]];
            end else if (ex_mem_opcode == 4'b0100) begin // STORE
                data_mem[ex_mem_alu_res[4:0]] <= ex_mem_val2;
            end

            // 3. EXECUTE (EX) STAGE
            ex_mem_opcode <= id_ex_opcode;
            ex_mem_rd <= id_ex_rd;
            
            // Forwarding Muxes
            case (forward_A)
                2'b10: alu_mux_A = ex_mem_alu_res;
                2'b01: alu_mux_A = (mem_wb_opcode == 4'b0011) ? mem_wb_mem_data : mem_wb_alu_res;
                default: alu_mux_A = id_ex_val1;
            endcase

            case (forward_B)
                2'b10: alu_mux_B = ex_mem_alu_res;
                2'b01: alu_mux_B = (mem_wb_opcode == 4'b0011) ? mem_wb_mem_data : mem_wb_alu_res;
                default: alu_mux_B = id_ex_val2;
            endcase
            
            ex_mem_val2 <= alu_mux_B;
            
            // ALU Logic
            case (id_ex_opcode)
                4'b0001: alu_result = alu_mux_A + alu_mux_B; // ADD
                4'b0010: alu_result = alu_mux_A - alu_mux_B; // SUB
                default: alu_result = alu_mux_A; // Default pass-through
            endcase
            ex_mem_alu_res <= alu_result;

            // Branch Resolution Logic
            branch_actual_taken = (id_ex_opcode == 4'b0101) && (alu_mux_A == alu_mux_B);
            branch_mispredicted = (id_ex_is_branch) && (branch_actual_taken != id_ex_predicted_taken);
            
            // 2. DECODE (ID) STAGE
            if (stall || branch_mispredicted) begin
                // Insert Bubble / Flush
                id_ex_opcode <= 4'b0000;
                id_ex_is_branch <= 1'b0;
                id_ex_rs1 <= 4'b0;
                id_ex_rs2 <= 4'b0;
            end else begin
                id_ex_pc <= if_id_pc;
                id_ex_opcode <= if_id_instr[15:12];
                id_ex_val1 <= reg_file[if_id_instr[11:8]];
                id_ex_val2 <= reg_file[if_id_instr[7:4]];
                id_ex_rd <= if_id_instr[3:0];
                id_ex_rs1 <= if_id_instr[11:8];
                id_ex_rs2 <= if_id_instr[7:4];
                id_ex_predicted_taken <= if_id_predicted_taken;
                id_ex_is_branch <= (if_id_instr[15:12] == 4'b0101);
            end

            // 1. FETCH (IF) STAGE
            if (branch_mispredicted) begin
                // Flush: Correct the PC to the right path
                pc <= branch_actual_taken ? branch_target : (id_ex_pc + 1);
                if_id_instr <= 16'b0; // Flush IF/ID
            end else if (!stall) begin
                if_id_pc <= pc;
                if_id_instr <= fetch_instr;
                if_id_predicted_taken <= predict_taken;
                
                // Fetch next instruction based on Branch Predictor
                if (fetch_instr[15:12] == 4'b0101 && predict_taken) begin
                    pc <= pc + fetch_instr[3:0]; // Jump to predicted target
                end else begin
                    pc <= pc + 1; // Normal PC increment
                end
            end
        end
    end
endmodule