TC=mips-linux-gnu
CC=$(TC)-gcc
AS=$(TC)-as
LD=$(TC)-ld
OBJCOPY=$(TC)-objcopy
CFLAGS = -fno-stack-protector -O0
MK_DIR := $(abspath $(lastword $(MAKEFILE_LIST)))
PWD = $(MK_DIR:%Makefile=%)

LDFLAGS := -nostartfiles -Tlinker.ld

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
%.S.o: %.S
	$(AS) -mips32 -O0 -o $@ $<
%.c.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	$(RM) *.hex *.o *.bin