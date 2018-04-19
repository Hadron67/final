`include "font.vh"
`include "DataBus.vh"

`timescale 1ns/1ns
module DummyMem #(
    parameter MEM_SIZE = 4096 // 4K
) (
    input wire clk, res,
    input wire [31:0] db_dataOut, db_addr,
    input wire `MEM_ACCESS_T db_accessType,
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
                    
                    if(db_addr == CMD_ADDR_HLT)
                        hlt <= 1'b1;
                    else if(db_addr == CMD_ADDR_WRITE_CHAR)
                        $write("%c", dataIn[7:0]);
                    else
                        case(db_memLen)
                            `MEM_LEN_B: begin
                                mem[db_addr] <= dataIn[7:0];
                                `ifdef DEBUG_DISPLAY
                                $display("write byte %x to address %x", dataIn[7:0], db_addr);
                                `endif
                            end
                            `MEM_LEN_H: begin
                                {mem[db_addr], mem[db_addr + 1]} <= dataIn[15:0];
                                `ifdef DEBUG_DISPLAY
                                $display("write half word %x to address %x", dataIn[15:0], db_addr);
                                `endif
                            end
                            `MEM_LEN_W: begin
                                {mem[db_addr], mem[db_addr + 1], mem[db_addr + 2], mem[db_addr + 3]} <= dataIn;
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
        file = $fopen({`ELF_DIR, "/mmu_test/mmu_test.bin"}, "rb");
        i = $fread(mem, file);
        $fclose(file);
    end
endmodule

module mmu_cpu_tb();
    reg clk, res;
    wire [31:0] db_dataOut, db_addr;
    wire `MEM_ACCESS_T db_accessType;
    wire `MEM_LEN db_memLen;
    wire db_ready;
    wire [31:0] db_dataIn;
    wire hlt;

    CPU_MMU uut (
        //     input wire clk, res,

        // input wire [31:0] db_dataIn,
        // output wire [31:0] db_dataOut, db_addr,
        // output reg [31:0] vAddr,
        // input wire db_ready,
        // output wire `MEM_ACCESS_T db_accessType,
        // output wire `MEM_LEN db_memLen
    );
endmodule