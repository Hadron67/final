interface SDRAM_Bus #(
	parameter BA_WIDTH            =  2,
	parameter ROW_WIDTH           =  13,
	parameter COL_WIDTH           =  9,
	parameter DQ_WIDTH            =  16,
	parameter DQM_WIDTH           =  SDR_DQ_WIDTH/8,
	parameter ADDR_WIDTH          =  SDR_BA_WIDTH + SDR_ROW_WIDTH + SDR_COL_WIDTH,
	parameter BURST_WIDTH         =  9
);
    logic                    cke,           //clock enable
	logic                    cs_n,          //chip select
	logic                    ras_n,         //row select
	logic                    cas_n,         //colum select
	logic                    we_n,          //write enable
	logic [BA_WIDTH - 1:0]   ba,            //bank address
	logic [ROW_WIDTH - 1:0]  addr,          //address
	logic [DQM_WIDTH - 1:0]  dqm,           //data mask
    logic [DQ_WIDTH - 1: 0]  dq             //data
    modport master (
        output cke, output cs_n, output ras_n, output cas_n, output we_n, output ba, output addr, output dqm,
        inout dq
    );
    modport slave (
        input cke, input cs_n, input ras_n, input cas_n, input we_n, input ba, input addr, input dqm,
        inout dq
    );
endinterface

interface SDRAM_Burst #(
	parameter BA_WIDTH            =  2,
	parameter ROW_WIDTH           =  13,
	parameter COL_WIDTH           =  9,
	parameter DQ_WIDTH            =  16,
	parameter DQM_WIDTH           =  SDR_DQ_WIDTH/8,
	parameter ADDR_WIDTH          =  SDR_BA_WIDTH + SDR_ROW_WIDTH + SDR_COL_WIDTH,
	parameter BURST_WIDTH         =  9
);
    logic                       req,        // request
    logic [DQ_WIDTH - 1:0]      data,       // data
    logic [BURST_WIDTH - 1:0]   len,        // data length, ahead of wr_burst_req
    logic [ADDR_WIDTH - 1:0]    addr,       // base address of sdram write buffer
    logic                       valid,      // data request/valid, 1 clock ahead
    logic                       finish      // data is end
    modport readIn(
        input req, input len, input addr,
        output data, output valid, output finish
    );
    modport readOut(
        output req, output len, output addr,
        input data, input valid, input finish
    );
    modport writeIn(
        input req, input len, input addr, input data,
        output valid, output finish
    );
    modport writeOut(
        output req, output len, output addr, output data,
        input valid, input finish
    );
endinterface