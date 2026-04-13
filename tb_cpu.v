`timescale 1ns / 1ps

module tb_cpu();

    // Testbench signals
    reg clk;
    reg reset;

    // Instantiate the Top-Level CPU
    pipelined_cpu UUT (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        // 1. Initialize signals and assert reset
        clk = 0;
        reset = 1;
        
        $display("--- Starting 5-Stage Pipeline Simulation ---");
        
        // 2. Release reset after 15ns
        #15 reset = 0;

        // 3. Let the CPU run for 20 clock cycles
        // This gives enough time for instructions to propagate through IF->ID->EX->MEM->WB
        #200; 

        // 4. End simulation
        $display("--- Simulation Complete ---");
        $finish;
    end

    // Monitor Block: Print out the state of the pipeline on every clock cycle
    always @(posedge clk) begin
        if (!reset) begin
            $display("Time: %0t | PC: %d | IF/ID Instr: %b | EX Opcode: %b | Mispredict: %b", 
                     $time, UUT.pc, UUT.if_id_instr, UUT.id_ex_opcode, UUT.branch_mispredicted);
        end
    end

endmodule