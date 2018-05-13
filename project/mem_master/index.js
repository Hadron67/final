'use strict';
var SerialPort = require('serialport');
var fs = require('fs');

var firmware = fs.readFileSync(process.argv[2]);
var port = new SerialPort(process.argv[1], {
    baudRate: 9600
});
port.set({
    dsr: true
});

// port.on('readable', function(data){
//     console.log("data: " + data.hexSlice());
// });