TC = mips-linux-gnu
CC = $(TC)-gcc
CXX = $(TC)-g++
AS = $(TC)-as
LD = $(TC)-ld
OBJCOPY = $(TC)-objcopy
ASFLAGS = -msoft-float -mips32 -O0
CFLAGS = -fno-stack-protector -O0 -mno-abicalls -fno-pic -msoft-float
CXXFLAGS = $(CFLAGS) -fno-exceptions
OBJ = $(SOURCE:%=build/%.o)

LDFLAGS := -nostartfiles -Tlinker.ld

all: $(TARGET_NAME).bin
$(TARGET_NAME).elf: $(OBJ) linker.ld
	$(LD) $(LDFLAGS) $(OBJ) -o $@
%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
build/%.S.o: %.S
	$(AS) $(ASFLAGS) -o $@ $<
build/%.c.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
build/%.cc.o: %.cc
	$(CXX) $(CXXFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	$(RM) *.hex *.o *.bin *.elf build/*