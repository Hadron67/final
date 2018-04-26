`include "opcode.vh"
`include "DataBus.vh"
`include "font.vh"
`include "log.vh"
`timescale 1ns/1ns
module DummyMem #(
    parameter MEM_SIZE = 4096 // 4K
) (
    input wire clk, res,
    input wire [31:0] db_dataOut, db_addr,
    input wire `MEM_ACCESS db_accessType,
    input wire `MEM_LEN db_memLen,
    output wire db_ready,
    output wire [31:0] db_dataIn,
    output reg hlt
);
    localparam CMD_ADDR_HLT        = 32'ha0000000;
    localparam CMD_ADDR_WRITE_CHAR = 32'ha0000001;

    reg [7:0] mem[MEM_SIZE - 1:0];
    reg [31:0] dataOut;
    reg [31:0] temp;
    wire [31:0] dataIn, convertedAddr;
    wire [31:0] r_b, r_h, r_w;
    wire cmd_hlt, cmd_writeChar;

    assign dataIn = db_dataOut;
    assign db_ready = 1'b1; // always be ready
    assign db_dataIn = dataOut;
    assign convertedAddr = {1'b0, db_addr[30:0]};
    assign cmd_hlt = db_addr == CMD_ADDR_HLT;
    assign cmd_writeChar = db_addr == CMD_ADDR_WRITE_CHAR;
    assign r_b = {{24{1'b0}}, mem[convertedAddr]};
    assign r_h = {{16{1'b0}}, mem[convertedAddr], mem[convertedAddr + 1]};
    assign r_w = {mem[convertedAddr], mem[convertedAddr + 1], mem[convertedAddr + 2], mem[convertedAddr + 3]};

    always @(posedge clk or posedge res) begin
        if(res) begin
        
        end else begin
            case(db_accessType)
                `MEM_ACCESS_R: begin
                    case(db_memLen)
                        `MEM_LEN_B: begin
                            `ifdef DEBUG_DISPLAY
                            $display("read byte at address %x, data: %x", db_addr, r_b);
                            `endif
                            dataOut <= r_b;
                        end
                        `MEM_LEN_H: begin
                            `ifdef DEBUG_DISPLAY
                            $display("read half word at address %x, data: %x", db_addr, r_h);
                            `endif
                            dataOut <= r_h;
                        end
                        `MEM_LEN_W: begin
                            `ifdef DEBUG_DISPLAY
                            $display("read word at address %x, data: %x", db_addr, r_w);
                            `endif
                            dataOut <= r_w;
                        end
                    endcase
                end
                `MEM_ACCESS_W: begin
                    
                    if(cmd_hlt)
                        hlt <= 1'b1;
                    else if(cmd_writeChar)
                        $write("%c", dataIn[7:0]);
                    else
                        case(db_memLen)
                            `MEM_LEN_B: begin
                                mem[convertedAddr] <= dataIn[7:0];
                                `ifdef DEBUG_DISPLAY
                                $display("write byte %x to address %x", dataIn[7:0], db_addr);
                                `endif
                            end
                            `MEM_LEN_H: begin
                                {mem[convertedAddr], mem[convertedAddr + 1]} <= dataIn[15:0];
                                `ifdef DEBUG_DISPLAY
                                $display("write half word %x to address %x", dataIn[15:0], db_addr);
                                `endif
                            end
                            `MEM_LEN_W: begin
                                {mem[convertedAddr], mem[convertedAddr + 1], mem[convertedAddr + 2], mem[convertedAddr + 3]} <= dataIn;
                                `ifdef DEBUG_DISPLAY
                                $display("write word %x to address %x", dataIn, db_addr);
                                `endif
                            end
                        endcase
                end
                `MEM_ACCESS_X: begin
                    `ifdef DEBUG_DISPLAY
                    $display(`FONT_YELLOW("execute memory at address %x, data: %x"), db_addr, r_w);
                    `endif
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
    wire `MEM_ACCESS db_accessType;
    wire `MEM_LEN db_memLen;
    wire db_ready;
    
    CPUCore uut(
        .clk(clk),
        .res(res),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_ready(db_ready),
        .db_accessType(db_accessType),
        .db_memLen(db_memLen)
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
        .db_memLen(db_memLen)
    );
    MMU m();
    initial begin
        $dumpfile({`OUT_DIR, "/cpu_tb.vcd"}); 
        $dumpvars(0, uut);
        $dumpvars(0, mem);
        $display("--------------------------------------------");
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
            $display("--------------------------------------------");
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