`include "DataBus.vh"
`include "font.vh"
module Cache #(
    parameter TAG = "cache",
    parameter BLOCK_ADDR_WIDTH = 4,   // 16 blocks
    parameter INBLOCK_ADDR_WIDTH = 10 // 1K
) (
    input wire clk, res,
    output wire ready,

    input wire [31:0] pAddr, vAddr, db_dataOut,
    output wire [31:0] db_dataIn,
    output wire db_ready,
    input wire `MEM_ACCESS db_accessType,

    input wire [31:0] dbOut_dataIn, 
    input wire dbOut_ready,
    output wire [31:0] dbOut_addr, dbOut_dataOut,
    output wire dbOut_re, dbOut_we
);
    localparam TAG_WIDTH = 32 - BLOCK_ADDR_WIDTH - INBLOCK_ADDR_WIDTH;
    localparam TAG_ENTRY_WIDTH = TAG_WIDTH + 2;
    localparam BLOCK_COUNT = 1 << BLOCK_ADDR_WIDTH;
    localparam BLOCK_SIZE = 1 << INBLOCK_ADDR_WIDTH;
    
    localparam S_RES           = 3'd0;
    localparam S_IDLE          = 3'd1;
    localparam S_CHK_HIT       = 3'd2;
    localparam S_LOAD_BLOCK    = 3'd3;
    localparam S_WRITE_BACK    = 3'd4;
    localparam S_READ_FIRST_W  = 3'd5;
    localparam S_WRITE_LAST_W  = 3'd6;
    localparam S_LOAD_LAST_W   = 3'd7;

    reg [2:0] state, nextState;
    reg `MEM_ACCESS accessTypeLatch;
    wire [BLOCK_ADDR_WIDTH - 1:0] index, indexLatch;
    reg [BLOCK_ADDR_WIDTH - 1:0] resetIndex;
    wire [INBLOCK_ADDR_WIDTH - 1:0] vAddr_inBlockAddr;
    reg [31:0] pAddrLatch;
    wire [TAG_WIDTH - 1:0] tagOut_tag, pAddrLatch_tag; 
    reg [TAG_WIDTH - 1:0] db_dataOut_tag, writeTagLatch;
    reg [INBLOCK_ADDR_WIDTH - 1:0] inBlockAddr, db_dataOut_inBlockAddr, dataWriteAddr;
    wire [INBLOCK_ADDR_WIDTH - 1:0] addedInBlockAddr;
    reg [31:0] vAddrLatch, dataWrite;
    wire [TAG_ENTRY_WIDTH - 1:0] tagOut;
    reg [TAG_ENTRY_WIDTH - 1:0] tagIn;
    wire [31:0] dataOut;
    reg [31:0] dataIn;
    wire tagOut_dirty, tagOut_valid, hit;
    wire accessMem, countEnd, memEnd, writeDirtBit;
    
    assign ready = state != S_RES;
    assign index = state == S_RES ? resetIndex : vAddr[INBLOCK_ADDR_WIDTH + BLOCK_ADDR_WIDTH - 1:INBLOCK_ADDR_WIDTH];
    assign indexLatch = vAddrLatch[INBLOCK_ADDR_WIDTH + BLOCK_ADDR_WIDTH - 1:INBLOCK_ADDR_WIDTH];
    assign vAddr_inBlockAddr = vAddr[INBLOCK_ADDR_WIDTH - 1:0];
    // assign tagOut_dirty = tagOut[TAG_WIDTH + 1];
    // assign tagOut_valid = tagOut[TAG_WIDTH];
    // assign tagOut_tag = tagOut[TAG_WIDTH - 1:0];
    assign {tagOut_valid, tagOut_dirty, tagOut_tag} = tagOut;
    assign pAddrLatch_tag = pAddrLatch[31:32 - TAG_WIDTH];
    assign hit = tagOut_valid && (pAddrLatch_tag == tagOut_tag);

    assign countEnd = resetIndex == BLOCK_COUNT - 1;
    // assign memEnd = inBlockAddr == BLOCK_SIZE - 1;
    assign {memEnd, addedInBlockAddr} = inBlockAddr + 4;
    assign accessMem = db_accessType != `MEM_ACCESS_NONE;
    assign writeDirtBit = accessTypeLatch == `MEM_ACCESS_W && hit && !tagOut_dirty;

    assign db_dataIn = dataOut;
    assign db_ready = state == S_IDLE || (state == S_CHK_HIT && hit && !writeDirtBit);

    assign dbOut_re = nextState == S_LOAD_BLOCK;
    assign dbOut_we = nextState == S_WRITE_BACK || nextState == S_WRITE_LAST_W;
    assign dbOut_dataOut = dataOut;
    assign dbOut_addr = {db_dataOut_tag, indexLatch, db_dataOut_inBlockAddr};

    always @* begin
        if(state == S_RES)
            tagIn = 0;
        else if(state == S_CHK_HIT) begin
            if(writeDirtBit) begin
                tagIn = {1'b1, 1'b1, tagOut_tag};
            end
            else if(!hit) begin
                tagIn = {1'b1, 1'b0, pAddrLatch_tag};
            end 
        end
        else 
            tagIn = 34'dx;
    end
    always @* begin
        if(state == S_LOAD_BLOCK && dbOut_ready)
            dataIn = dbOut_dataIn;
        else if(state == S_CHK_HIT && hit)
            dataIn = db_dataOut;
        else
            dataIn = 32'dx;
    end
    always @* begin
        case(nextState)
            S_IDLE: dataWriteAddr = state == S_CHK_HIT ? vAddr_inBlockAddr : 'dx;
            S_CHK_HIT: dataWriteAddr = vAddr_inBlockAddr;
            S_LOAD_BLOCK,
            S_LOAD_LAST_W: dataWriteAddr = inBlockAddr;
            S_WRITE_BACK: dataWriteAddr = addedInBlockAddr;
            S_READ_FIRST_W: dataWriteAddr = 0;
            default: dataWriteAddr = 'dx;
        endcase
    end
    always @* begin
        case(nextState)
            S_LOAD_LAST_W,
            S_LOAD_BLOCK: db_dataOut_tag = pAddrLatch_tag;
            S_WRITE_LAST_W,
            S_WRITE_BACK: db_dataOut_tag = writeTagLatch;
            default: db_dataOut_tag = 'dx;
        endcase
    end
    always @* begin
        case(nextState)
            S_LOAD_BLOCK: db_dataOut_inBlockAddr = state == S_CHK_HIT || state == S_WRITE_BACK ? 0 : addedInBlockAddr;
            S_WRITE_LAST_W,
            S_WRITE_BACK: db_dataOut_inBlockAddr = inBlockAddr;
            default: db_dataOut_inBlockAddr = 'dx;
        endcase
    end
    always @* begin
        case(state)
            S_RES: nextState = countEnd ? S_IDLE : S_RES;
            S_IDLE: nextState = accessMem ? S_CHK_HIT : S_IDLE;
            S_CHK_HIT:
                if(hit) begin
                    if(writeDirtBit)
                        nextState = S_IDLE;
                    else 
                        nextState = accessMem ? S_CHK_HIT : S_IDLE;
                end
                else
                    nextState = tagOut_valid && tagOut_dirty ? S_READ_FIRST_W : S_LOAD_BLOCK;
            S_LOAD_BLOCK: nextState = memEnd ? S_LOAD_LAST_W : S_LOAD_BLOCK;
            S_WRITE_BACK: nextState = memEnd && dbOut_ready ? S_WRITE_LAST_W : S_WRITE_BACK;
            S_READ_FIRST_W: nextState = S_WRITE_BACK;
            S_LOAD_LAST_W: nextState = S_CHK_HIT;
            S_WRITE_LAST_W: nextState = dbOut_ready ? S_LOAD_BLOCK : S_WRITE_LAST_W;
        endcase
    end
    Ram #(.WIDTH(32), .ADDR_WIDTH(BLOCK_ADDR_WIDTH + INBLOCK_ADDR_WIDTH - 2), .TAG({TAG, "/DataRam"})) dataRam (
        .clk(clk),
        .res(res),
        .re(nextState == S_CHK_HIT || nextState == S_WRITE_BACK || nextState == S_READ_FIRST_W),
        .we(accessTypeLatch == `MEM_ACCESS_W && state == S_CHK_HIT && hit || state == S_LOAD_BLOCK && dbOut_ready),
        .readAddr({index, dataWriteAddr[INBLOCK_ADDR_WIDTH - 1:2]}),
        .writeAddr({index, dataWriteAddr[INBLOCK_ADDR_WIDTH - 1:2]}),
        .dataOut(dataOut),
        .dataIn(dataIn)
    );

    Ram #(.WIDTH(TAG_ENTRY_WIDTH), .ADDR_WIDTH(BLOCK_ADDR_WIDTH), .TAG({TAG, "/TagRam"})) tagRam (
        .clk(clk),
        .res(res),
        .re(nextState == S_CHK_HIT),
        .we(state == S_RES || state == S_CHK_HIT && (writeDirtBit || !hit)),
        .writeAddr(index),
        .readAddr(index),
        .dataOut(tagOut),
        .dataIn(tagIn)
    );

    always @(posedge clk or posedge res) begin
        if(res) begin
            state <= S_RES;
            resetIndex <= 0;
            inBlockAddr <= 0;
        end
        else begin
            if(state == S_RES) begin
                resetIndex <= countEnd ? 0 : resetIndex + 1;
            end
            if(nextState == S_CHK_HIT && state != S_LOAD_LAST_W) begin
                pAddrLatch <= pAddr;
                vAddrLatch <= vAddr;
                accessTypeLatch <= db_accessType;
            end

            if(nextState == S_LOAD_BLOCK) begin
                if(state == S_CHK_HIT) begin
                    inBlockAddr <= 0;
                end
                else if(dbOut_ready) begin
                    inBlockAddr <= addedInBlockAddr;
                end
            end
            else if(nextState == S_READ_FIRST_W) begin
                inBlockAddr <= 'd0;
            end
            else if(nextState == S_WRITE_BACK) begin
                if(dbOut_ready) begin
                    inBlockAddr <= addedInBlockAddr;
                end
            end

            if(state == S_CHK_HIT)
                writeTagLatch <= tagOut_tag;
            
            state <= nextState;
        end
    end

    `ifdef DEBUG_DISPLAY

    always @(posedge clk) begin
        if(state == S_RES && countEnd) begin
            $display({`FONT_GREEN, "[", TAG, "]Initialization done.", `FONT_END});
        end
        if(state == S_CHK_HIT) begin
            if(hit)
                $display({`FONT_GREEN, "[", TAG, "]hit for address 0x%x", `FONT_END}, vAddrLatch);
            else begin
                $display({`FONT_RED, "[", TAG, "]missed for address 0x%x", `FONT_END}, vAddrLatch);
                if(tagOut_valid && tagOut_dirty) begin
                    $display({"[", TAG, "]valid and dirty bit of block 0x%x is on, writting back"}, indexLatch);
                end
            end
        end
    end

    `endif
endmodule // Cache