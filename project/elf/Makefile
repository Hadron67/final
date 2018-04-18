TC=mips-linux-gnu
CC=$(TC)-gcc
AS=$(TC)-as
LD=$(TC)-ld
OBJCOPY=$(TC)-objcopy
MK_DIR := $(abspath $(lastword $(MAKEFILE_LIST)))
PWD = $(MK_DIR:%Makefile=%)

LDFLAGS := -T$(PWD)/link.ld


%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
%.S.o: %.S
	$(AS) -o $@ $<
%.c.o: %.c
	$(CC) -c -o $@ $<

.PHONY: clean
clean:
	$(RM) *.hex *.o *.bin