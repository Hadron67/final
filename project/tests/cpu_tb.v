`include "opcode.vh"
`include "DataBus.vh"
`include "font.vh"
`include "log.vh"
`timescale 1ns/1ns
module DummyMem #(
    parameter MEM_SIZE = 2048
) (
    input wire clk, res,
    input wire [31:0] db_dataOut, db_addr,
    input wire `MEM_ACCESS_T db_accessType,
    input wire `MEM_LEN db_memLen,
    input wire db_signed,
    output wire db_ready,
    output wire [31:0] db_dataIn,
    output reg hlt
);
    reg [7:0] mem[MEM_SIZE - 1:0];
    reg [31:0] dataOut;
    reg [31:0] temp;
    wire [31:0] dataIn;
    wire [7:0] r_b;
    wire [15:0] r_h;
    wire [31:0] r_w;

    assign dataIn = db_dataOut;
    assign db_ready = 1'b1; // always be ready
    assign db_dataIn = dataOut;
    assign r_b = mem[db_addr];
    assign r_h = {mem[db_addr], mem[db_addr + 1]};
    assign r_w = {mem[db_addr], mem[db_addr + 1], mem[db_addr + 2], mem[db_addr + 3]};

    always @(posedge clk or posedge res) begin
        if(res) begin
        
        end else begin
            case(db_accessType)
                `MEM_ACCESS_R: begin
                    $display("read memory at address %x, data: %x", db_addr, r_w);
                    dataOut <= r_w;
                end
                `MEM_ACCESS_W: begin
                    $display("write memory %x to address %x", dataIn, db_addr);
                    if(db_addr == 32'hbfffffff)
                        hlt <= 1'b1;
                    else
                        {mem[db_addr], mem[db_addr + 1], mem[db_addr + 2], mem[db_addr + 3]} <= dataIn;
                end
                `MEM_ACCESS_X: begin
                    $display(`FONT_YELLOW("execute memory at address %x, data: %x"), db_addr, r_w);
                    dataOut <= r_w;
                end
            endcase
        end
    end
    integer file;
    integer i;
    initial begin
        hlt = 1'b0;
        file = $fopen({`ELF_DIR, "/test/test.bin"}, "rb");
        i = $fread(mem, file);
        $fclose(file);
    end
endmodule

module cpu_tb();
    localparam CNT = 50;
    reg clk1, clk, res, clkEnable;
    integer count;
    wire hlt;

    wire [31:0] db_dataIn, db_dataOut, db_addr; 
    wire `MEM_ACCESS_T db_accessType;
    wire `MEM_LEN db_memLen;
    wire db_ready, db_signed;
    
    CPUCore uut(
        .clk(clk),
        .res(res),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_ready(db_ready),
        .db_accessType(db_accessType),
        .db_memLen(db_memLen),
        .db_signed(db_signed)
    );
    DummyMem mem(
        .clk(clk),
        .res(res),
        .hlt(hlt),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_ready(db_ready),
        .db_accessType(db_accessType),
        .db_memLen(db_memLen),
        .db_signed(db_signed)
    );
    MMU m();
    initial begin
        $dumpfile({`OUT_DIR, "/cpu_tb.vcd"}); 
        $dumpvars(0, uut);
        $dumpvars(0, mem);
        clk = 0;
        clk1 = 0;
        count = 0;
        res = 0;
        clkEnable = 0;

        #100;
        res = 1;
        #100;
        res = 0;
        #200;
        clkEnable = 1;
    end
    always begin
        if(hlt) begin
            $display(`FONT_GREEN("exit command received, exit."));
            $dumpflush;
            $stop();
        end 
        clk1 <= ~clk1;
        if(clkEnable)
            clk <= clk1;
        #1000;
    end
endmodule