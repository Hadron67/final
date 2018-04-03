module SDRAMController #(
    parameter BA_WIDTH            =  2,
	parameter ROW_WIDTH           =  13,
	parameter COL_WIDTH           =  9,
	parameter DQ_WIDTH            =  16,
	parameter DQM_WIDTH           =  SDR_DQ_WIDTH/8,
	parameter ADDR_WIDTH          =  SDR_BA_WIDTH + SDR_ROW_WIDTH + SDR_COL_WIDTH,
	parameter BURST_WIDTH         =  9
) (
    input wire clk,
    input wire res,
    SDRAM_Burst.readIn read,
    SDRAM_Burst.writeIn write,
    SDRAM_Bus.master bus
);
    
endmodule