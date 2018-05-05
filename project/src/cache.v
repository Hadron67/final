`include "DataBus.vh"
module Cache #(
    parameter BLOCK_ADDR_WIDTH = 4,   // 16 blocks
    parameter INBLOCK_ADDR_WIDTH = 10 // 1K
) (
    input wire clk, res,
    input wire [31:0] pAddr, vAddr,

    input wire `MEM_ACCESS db_accessType,
    input wire `MEM_LEN db_memLen,

    input wire [31:0] dbOut_dataIn, dbOut_ready,
    output wire [31:0] dbOut_addr, dbOut_dataOut,
    output wire dbOut_re, dbOut_we
);
    localparam BLOCK_COUNT = 1 << BLOCK_ADDR_WIDTH;
    localparam BLOCK_SIZE = 1 << INBLOCK_ADDR_WIDTH;
    
    localparam S_RES        = 3'd0;
    localparam S_IDLE       = 3'd1;
    localparam S_CHK_HIT    = 3'd2;
    localparam S_LOAD_BLOCK = 3'd3;
    localparam S_WRITE_BACK = 3'd4;

    reg [2:0] state, nextState;
    reg `MEM_ACCESS accessTypeLatch;
    reg `MEM_LEN memLenLatch;
    wire [BLOCK_ADDR_WIDTH - 1:0] index;
    reg [BLOCK_ADDR_WIDTH - 1:0] indexLatch;
    wire [INBLOCK_ADDR_WIDTH - 1:0] inBlockAddr;
    reg [31:0] pAddrLatch, vAddrLatch, dataWrite;
    wire [33:0] tagOut;
    reg [33:0] tagIn;
    wire [31:0] dataOut;
    reg [31:0] dataIn;
    wire dirt, valid, hit;
    wire [31:0] pAddrTag;
    
    assign index = state == S_RES ? indexLatch : vAddr[INBLOCK_ADDR_WIDTH + BLOCK_ADDR_WIDTH - 1:INBLOCK_ADDR_WIDTH];
    assign inBlockAddr = vAddr[INBLOCK_ADDR_WIDTH - 1:0];
    assign dirt = tagOut[33];
    assign valid = tagOut[32];
    assign pAddrTag = tagOut[31:0];
    assign hit = valid && (pAddrLatch == pAddrTag);

    always @* begin
        if(state == S_RES)
            tagIn = 0;
        else if(nextState == S_LOAD_BLOCK)
            tagIn = {1'b0, 1'b1, pAddrLatch};
        else 
            tagIn = 34'dx;
    end
    always @* begin
        if(state == S_LOAD_BLOCK && dbOut_ready)
            dataIn = dbOut_dataIn;
        else if(state == S_CHK_HIT && hit)
            dataIn = dataWrite;
        else
            dataIn = 32'dx;
    end
    always @* begin
        case(state)
            S_RES: nextState = indexLatch == BLOCK_ADDR_WIDTH - 1 ? S_IDLE : S_RES;
            S_IDLE: nextState = db_accessType != `MEM_ACCESS_NONE ? S_CHK_HIT : S_IDLE;
            S_CHK_HIT:
                if(hit)
                    nextState = S_IDLE;
                else
                    case(accessTypeLatch)
                        `MEM_ACCESS_X: nextState = S_LOAD_BLOCK;
                        `MEM_ACCESS_R: nextState = S_LOAD_BLOCK;
                        `MEM_AC
                    endcase
        endcase
    end

    Ram #(.WIDTH(32), .ADDR_WIDTH(BLOCK_ADDR_WIDTH + INBLOCK_ADDR_WIDTH - 2), .TAG("DataRam")) dataRam (
        .clk(clk),
        .res(res),
        .re(nextState == S_CHK_HIT),
        .addr({index, inBlockAddr[INBLOCK_ADDR_WIDTH - 1:2]}),
        .dataOut(dataOut),
        .dataIn(dataIn)
    );

    Ram #(.WIDTH(34), .ADDR_WIDTH(BLOCK_ADDR_WIDTH), .TAG("TagRam")) tagRam (
        .clk(clk),
        .res(res),
        .re(nextState == S_CHK_HIT),
        .we(state == S_RES),
        .addr(index),
        .dataOut(tagOut),
        .dataIn(tagIn)
    );

    always @(posedge clk or posedge res) begin
        if(res) begin
            state <= S_RES;
            indexLatch <= 0;
        end
        else begin
            if(state == S_RES)
                indexLatch <= indexLatch + 1;
            if(nextState == S_CHK_HIT) begin
                pAddrLatch <= pAddr;
                vAddrLatch <= vAddr;
                accessTypeLatch <= db_accessType;
                memLenLatch <= db_memLen;
            end
            state <= nextState;
        end
    end

endmodule // Cache