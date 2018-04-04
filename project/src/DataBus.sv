package MemType;
    typedef enum logic [2:0] {
        BYTE,
        WORD
    } MemType_t;
endpackage

import MemType::MemType_t;
interface DataBus;
    // The master prepare data on the raising edge, while the slave
    // process the data on the failing edge.
    logic [31:0] addr, dataIn, dataOut;
    logic read, write, ready;
    MemType_t memType;
    modport master(
        input ready, input dataIn,
        output addr, output read, output write, output memType, output dataOut
    );
    modport slave(
        output ready, output dataIn,
        input addr, input read, input write, input memType, input dataOut
    );
endinterface