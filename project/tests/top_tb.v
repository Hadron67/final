module top_tb #(
    parameter MEM_FILE = "mmu.bin",
    parameter SIZE = 8 * 1024 * 1024
);
    localparam CLK_PERIOD = 100;
    localparam CYCLE = 10;

    localparam CMD_READ  = 8'd1;
    localparam CMD_WRITE = 8'd2;
    localparam CMD_PRINT = 8'd3;
    localparam CMD_HLT   = 8'd4;

    reg clk, res, tx;
    reg [7:0] cmd, printChar;
    reg [31:0] addr, writeData;
    reg [7:0] mem[0:SIZE - 1];
    wire rx;
    integer file, i;

    top #(.CLK(1), .BAUD_RATE(100000)) uut (
        .clk(clk),
        .res_n(~res),
        .tx(rx),
        .rx(tx)
    );

    task uartRx;
        output [7:0] data;
        integer i;
        begin
            #(CYCLE * CLK_PERIOD);
            for(i = 0; i < 8; i = i + 1)begin
                #(CYCLE * CLK_PERIOD / 2);
                data[i] = rx;
                #(CYCLE * CLK_PERIOD / 2);
            end
            #(CYCLE * CLK_PERIOD);
        end
    endtask

    task uartTx;
        input [7:0] data;
        integer i;
        begin
            tx = 0;
            #(CYCLE * CLK_PERIOD);
            for(i = 0; i < 8; i = i + 1) begin
                tx = data[i];
                #(CYCLE * CLK_PERIOD);
            end
            tx = 1;
            #(CYCLE * CLK_PERIOD);
        end
    endtask

    always begin
        wait(~rx);
        uartRx(cmd);
        // $display("command 0x%x", cmd);
        if(cmd == CMD_HLT) begin
            $display({`FONT_GREEN, "exit command received, exit.", `FONT_END});
            $dumpflush;
            $stop;
        end
        else if(cmd == CMD_PRINT) begin
            uartRx(printChar);
            $write("%c", printChar);
            // $display("char: %c (0x%x)", printChar, printChar);
        end
        else begin
            uartRx(addr[7:0]);
            uartRx(addr[15:8]);
            uartRx(addr[23:16]);
            uartRx(addr[31:24]);
            case(cmd)
                CMD_READ: begin
                    uartTx(mem[addr + 3]);
                    uartTx(mem[addr + 2]);
                    uartTx(mem[addr + 1]);
                    uartTx(mem[addr]);
                end
                CMD_WRITE: begin
                    uartRx(writeData[7:0]);
                    uartRx(writeData[15:8]);
                    uartRx(writeData[23:16]);
                    uartRx(writeData[31:24]);
                    {mem[addr], mem[addr + 1], mem[addr + 2], mem[addr + 3]} = writeData;
                end
            endcase
        end
    end

    always begin
        #(CLK_PERIOD / 2);
        clk <= ~clk;
    end

    initial begin
        $dumpfile({`OUT_DIR, "/top_tb.vcd"});
        $dumpvars(0, uut);
        file = $fopen({`ELF_DIR, "/mmu_test/mmu_test.bin"}, "rb");
        i = $fread(mem, file);
        $fclose(file);
        tx = 1;
        clk = 0;
        res = 0;
        #(CLK_PERIOD / 2);
        res = 1;
        #(CLK_PERIOD / 2);
        res = 0;
    end
endmodule