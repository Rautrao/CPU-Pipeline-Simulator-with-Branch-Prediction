`timescale 1ns / 1ps

module branch_predictor (
    input wire clk,
    input wire reset,
    
    // FETCH STAGE: Requesting a prediction
    input wire [15:0] pc_fetch,        // The PC currently being fetched
    output wire prediction_taken,      // 1 = Predict Taken, 0 = Predict Not Taken
    
    // EXECUTE STAGE: Updating the predictor after actual calculation
    input wire [15:0] pc_execute,      // The PC of the branch currently in EX stage
    input wire is_branch_ex,           // High if the instruction in EX is actually a branch
    input wire actual_taken            // 1 = Branch was taken, 0 = Branch was not taken
);

    // Branch History Table (BHT)
    // 16 entries (using lower 4 bits of PC as index), each entry is 2 bits.
    // States: 00 (Strongly Not Taken), 01 (Weakly Not Taken), 10 (Weakly Taken), 11 (Strongly Taken)
    reg [1:0] bht [0:15];
    integer i;

    // PREDICTION LOGIC (Combinational - happens instantly in Fetch stage)
    // The Most Significant Bit (MSB) of the 2-bit state dictates the prediction.
    assign prediction_taken = bht[pc_fetch[3:0]][1]; 

    // UPDATE LOGIC (Sequential - updates on clock edge from Execute stage)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize all BHT entries to 01 (Weakly Not Taken)
            for (i = 0; i < 16; i = i + 1) begin
                bht[i] <= 2'b01;
            end
        end 
        else if (is_branch_ex) begin
            // 2-Bit State Machine Logic
            case (bht[pc_execute[3:0]])
                2'b00: bht[pc_execute[3:0]] <= actual_taken ? 2'b01 : 2'b00; // Strong NT
                2'b01: bht[pc_execute[3:0]] <= actual_taken ? 2'b10 : 2'b00; // Weak NT
                2'b10: bht[pc_execute[3:0]] <= actual_taken ? 2'b11 : 2'b01; // Weak T
                2'b11: bht[pc_execute[3:0]] <= actual_taken ? 2'b11 : 2'b10; // Strong T
            endcase
        end
    end
endmodule