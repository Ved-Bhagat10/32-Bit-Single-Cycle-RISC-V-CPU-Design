# Branching and Jump Logic

This document explains how control flow instructions modify the Program Counter.

---

# Sequential Execution

Normally, the Program Counter increments by 4.

```verilog
assign pc_plus_four = pc + 32'd4;
```

This moves execution to the next instruction.

---

# Branch Instructions

Example:
```assembly
beq x1, x2, label
```

The branch condition is checked using comparison logic.

```verilog
assign branch_taken =
    branch && (
        (func3 == 3'b000 && zero)
    );
```

If the condition is true:

```verilog
assign branch_target = pc + imm_out;
```

The PC updates using the branch target.

Otherwise execution continues sequentially.

---

# Jump Instructions

## JAL

```assembly
jal x1, label
```

Jump target:

```verilog
assign jump_target = pc + imm_out;
```

Return address:

```text
PC + 4
```

is written into the destination register.

---

# JALR

```assembly
jalr x1, 0(x2)
```

Jump target:

```verilog
assign jalr_target = (rd1 + imm_out) & ~32'd1;
```

The least significant bit is cleared according to the RISC-V specification.

This instruction supports register-relative jumps and function returns.

---

# PC Update Multiplexer

Final PC selection logic:

```verilog
assign pc_next =
    branch_taken ? branch_target :
    jump ? ((opcode == 7'd103) ? jalr_target : jump_target) :
    pc_plus_four;
```

Priority:
1. branch target
2. jump target
3. normal sequential execution