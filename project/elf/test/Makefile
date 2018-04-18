SOURCE=\
test.S \
test.c

OBJ=$(SOURCE:%=%.o)

all: test.bin
test.elf: $(OBJ)
	$(LD) $(LDFLAGS) $(OBJ) -o $@

sinclude ../Makefile
