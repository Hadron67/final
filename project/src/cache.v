`include "DataBus.vh"
`include "font.vh"
module Cache #(
    parameter TAG = "cache",
    parameter ASSOC_ADDR_WIDTH = 0,
    parameter BLOCK_ADDR_WIDTH = 4,   // 16 blocks
    parameter INBLOCK_ADDR_WIDTH = 9  // 256B, or 16 instructions
) (
    input wire clk, res,
    output wire ready,

    input wire cachable,
    input wire [31:0] pAddr, vAddr, db_dataOut,
    output wire [31:0] db_dataIn,
    output wire db_ready,
    input wire `MEM_ACCESS db_accessType,

    input wire [31:0] dbOut_dataIn, 
    input wire dbOut_ready,
    output wire [31:0] dbOut_addr, dbOut_dataOut,
    output wire dbOut_re, dbOut_we
);
    localparam TAG_WIDTH = 32 - INBLOCK_ADDR_WIDTH;
    localparam TAG_ENTRY_WIDTH = TAG_WIDTH + 2;
    localparam BLOCK_COUNT = 1 << BLOCK_ADDR_WIDTH;
    localparam BLOCK_SIZE = 1 << INBLOCK_ADDR_WIDTH;

    localparam ASSOC_COUNT = 1 << ASSOC_ADDR_WIDTH;
    
    localparam S_RES               = 4'd0;
    localparam S_IDLE              = 4'd1;
    localparam S_CHK_HIT           = 4'd2;
    localparam S_LOAD_BLOCK        = 4'd3;
    localparam S_WRITE_BACK        = 4'd4;
    localparam S_READ_FIRST_W      = 4'd5;
    localparam S_WRITE_LAST_W      = 4'd6;
    localparam S_LOAD_LAST_W       = 4'd7;
    localparam S_LOAD_BLOCK_WAIT   = 4'd8;
    localparam S_WRITE_BACK_WAIT   = 4'd9;
    localparam S_WRITE_LAST_W_WAIT = 4'd10;

    reg [3:0] state, nextState;
    reg `MEM_ACCESS accessTypeLatch;
    wire [BLOCK_ADDR_WIDTH - 1:0] index, indexLatch;
    reg [BLOCK_ADDR_WIDTH - 1:0] resetIndex;
    wire [INBLOCK_ADDR_WIDTH - 1:0] vAddr_inBlockAddr;
    reg [31:0] pAddrLatch, db_dataOutLatch;
    wire [TAG_WIDTH - 1:0] tagOut_tag, pAddrLatch_tag, tagOut1_tag, tagOut2_tag; 
    reg [TAG_WIDTH - 1:0] db_dataOut_tag, writeTagLatch;
    reg [INBLOCK_ADDR_WIDTH - 1:0] inBlockAddr, db_dataOut_inBlockAddr, dataWriteAddr;
    wire [INBLOCK_ADDR_WIDTH - 1:0] addedInBlockAddr;
    reg [31:0] vAddrLatch, dataWrite;
    reg [TAG_ENTRY_WIDTH - 1:0] tagIn;
    wire [TAG_ENTRY_WIDTH - 1:0] tagOut, tagOut1, tagOut2;
    wire [31:0] dataOut, dataOut1, dataOut2;
    reg [31:0] dataIn;
    wire tagOut_dirty, tagOut_valid, hit, tagOut1_dirty, tagOut1_valid, tagOut2_dirty, tagOut2_valid, hit1, hit2;
    wire accessMem, countEnd, memEnd, writeDirtBit;
    wire whichEntry, hitEntry;
    reg victim;
    wire readReady;

    assign ready = state != S_RES;
    assign index = state == S_RES ? resetIndex : vAddr[INBLOCK_ADDR_WIDTH + BLOCK_ADDR_WIDTH - 1:INBLOCK_ADDR_WIDTH];
    assign indexLatch = vAddrLatch[INBLOCK_ADDR_WIDTH + BLOCK_ADDR_WIDTH - 1:INBLOCK_ADDR_WIDTH];
    assign vAddr_inBlockAddr = vAddr[INBLOCK_ADDR_WIDTH - 1:0];
    assign {tagOut1_valid, tagOut1_dirty, tagOut1_tag} = tagOut1;
    assign {tagOut2_valid, tagOut2_dirty, tagOut2_tag} = tagOut2;
    assign {tagOut_valid, tagOut_dirty, tagOut_tag} = tagOut;
    assign tagOut = whichEntry ? tagOut2 : tagOut1;
    assign dataOut = whichEntry ? dataOut2 : dataOut1;
    assign pAddrLatch_tag = pAddrLatch[31:32 - TAG_WIDTH];
    assign hit1 = tagOut1_valid && (pAddrLatch_tag == tagOut1_tag);
    assign hit2 = tagOut2_valid && (pAddrLatch_tag == tagOut2_tag);
    assign hit = hit1 || hit2;
    assign hitEntry = hit1 ? 1'b0 : hit2 ? 1'b1 : 1'bx;
    assign whichEntry = hit ? hitEntry : victim;
    assign readReady = dbOut_ready && (state == S_LOAD_BLOCK || state == S_LOAD_BLOCK_WAIT);

    assign countEnd = resetIndex == BLOCK_COUNT - 1;
    assign {memEnd, addedInBlockAddr} = inBlockAddr + 4;
    assign accessMem = cachable && db_accessType != `MEM_ACCESS_NONE;
    assign writeDirtBit = accessTypeLatch == `MEM_ACCESS_W && hit && !tagOut_dirty;

    assign db_dataIn = cachable ? dataOut : dbOut_dataIn;
    assign db_ready = cachable ? (state == S_IDLE || (state == S_CHK_HIT && hit && !writeDirtBit)) : dbOut_ready;

    assign dbOut_re = cachable ? (nextState == S_LOAD_BLOCK) : (db_accessType == `MEM_ACCESS_R || db_accessType == `MEM_ACCESS_X);
    assign dbOut_we = cachable ? (nextState == S_WRITE_BACK || nextState == S_WRITE_LAST_W) : (db_accessType == `MEM_ACCESS_W);
    assign dbOut_dataOut = cachable ? dataOut : db_dataOut;
    assign dbOut_addr = cachable ? {db_dataOut_tag, db_dataOut_inBlockAddr} : pAddr;

    always @* begin
        case({tagOut2_valid, tagOut1_valid})
            2'b00,
            2'b01: victim = 1'b1;
            2'b10: victim = 1'b0;
            2'b11: 
                case({tagOut2_dirty, tagOut1_dirty})
                    2'b00,
                    2'b01: victim = 1'b1;
                    2'b10: victim = 1'b0;
                    2'b11: victim = 1'b0; // TODO: random
                endcase
        endcase
    end
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
            else
                tagIn = 34'dx;
        end
        else 
            tagIn = 34'dx;
    end
    always @* begin
        if((state == S_LOAD_BLOCK || state == S_LOAD_BLOCK_WAIT) && dbOut_ready)
            dataIn = dbOut_dataIn;
        else if(state == S_CHK_HIT && hit)
            dataIn = db_dataOutLatch;
        else
            dataIn = 32'dx;
    end
    always @* begin
        case(nextState)
            S_IDLE: dataWriteAddr = state == S_CHK_HIT ? vAddr_inBlockAddr : 'dx;
            S_CHK_HIT: dataWriteAddr = vAddr_inBlockAddr;
            S_LOAD_BLOCK,
            S_LOAD_BLOCK_WAIT,
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
                    nextState = tagOut_dirty ? S_READ_FIRST_W : S_LOAD_BLOCK;
            S_LOAD_BLOCK,
            S_LOAD_BLOCK_WAIT: nextState = memEnd && dbOut_ready ? S_LOAD_LAST_W : (dbOut_ready ? S_LOAD_BLOCK : S_LOAD_BLOCK_WAIT);
            S_WRITE_BACK,
            S_WRITE_BACK_WAIT: nextState = memEnd && dbOut_ready ? S_WRITE_LAST_W : (dbOut_ready ? S_WRITE_BACK : S_WRITE_BACK_WAIT);
            S_READ_FIRST_W: nextState = S_WRITE_BACK;
            S_LOAD_LAST_W: nextState = S_CHK_HIT;
            S_WRITE_LAST_W,
            S_WRITE_LAST_W_WAIT: nextState = dbOut_ready ? S_LOAD_BLOCK : S_WRITE_LAST_W_WAIT;
        endcase
    end
    Ram #(.WIDTH(32), .ADDR_WIDTH(BLOCK_ADDR_WIDTH + INBLOCK_ADDR_WIDTH - 2), .TAG({TAG, "/DataRam1"})) dataRam1 (
        .clk(clk),
        .res(res),
        .re(nextState == S_CHK_HIT || nextState == S_WRITE_BACK || nextState == S_READ_FIRST_W),
        .we(~whichEntry && (accessTypeLatch == `MEM_ACCESS_W && state == S_CHK_HIT && hit || readReady)),
        .readAddr({index, dataWriteAddr[INBLOCK_ADDR_WIDTH - 1:2]}),
        .writeAddr({index, dataWriteAddr[INBLOCK_ADDR_WIDTH - 1:2]}),
        .dataOut(dataOut1),
        .dataIn(dataIn)
    );

    Ram #(.WIDTH(TAG_ENTRY_WIDTH), .ADDR_WIDTH(BLOCK_ADDR_WIDTH), .TAG({TAG, "/TagRam1"})) tagRam1 (
        .clk(clk),
        .res(res),
        .re(nextState == S_CHK_HIT),
        .we(state == S_RES || ~whichEntry && (state == S_CHK_HIT && (writeDirtBit || !hit))),
        .writeAddr(index),
        .readAddr(index),
        .dataOut(tagOut1),
        .dataIn(tagIn)
    );

    Ram #(.WIDTH(32), .ADDR_WIDTH(BLOCK_ADDR_WIDTH + INBLOCK_ADDR_WIDTH - 2), .TAG({TAG, "/DataRam2"})) dataRam2 (
        .clk(clk),
        .res(res),
        .re(nextState == S_CHK_HIT || nextState == S_WRITE_BACK || nextState == S_READ_FIRST_W),
        .we(whichEntry && (accessTypeLatch == `MEM_ACCESS_W && state == S_CHK_HIT && hit || readReady)),
        .readAddr({index, dataWriteAddr[INBLOCK_ADDR_WIDTH - 1:2]}),
        .writeAddr({index, dataWriteAddr[INBLOCK_ADDR_WIDTH - 1:2]}),
        .dataOut(dataOut2),
        .dataIn(dataIn)
    );

    Ram #(.WIDTH(TAG_ENTRY_WIDTH), .ADDR_WIDTH(BLOCK_ADDR_WIDTH), .TAG({TAG, "/TagRam2"})) tagRam2 (
        .clk(clk),
        .res(res),
        .re(nextState == S_CHK_HIT),
        .we(state == S_RES || whichEntry && (state == S_CHK_HIT && (writeDirtBit || !hit))),
        .writeAddr(index),
        .readAddr(index),
        .dataOut(tagOut2),
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
                db_dataOutLatch <= db_dataOut;
            end

            if(nextState == S_LOAD_BLOCK || nextState == S_LOAD_BLOCK_WAIT) begin
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
            else if(nextState == S_WRITE_BACK || nextState == S_WRITE_BACK_WAIT) begin
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
            $display({`FONT_GREEN, "[", TAG, "] Initialization done.", `FONT_END});
        end
        if(state == S_CHK_HIT) begin
            if(hit)
                $display({`FONT_GREEN, "[", TAG, "] hit for address 0x%x", `FONT_END}, vAddrLatch);
            else begin
                $display({`FONT_RED, "[", TAG, "] missed for address 0x%x (0x%x)", `FONT_END}, vAddrLatch, pAddrLatch);
                if(tagOut_valid && tagOut_dirty) begin
                    $display({"[", TAG, "] valid and dirty bit of block 0x%x is on, writting back"}, indexLatch);
                end
            end
        end
    end

    `endif
endmodule // Cache