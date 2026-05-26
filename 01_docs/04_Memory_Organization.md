# Memory Organization

The processor uses separate instruction memory and data memory.

This follows a Harvard-style memory organization.

---

# Instruction Memory

```verilog
reg [31:0] inst_mem [0:255];
```

- 256 words
- each word = 32 bits
- total size = 1 KB

Instruction fetch:

```verilog
assign instruction = inst_mem[pc[9:2]];
```

---

# Why pc[9:2]?

The Program Counter stores byte addresses.

Since each instruction is 4 bytes long:

```text
PC values:
0, 4, 8, 12 ...
```

But instruction memory indexing works as:

```text
0, 1, 2, 3 ...
```

So the byte address must be converted into a word index.

This is done using:

```verilog
pc[9:2]
```

which is equivalent to:

```text
PC / 4
```

---

# Data Memory

```verilog
reg [31:0] data_mem [0:255];
```

- 256 words
- each word = 32 bits
- total size = 1 KB

Memory access:

```verilog
assign mem_data = data_mem[alu_result[9:2]];
```

---

# Effective Address Computation

For load/store instructions:

```assembly
lw x5, 0(x1)
sw x3, 4(x2)
```

The ALU computes:

```text
effective address = base register + offset
```

This result is a byte address.

To access word memory correctly, the address is divided by 4 using:

```verilog
alu_result[9:2]
```

---

# Memory Initialization

Instruction memory is initialized with NOP instructions:

```verilog
32'h00000013
```

Data memory is initialized with zeros to avoid undefined simulation behavior.