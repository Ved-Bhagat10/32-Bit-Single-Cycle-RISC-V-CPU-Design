module cpu (
    input clk,
    input reset
);

    // PC wires
    wire [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_four;

    // Instruction memory
    wire [31:0] instruction;
    reg [31:0] inst_mem [0:255];

    // Instruction fields
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [2:0] func3;
    wire [6:0] func7;

    // Control signals
    wire regf_w;
    wire [1:0] alu_op;
    wire alu_src;
    wire [2:0] imm_sel;
    wire mem_w;
    wire mem_r;
    wire [1:0] result_src;
    wire jump;
    wire branch;

    // Immediate
    wire [31:0] imm_out;

    // Register file
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] write_data;

    // ALU
    wire [31:0] alu_in1;
    wire [31:0] alu_in2;
    wire [31:0] alu_result;
    wire [3:0] alu_ctrl;
    wire zero;
    wire carry;
    wire overflow;

    // Memory
    wire [31:0] mem_data;
    reg [31:0] data_mem [0:255];

    // PC control
    wire [31:0] branch_target;
    wire [31:0] jump_target;
    wire [31:0] jalr_target;
    wire branch_taken;

    integer i, j;

    initial begin
        for(j = 0; j < 256; j = j + 1)
            inst_mem[j] = 32'h00000013;

        for(i = 0; i < 256; i = i + 1)
            data_mem[i] = 32'b0;
    end

    assign pc_plus_four = pc + 32'd4;

    pc pc_unit(
        .clk(clk),
        .reset(reset),
        .next_pc(pc_next),
        .pc(pc)
    );

    assign instruction = inst_mem[pc[9:2]];

    assign opcode = instruction[6:0];
    assign rd     = instruction[11:7];
    assign func3  = instruction[14:12];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign func7  = instruction[31:25];

    ctrl_unit cu_unit(
        .opcode(opcode),
        .regf_w(regf_w),
        .alu_op(alu_op),
        .alu_src(alu_src),
        .imm_sel(imm_sel),
        .mem_w(mem_w),
        .mem_r(mem_r),
        .result_src(result_src),
        .jump(jump),
        .branch(branch)
    );

    imm_gen imm_gen_unit(
        .inst(instruction),
        .imm_sel(imm_sel),
        .imm_out(imm_out)
    );

    regf regf_unit(
        .clk(clk),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .write_en(regf_w),
        .rd1(rd1),
        .rd2(rd2)
    );

    assign alu_in1 = (opcode == 7'd23) ? pc : rd1;
    assign alu_in2 = alu_src ? imm_out : rd2;

    alu_ctrl_unit alu_ctrl_unit_mod(
        .opcode(opcode),
        .func7(func7),
        .func3(func3),
        .alu_op(alu_op),
        .alu_ctrl(alu_ctrl)
    );

    alu alu_unit(
        .a(alu_in1),
        .b(alu_in2),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(zero),
        .carry(carry),
        .overflow(overflow)
    );

    assign mem_data = mem_r ? data_mem[alu_result[9:2]] : 32'b0;

    always @(posedge clk) begin
        if(mem_w)
            data_mem[alu_result[9:2]] <= rd2;
    end

    assign write_data =
        (result_src == 2'b00) ? alu_result   :
        (result_src == 2'b01) ? mem_data     :
        (result_src == 2'b10) ? pc_plus_four :
                                imm_out;

    assign branch_taken =
        branch && (
            (func3 == 3'b000 && zero) ||
            (func3 == 3'b001 && !zero) ||
            (func3 == 3'b100 && ($signed(rd1) <  $signed(rd2))) ||
            (func3 == 3'b101 && ($signed(rd1) >= $signed(rd2))) ||
            (func3 == 3'b110 && (rd1 <  rd2)) ||
            (func3 == 3'b111 && (rd1 >= rd2))
        );

    assign branch_target = pc + imm_out;
    assign jump_target   = pc + imm_out;
    assign jalr_target   = (rd1 + imm_out) & ~32'd1;

    assign pc_next =
        branch_taken ? branch_target :
        jump ? ((opcode == 7'd103) ? jalr_target : jump_target) :
        pc_plus_four;

endmodule

