SOURCE_DIR=src

SOURCE_FILES=\
ALU.v \
Controller.v \
CP0RegNum.v \
CPU.v \
InstructionFetcher.v \
mmu.v \
CP0Regs.v \
RegFile.v

SOURCE=$(SOURCE_FILES:%=$(SOURCE_DIR)/%)

INC_DIR=src/
IV=iverilog
VVP=vvp -n

SIM_SOURCE_DIR=tests
SIM_OUTDIR=simulation/vvp

all: cpu_sim

%_sim: %_tb
	$(VVP) $(SIM_OUTDIR)/$<.out

%_tb: $(SOURCE) $(SIM_SOURCE_DIR)/%_tb.v
	$(IV) -o $(SIM_OUTDIR)/$@.out -s $@ -I $(INC_DIR) -DOUT_DIR=\"$(SIM_OUTDIR)\" $(SOURCE) $(SIM_SOURCE_DIR)/$@.v

%_sim_clean:
	$(RM) $(@:%_sim_clean=%_tb).out $(@:%_sim_clean=%_tb).vcd

clean:
	$(RM) $(SIM_OUTDIR)/*