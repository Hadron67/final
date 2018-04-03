module RegFile(
    input wire clk,
    input wire [4:0] addrA,
    input wire [4:0] addrB,
    input wire [4:0] addrWrite,
    input wire [31:0] writeData,
    input wire writeReg,
    
    output wire [31:0] outA,
    output wire [31:0] outB
);
    reg [31:0] regs[31:0];
    
    assign outA = addrA == 0 ? 0 : regs[addrA];
    assign outB = addrB == 0 ? 0 : regs[addrB];
    
    always @(posedge clk) begin
        if(writeReg && addrWrite != 0) begin
            regs[addrWrite] <= writeData;
            $display("written data (%d) to register $%d", writeData, addrWrite);
        end
    end

endmodule // RegFile