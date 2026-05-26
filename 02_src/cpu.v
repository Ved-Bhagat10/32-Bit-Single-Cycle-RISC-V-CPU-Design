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

module alu_ctrl_unit(
    input [6:0] opcode,
    input [6:0] func7,
    input [2:0] func3,
    input [1:0] alu_op,
    output reg [3:0] alu_ctrl
);

always @(*) begin
    alu_ctrl=4'b0000;
    case(alu_op)
    2'b00:alu_ctrl=4'b0000; // ADD for load/store instructions
    2'b01:alu_ctrl=4'b0001; // SUB for compare
    2'b10:begin
        case(opcode)
        7'd51:begin  // R-Type Instructions
            case({func7[5],func3})
            {1'b0,3'b000}:alu_ctrl=4'b0000;  // add (add)
            {1'b1,3'b000}:alu_ctrl=4'b0001;  // subtract (sub)
            {1'b0,3'b001}:alu_ctrl=4'b0101;  // shift left logical (sll)
            {1'b0,3'b010}:alu_ctrl=4'b1001;  // set less than (slt)
            {1'b0,3'b011}:alu_ctrl=4'b1000;  // set less than (unsigned) (sltu)
            {1'b0,3'b100}:alu_ctrl=4'b0100;  // xor (xor)
            {1'b0,3'b101}:alu_ctrl=4'b0110;  // shift right logical (srl)
            {1'b1,3'b101}:alu_ctrl=4'b0111;  // shift right arithmetic (sra)
            {1'b0,3'b110}:alu_ctrl=4'b0011;  // or (or)
            {1'b0,3'b111}:alu_ctrl=4'b0010;  // and (and)
            default:alu_ctrl=4'b0;
            endcase
        end
        7'd19:begin  // I-Type Instructions
            case(func3)
            3'b000:alu_ctrl=4'b0000;  // add (addi)
            3'b001:alu_ctrl=4'b0101;  // shift left logical (slli)
            3'b010:alu_ctrl=4'b1001;  // set less than (slti)
            3'b011:alu_ctrl=4'b1000;  // set less than (unsigned) (sltiu)
            3'b100:alu_ctrl=4'b0100;  // xor (xori)
            3'b101:begin
                if(func7[5]==1'b0)begin
                    alu_ctrl=4'b0110;  // shift right logical (srli)
                end else begin
                    alu_ctrl=4'b0111;  // shift right arithmetic immediate (srai)
                end
            end
            3'b110:alu_ctrl=4'b0011;  // or (ori)
            3'b111:alu_ctrl=4'b0010;  // and (andi)
            default:alu_ctrl=4'b0;
            endcase
        end
        default:alu_ctrl=4'b0000;
        endcase
    end
    endcase
end

endmodule


module alu (
    input [31:0] a,b,
    input [3:0] alu_ctrl,
    output reg [31:0] result,
    output zero,
    output reg carry,
    output reg overflow
);

always @(*) begin
    carry=1'b0;
    overflow=1'b0;
    case(alu_ctrl)
    4'b0000:begin // add
        {carry,result}=a+b;
        overflow=(a[31]==b[31])&&(a[31]!=result[31]);
    end
    4'b0001:begin // sub
        {carry,result}=a-b;
        overflow=(a[31]!=b[31])&&(a[31]!=result[31]);
    end
    4'b0010:result=a&b; // and
    4'b0011:result=a|b; // or
    4'b0100:result=a^b;// xor
    4'b0101:result=a<<b[4:0]; // shift left logical
    4'b0110:result=a>>b[4:0]; // shift right logical
    4'b0111:result=($signed(a)>>>b[4:0]); // shift right arithmetic
    4'b1000:result=(a<b)?32'd1:32'd0; // set if less than (unsigned)
    4'b1001:result=(($signed(a))<($signed(b)))?32'd1:32'd0; // set less than
    default:result=32'b0;
    endcase
end

assign zero=(result==32'b0);

endmodule



module regf(
    input clk,
    input [4:0] rs1,rs2,rd,
    input [31:0] write_data,
    input write_en,
    output [31:0] rd1,rd2
);

reg [31:0] register_file [31:0];
integer i;

always @(posedge clk) begin
    if((write_en==1) && (rd!=5'b0)) begin
        register_file[rd] <= write_data;
    end
end

initial begin
    for(i=0; i<32;i++)begin
        register_file[i]= 32'b0;
    end
end

assign rd1=(rs1==5'b0)?32'b0:register_file[rs1];
assign rd2=(rs2==5'b0)?32'b0:register_file[rs2];

endmodule

module imm_gen(
    input [31:0] inst,
    input [2:0] imm_sel,
    output reg [31:0] imm_out
);

always @(*) begin
    case(imm_sel)
    3'b000:imm_out={{20{inst[31]}},inst[31:20]};                                     // I-Type
    3'b001:imm_out={{20{inst[31]}},inst[31:25],inst[11:7]};                          // S-Type
    3'b010:imm_out={{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};    // B-Type
    3'b011:imm_out={inst[31:12],12'b0};                                              // U-Type
    3'b100:imm_out={{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};  // J-Type
    default:imm_out=32'b0;
    endcase
end

endmodule

module ctrl_unit(
    input [6:0] opcode,
    output reg regf_w,
    output reg [1:0] alu_op,
    output reg alu_src,
    output reg [2:0] imm_sel,
    output reg mem_w,
    output reg mem_r,
    output reg [1:0] result_src,
    output reg jump,
    output reg branch
);

always @(*) begin
    regf_w=1'b0;
    alu_op=2'b0;
    alu_src=1'b0;
    imm_sel=3'b000;
    mem_w=1'b0;
    mem_r=1'b0;
    result_src=2'b0;
    jump=1'b0;
    branch=1'b0;

    case(opcode)
    7'd51:begin  // R-Type
        regf_w=1'b1;
        alu_op=2'b10;
        alu_src=1'b0;
        result_src=2'b00;
    end

    7'd19:begin  // I-Type
        regf_w=1'b1;
        alu_op=2'b10;
        imm_sel=3'b000;
        alu_src=1'b1;
        result_src=2'b00;
    end

    7'd3:begin  // I-Type Load
        regf_w=1'b1;
        alu_src=1'b1;
        imm_sel=3'b000;
        mem_r=1'b1;
        result_src=2'b01;
        alu_op=2'b00;
    end

    7'd35:begin // S-Type
        mem_w=1'b1;
        alu_op=2'b00;
        alu_src=1'b1;
        imm_sel=3'b001;
    end

    7'd23:begin // U-Type auipc
        regf_w=1'b1;
        alu_src=1'b1;
        alu_op=2'b00;
        imm_sel=3'b011;
        result_src=2'b00;
    end

    7'd55:begin // U-Type lui
        alu_op=2'b00;
        imm_sel=3'b011;
        regf_w=1'b1;
        alu_src=1'b1;
        result_src=2'b11;
    end

    7'd99:begin  // B-Type
        alu_op=2'b01;
        alu_src=1'b0;
        branch=1'b1;
        imm_sel=3'b010;
        result_src=2'b00;
    end

    7'd103:begin // I-Type jalr
        imm_sel=3'b000;
        result_src=2'b10;
        regf_w=1'b1;
        alu_src=1'b1;
        jump=1'b1;
        alu_op=2'b00;
    end

    7'd111:begin  // J-Type jal
        regf_w=1'b1;
        jump=1'b1;
        result_src=2'b10;
        imm_sel=3'b100;
    end

    default:begin  // default case
        regf_w=1'b0;
        alu_op=2'b00;
        alu_src=1'b0;
        imm_sel=3'b000;
        mem_w=1'b0;
        mem_r=1'b0;
        result_src=2'b00;
        jump=1'b0;
        branch=1'b0;
    end
    endcase
end

endmodule

module pc(
    input clk, 
    input reset,
    input [31:0] next_pc,
    output reg [31:0] pc
);

always @(posedge clk or posedge reset) begin
    if(reset) begin
        pc<=32'b0;
    end else begin
        pc<=next_pc;
    end
end

endmodule