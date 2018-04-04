module DummyMem(
    input wire clk,
    DataBus.slave db,
    input wire res
);
    logic [31:0] mem[127:0];
    logic [31:0] dataOut, dataIn;

    assign dataIn = db.dataOut;
    assign db.ready = 1'b1; // always be ready
    assign db.dataIn = db.write ? 32'bzzzz : dataOut;
    always @(posedge clk or posedge res) begin
        if(res) begin
        
        end else begin
            if(db.write) begin
                $display("write memory %x to address %x", dataIn, db.addr);
                mem[db.addr[11:2]] <= dataIn;
            end else if(db.read) begin
                $display("read memory at address %x, data: %x", db.addr, mem[db.addr[11:2]]);
                dataOut <= mem[db.addr[11:2]];
            end
        end
    end
    initial begin
        // mem[0] = 32'b000000_00000_00000_00001_00000_100000;//add $1,$0,$0
        // mem[0] = {OpCode:PSOP_I, 5'd0, 5'd0, 5'd1, 5'b0, Func::ADD}; //add $1, $0, $0
        mem[0] = {OpCode::ADDI, 5'd0, 5'd1, 16'd64}; //addi $1, $0, 64
        // mem[1] = 32'b100011_00001_00010_0000000000000000;  //lw $2,0($1)
        mem[1] = {OpCode::LW, 5'd1, 5'd2, 16'd0};
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
    logic clk1, clk, res, clkEnable;
    int count;
    DataBus db();
    IMMU mmuIt();
    
    CPUCore uut(
        .clk(clk),
        .res(res),
        .db(db),
        .mmu(mmuIt)
    );
    DummyMem mem(
        .clk(clk),
        .res(res),
        .db(db)
    );
    initial begin
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
            $stop;
            break;
        end else
            count <= count + 1;
        clk1 <= ~clk1;
        if(clkEnable)
            clk <= clk1;
        #10;
    end
endmodule