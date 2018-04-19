TC = mips-linux-gnu
CC = $(TC)-gcc
CXX = $(TC)-g++
AS = $(TC)-as
LD = $(TC)-ld
OBJCOPY = $(TC)-objcopy
CFLAGS = -fno-stack-protector -O0 -mno-abicalls -fno-pic
CXXFLAGS = $(CFLAGS) -fno-exceptions

LDFLAGS := -nostartfiles -Tlinker.ld

all: $(TARGET_NAME).bin
$(TARGET_NAME).elf: $(OBJ) linker.ld
	$(LD) $(LDFLAGS) $(OBJ) -o $@
%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
%.S.o: %.S
	$(AS) -mips32 -O0 -o $@ $<
%.c.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
%.cc.o: %.cc
	$(CXX) $(CXXFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	$(RM) *.hex *.o *.bin