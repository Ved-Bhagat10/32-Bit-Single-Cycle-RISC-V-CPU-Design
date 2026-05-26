# Control Signals

The Control Unit generates different control signals depending on the instruction opcode.

These signals control datapath behavior during instruction execution.

---

# regf_w

Enables writing into the register file.

- 1 → write enabled
- 0 → write disabled

Used in:
- arithmetic instructions
- load instructions
- jump instructions

---

# alu_op

Determines the category of ALU operation.

| alu_op | Purpose |
|---|---|
| 00 | ADD operation (load/store/address calculation) |
| 01 | SUB operation (branch comparison) |
| 10 | R-Type / I-Type ALU decoding |

---

# alu_src

Selects second ALU operand source.

| alu_src | ALU Input B |
|---|---|
| 0 | Register file output |
| 1 | Immediate Generator output |

---

# imm_sel

Determines which immediate format should be generated.

| imm_sel | Instruction Type |
|---|---|
| 000 | I-Type |
| 001 | S-Type |
| 010 | B-Type |
| 011 | U-Type |
| 100 | J-Type |

---

# mem_w

Enables memory write operation.

Used during:
- store instructions

---

# mem_r

Enables memory read operation.

Used during:
- load instructions

---

# result_src

Selects the value written back into the register file.

| result_src | Source |
|---|---|
| 00 | ALU result |
| 01 | Memory data |
| 10 | PC + 4 |
| 11 | Immediate Generator output |

---

# jump

Indicates jump instruction execution.

Used in:
- jal
- jalr

---

# branch

Indicates branch instruction execution.

Used in:
- beq
- bne
- blt
- bge
- bltu
- bgeu