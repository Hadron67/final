SOURCE_DIR=src

SOURCE_FILES=\
ALU.v \
Controller.v \
CP0RegNum.v \
CPU.v \
InstructionFetcher.v \
mmu.v \
CP0Regs.v \
RegFile.v \
random32.v \
encoder.v \
CPU_MMU.v

SOURCE=$(SOURCE_FILES:%=$(SOURCE_DIR)/%)

INC_DIR=src/
IV=iverilog
VVP=vvp -n

SIM_SOURCE_DIR=tests
SIM_OUTDIR=simulation/vvp

SIM_TARGETS=\
cpu \
mmu \
encoder

default:
	@echo "You must specify what to run." && exit 1;

all: $(SIM_TARGETS:%=%_sim)

%_sim: $(SIM_OUTDIR)/%_tb.out
	$(VVP) $<

$(SIM_OUTDIR)/%_tb.out: $(SOURCE) $(SIM_SOURCE_DIR)/%_tb.v
	$(IV) -o $@ -s $(@:$(SIM_OUTDIR)/%.out=%) -I $(INC_DIR) -DOUT_DIR=\"$(SIM_OUTDIR)\" $(SOURCE) $(@:$(SIM_OUTDIR)/%.out=$(SIM_SOURCE_DIR)/%.v)

.SECONDARY: $(SIM_TARGETS:%=$(SIM_OUTDIR)/%_tb.out)
.PHONY: clean sandwitch default
clean:
	$(RM) $(SIM_OUTDIR)/*

sandwitch:
	@[ "`whoami`" = "root" ] && echo "Okay." || echo "What? Make it yourself."