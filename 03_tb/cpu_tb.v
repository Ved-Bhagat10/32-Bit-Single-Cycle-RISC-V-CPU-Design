`timescale 1ns/1ps

module cpu_tb;

reg clk;
reg reset;

cpu uut (
    .clk(clk),
    .reset(reset)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;

    #10;
    reset = 0;

    // basic arithmetic
    uut.inst_mem[0] = 32'h00500093; // addi x1, x0, 5
    uut.inst_mem[1] = 32'h00A00113; // addi x2, x0, 10
    uut.inst_mem[2] = 32'h002081B3; // add x3, x1, x2 -> x3 = 15

    // memory
    uut.inst_mem[3] = 32'h00302023; // sw x3, 0(x0)
    uut.inst_mem[4] = 32'h00002203; // lw x4, 0(x0) -> x4 = 15

    // branch taken
    uut.inst_mem[5] = 32'h00418463; // beq x3, x4, +8
    uut.inst_mem[6] = 32'h06F00293; // addi x5, x0, 111 skipped
    uut.inst_mem[7] = 32'h07B00313; // addi x6, x0, 123

    // jump
    uut.inst_mem[8] = 32'h008003EF; // jal x7, +8
    uut.inst_mem[9] = 32'h0DE00413; // addi x8, x0, 222 skipped
    uut.inst_mem[10] = 32'h14D00493; // addi x9, x0, 333

    #200;
    $stop;
end

endmodule