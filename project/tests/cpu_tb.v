`include "opcode.vh"
`include "DataBus.vh"
`include "font.vh"

module DummyMem(
    input wire clk, res,
    input wire [31:0] db_dataOut, db_addr,
    input wire [1:0] db_accessType,
    output wire db_ready,
    output wire [31:0] db_dataIn
);
    reg [31:0] mem[127:0], dataOut;
    wire [31:0] dataIn;

    assign dataIn = db_dataOut;
    assign db_ready = 1'b1; // always be ready
    assign db_dataIn = dataOut;

    always @(posedge clk or posedge res) begin
        if(res) begin
        
        end else begin
            case(db_accessType)
                `MEM_ACCESS_R: begin
                    $display("read memory at address %x, data: %x", db_addr, mem[db_addr[11:2]]);
                    dataOut <= mem[db_addr[11:2]];
                end
                `MEM_ACCESS_W: begin
                    $display("write memory %x to address %x", dataIn, db_addr);
                    mem[db_addr[11:2]] <= dataIn;
                end
                `MEM_ACCESS_X: begin
                    $display(`FONT_YELLOW("execute memory at address %x, data: %x"), db_addr, mem[db_addr[11:2]]);
                    dataOut <= mem[db_addr[11:2]];
                end
            endcase
        end
    end
    initial begin
        // mem[0] = 32'b000000_00000_00000_00001_00000_100000;//add $1,$0,$0
        // mem[0] = {OpCode:PSOP_I, 5'd0, 5'd0, 5'd1, 5'b0, Func::ADD}; //add $1, $0, $0
        mem[0] = {`OPCODE_ADDI, 5'd0, 5'd1, 16'd64}; //addi $1, $0, 64
        // mem[1] = 32'b100011_00001_00010_0000000000000000;  //lw $2,0($1)
        mem[1] = {`OPCODE_LW, 5'd1, 5'd2, 16'd0};
        mem[2] = 32'b100011_00001_00011_0000000000000100;  //lw $3,4($1)
        mem[3] = 32'b000000_00010_00011_00010_00000_100000;//add $2,$2,$3
        mem[4] = 32'b100011_00001_00011_0000000000001000;  //lw $3,8($1)
        mem[5] = 32'b000100_00010_00011_0000000000000001;  //beq $2,$3,1
        mem[6] = 32'b101011_00001_00000_0000000000001100;  //sw $0,12($1)
        mem[7] = 32'b101011_00001_00010_0000000000001100;  //sw $2,12($1)

        mem[16] = 32'd4;
        mem[17] = 32'd5;
        mem[18] = 32'd9;
    end
endmodule

module cpu_tb();
    localparam CNT = 50;
    reg clk1, clk, res, clkEnable;
    integer count;

    wire [31:0] db_dataIn, db_dataOut, db_addr; 
    wire [1:0] db_accessType;
    wire db_ready;
    
    CPUCore uut(
        .clk(clk),
        .res(res),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_ready(db_ready),
        .db_accessType(db_accessType)
    );
    DummyMem mem(
        .clk(clk),
        .res(res),
        .db_dataIn(db_dataIn),
        .db_dataOut(db_dataOut),
        .db_addr(db_addr),
        .db_ready(db_ready),
        .db_accessType(db_accessType)
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

        #10;
        res = 1;
        #10;
        res = 0;
        #20;
        clkEnable = 1;
    end
    always begin
        if(count == CNT) begin
            $dumpflush();
            $stop();
        end else
            count <= count + 1;
        clk1 <= ~clk1;
        if(clkEnable)
            clk <= clk1;
        #10;
    end
endmodule