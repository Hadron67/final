#!/usr/bin/env python

from struct import *
import serial
import sys
import logging

CMD_READ     = 0x1
CMD_WRITE    = 0x2
CMD_PRINT    = 0x3
CMD_HLT      = 0x4

class FirmwareWrapper:
    def __init__(self, str):
        self._str = str
    
    def __getitem__(self, i):
        if i >= len(self._str):
            return ['\x00']
        else:
            return self._str[i]
    

port = serial.Serial('/dev/ttyUSB0', 9600)
port.parity = serial.PARITY_NONE

logging.basicConfig(format = ('%(levelname)s: '
                            + '[%(relativeCreated)d] '
                            + '%(message)s'),
                    level = logging.INFO)

def getWord():
    return ord(port.read()) | ord(port.read()) << 8 | ord(port.read()) << 16 | ord(port.read()) << 24

def putWord(word):
    word = word[3] + word[2] + word[1] + word[0]
    port.write(word)

firmware = ''
with open(sys.argv[1], 'rb') as file:
    firmware = [i for i in file.read()]

printBuff = ''
while(1):
    cmd = ord(port.read())
    if cmd == CMD_READ:
        addr = getWord()
        data = firmware[addr:addr + 4]
        logging.debug(("read memory at 0x%x, data 0x" % addr) + ''.join(['%02x' % ord(i) for i in data]))
        putWord(FirmwareWrapper(data))
    elif cmd == CMD_WRITE:
        addr = getWord()
        data = getWord()
        logging.debug("write memory to 0x%x, data 0x%x" % (addr, data))
        firmware[addr] = pack('B', (data >> 24) & 0xff)
        firmware[addr + 1] = pack('B', (data >> 16) & 0xff)
        firmware[addr + 2] = pack('B', (data >> 8) & 0xff)
        firmware[addr + 3] = pack('B', data & 0xff)
    elif cmd == CMD_PRINT:
        char = port.read()
        if char == '\n':
            logging.info("output: " + printBuff)
            printBuff = ''
        else:
            printBuff += char
    elif cmd == CMD_HLT:
        logging.info("exit command received, exit")
        break
    else:
        logging.warn("unknown command 0x%x" % cmd)