# 16-Bit RISC Pipelined CPU with Dynamic Branch Prediction

## 📌 Project Overview
This project is a custom-designed 16-bit RISC CPU built entirely in Verilog. It implements a full 5-stage instruction pipeline (Instruction Fetch, Instruction Decode, Execute, Memory, Write-Back) and is specifically engineered to handle pipeline hazards and control flow optimization.

This architecture avoids the common pitfalls of basic CPUs by implementing structural hazard detection, data forwarding, and a dynamic 2-bit branch prediction algorithm directly in hardware.

## 🚀 Key Features
* **5-Stage Pipeline:** Fully parallel execution using `IF/ID`, `ID/EX`, `EX/MEM`, and `MEM/WB` pipeline registers.
* **Data Forwarding Unit:** Resolves data hazards on the fly by intelligently routing the latest calculated data from the `MEM` and `WB` stages directly back into the `ALU`, bypassing the register file to prevent unnecessary pipeline stalls.
* **Hardware Hazard Detection Unit:** Monitors read/write dependencies in real-time. If an unavoidable Data Hazard is detected (e.g., a `LOAD` instruction that cannot be forwarded in time), the unit automatically stalls the PC and inserts a pipeline bubble to prevent data corruption.
* **Dynamic 2-Bit Branch Predictor:** Implements a Branch History Table (BHT) to predict branch outcomes (`Strongly Not Taken`, `Weakly Not Taken`, `Weakly Taken`, `Strongly Taken`). It features hardware-level misprediction recovery, automatically flushing invalid speculative instructions from the pipeline and recalculating the correct Program Counter.

## 📁 Module Breakdown
The project is modularized into the following Verilog files:
1. `pipelined_cpu.v`: The top-level module containing the datapath, pipeline registers, embedded RAM/ROM, and ALU.
2. `branch_predictor.v`: The FSM handling the 2-bit dynamic prediction logic and BHT updates.
3. `hazard_unit.v`: Combinational logic that monitors register dependencies to trigger hardware stalls.
4. `forwarding_unit.v`: Combinational logic that routes the latest data from the pipeline registers back to the ALU to optimize execution speed.
5. `tb_cpu.v`: The testbench that simulates the clock cycle and monitors pipeline state transitions.

## ⚙️ Instruction Set Architecture (ISA)
The CPU supports a custom 16-bit instruction format: 
`[15:12] Opcode | [11:8] Rs1 | [7:4] Rs2 | [3:0] Rd/Imm`

| Instruction | Opcode | Description |
| :--- | :--- | :--- |
| **ADD** | `0001` | Adds Rs1 and Rs2, stores in Rd |
| **SUB** | `0010` | Subtracts Rs2 from Rs1, stores in Rd |
| **LOAD** | `0011` | Loads data from memory address into Rd |
| **STORE**| `0100` | Stores data from Rs2 into memory address |
| **BEQ** | `0101` | Branch to Target if Rs1 == Rs2 |

## 💻 Simulation & Testing
A hardcoded program is pre-loaded into the CPU's Instruction Memory to test the architecture's edge cases, including data dependencies, full forwarding passes, memory initialization, and branch mispredictions/flushes.

**To run the simulation using Icarus Verilog:**
```bash
iverilog -o cpu_sim.out tb_cpu.v pipelined_cpu.v branch_predictor.v hazard_unit.v forwarding_unit.v
vvp cpu_sim.out
```
