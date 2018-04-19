SOURCE=\
test.S \
test.c \
io.c

OBJ=$(SOURCE:%=%.o)

all: test.bin
test.elf: $(OBJ) linker.ld
	$(LD) $(LDFLAGS) $(OBJ) -o $@

sinclude ../Makefile
