`include "font.vh"
`include "DataBus.vh"

`timescale 1ns/1ns
module DummyMem #(
    parameter MEM_SIZE = 4096 // 4K
) (
    input wire clk, res,
    input wire [31:0] db_dataOut, db_addr, vAddr,
    input wire `MEM_ACCESS_T db_accessType,
    input wire `MEM_LEN db_memLen,
    input wire db_io,
    output wire db_ready,
    output wire [31:0] db_dataIn,
    output reg hlt
);
    localparam CMD_ADDR_HLT        = 32'd0;
    localparam CMD_ADDR_WRITE_CHAR = 32'd1;

    reg [7:0] mem[MEM_SIZE - 1:0];
    reg [31:0] dataOut;
    reg [31:0] temp;
    wire [31:0] dataIn;
    wire [31:0] r_b, r_h, r_w;

    assign dataIn = db_dataOut;
    assign db_ready = 1'b1; // always be ready
    assign db_dataIn = dataOut;
    assign r_b = {{24{1'b0}}, mem[db_addr]};
    assign r_h = {{16{1'b0}}, mem[db_addr], mem[db_addr + 1]};
    assign r_w = {mem[db_addr], mem[db_addr + 1], mem[db_addr + 2], mem[db_addr + 3]};

    always @(posedge clk or posedge res) begin
        if(res) begin
        
        end else begin
            case(db_accessType)
                `MEM_ACCESS_R: begin
                    case(db_memLen)
                        `MEM_LEN_B: begin
                            `ifdef DEBUG_DISPLAY
                            $display("read byte at address %x (%x), data: %x", db_addr, vAddr, r_b);
                            `endif
                            dataOut <= r_b;
                        end
                        `MEM_LEN_H: begin
                            `ifdef DEBUG_DISPLAY
                            $display("read half word at address %x (%x), data: %x", db_addr, vAddr, r_h);
                            `endif
                            dataOut <= r_h;
                        end
                        `MEM_LEN_W: begin
                            `ifdef DEBUG_DISPLAY
                            $display("read word at address %x (%x), data: %x", db_addr, vAddr, r_w);
                            `endif
                            dataOut <= r_w;
                        end
                    endcase
                end
                `MEM_ACCESS_W: begin
                    if(db_io) begin
                        if(db_addr == CMD_ADDR_HLT)
                            hlt <= 1'b1;
                        else if(db_addr == CMD_ADDR_WRITE_CHAR)
                            $write("%c", dataIn[7:0]);
                    end
                    else
                        case(db_memLen)
                            `MEM_LEN_B: begin
                                mem[db_addr] <= dataIn[7:0];
                                `ifdef DEBUG_DISPLAY
                                $display("write byte %x to address %x (%x)", dataIn[7:0], db_addr, vAddr);
                                `endif
                            end
                            `MEM_LEN_H: begin
                                {mem[db_addr], mem[db_addr + 1]} <= dataIn[15:0];
                                `ifdef DEBUG_DISPLAY
                                $display("write half word %x to address %x (%x)", dataIn[15:0], db_addr, vAddr);
                                `endif
                            end
                            `MEM_LEN_W: begin
                                {mem[db_addr], mem[db_addr + 1], mem[db_addr + 2], mem[db_addr + 3]} <= dataIn;
                                `ifdef DEBUG_DISPLAY
                                $display("write word %x to address %x (%x)", dataIn, db_addr, vAddr);
                                `endif
                            end
                        endcase
                end
                `MEM_ACCESS_X: begin
                    `ifdef DEBUG_DISPLAY
                    $display(`FONT_YELLOW("execute memory at address %x (%x), data: %x"), db_addr, vAddr, r_w);
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
        file = $fopen({`ELF_DIR, "/mmu_test/mmu_test.bin"}, "rb");
        i = $fread(mem, file);
        $fclose(file);
    end
endmodule

module mmu_cpu_tb();
    reg clk, res;
    wire [31:0] db_dataOut, db_addr, db_dataIn, vAddr;
    wire `MEM_ACCESS_T db_accessType;
    wire `MEM_LEN db_memLen;
    wire db_ready, db_io;
    wire hlt;
    reg enableclk;
    integer cnt;

    CPU_MMU uut (
        //     input wire clk, res,
        .clk(clk),
        .res(res),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_io(db_io),
        .vAddr(vAddr),
        .db_ready(db_ready),
        .db_accessType(db_accessType),
        .db_memLen(db_memLen)
    );

    DummyMem mem (
        .clk(clk),
        .res(res),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_io(db_io),
        .vAddr(vAddr),
        .db_ready(db_ready),
        .db_accessType(db_accessType),
        .db_memLen(db_memLen),
        .hlt(hlt)
    );

    initial begin
        $dumpfile({`OUT_DIR, "/mmu_cpu.vcd"});
        $dumpvars(0, uut);
        $display("------------------------------------------------");
        clk = 0;
        res = 0;
        cnt = 0;
        #100;
        res = 1;
        #100;
        res = 0;
    end

    always begin: clkDriver
        #100;
        if(hlt) begin
            $display("------------------------------------------------");
            $display(`FONT_GREEN("exit command received, exit."));
            $dumpflush;
            $stop;
        end 
        // else if(cnt >= 65535) begin
        //     $display("------------------------------------------------");
        //     $display(`FONT_GREEN("time's up, exit."));
        //     $dumpflush;
        //     $stop;
        // end
        clk <= ~clk;
        cnt <= cnt + 1;
    end


endmodule