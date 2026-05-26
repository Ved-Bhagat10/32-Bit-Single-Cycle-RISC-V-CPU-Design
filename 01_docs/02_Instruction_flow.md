# Instruction Execution Flow

This document explains how different instruction types move through the datapath during execution.

Since the processor follows a single-cycle architecture, every instruction completes all stages within one clock cycle.

---

# R-Type Instructions

Example:
```assembly
add x3, x1, x2
```

## Flow
1. Instruction fetched from instruction memory
2. Opcode decoded by Control Unit
3. Register file reads x1 and x2
4. ALU Control Unit selects ADD operation
5. ALU performs addition
6. Result written back into x3

---

# I-Type Arithmetic Instructions

Example:
```assembly
addi x1, x0, 5
```

## Flow
1. Instruction fetched
2. Immediate Generator extracts immediate value
3. Register file reads source register
4. ALU performs operation using register + immediate
5. Result written back into destination register

---

# Load Instructions

Example:
```assembly
lw x5, 0(x1)
```

## Flow
1. Base register value read from register file
2. Immediate offset generated
3. ALU computes effective memory address
4. Data memory performs read operation
5. Loaded data written back into register file

---

# Store Instructions

Example:
```assembly
sw x3, 4(x2)
```

## Flow
1. Register file reads base register and source data register
2. Immediate Generator creates offset
3. ALU computes effective address
4. Data memory stores register value at computed address

No register write-back occurs during store instructions.

---

# Branch Instructions

Example:
```assembly
beq x1, x2, label
```

## Flow
1. Register file reads comparison operands
2. ALU performs subtraction/comparison
3. Branch logic checks branch condition
4. If condition is true:
   - PC updated using branch target
5. Otherwise:
   - PC increments normally

---

# JAL Instruction

Example:
```assembly
jal x1, label
```

## Flow
1. Return address (PC + 4) generated
2. Jump target computed using PC + immediate
3. Return address written into destination register
4. PC updated with jump target

---

# JALR Instruction

Example:
```assembly
jalr x1, 0(x2)
```

## Flow
1. Register file reads base register
2. Immediate offset generated
3. Jump target computed using rs1 + immediate
4. Least significant bit cleared as per RISC-V specification
5. Return address stored in destination register
6. PC updated with computed target

---

# LUI Instruction

Example:
```assembly
lui x5, 0x12345
```

## Flow
1. Immediate Generator creates upper immediate value
2. Lower 12 bits filled with zeros
3. Immediate directly written into destination register

ALU is not required for this operation.

---

# AUIPC Instruction

Example:
```assembly
auipc x5, 0x10
```

## Flow
1. Immediate Generator creates upper immediate
2. ALU adds PC with immediate value
3. Result written back into destination register

This instruction is useful for PC-relative addressing.