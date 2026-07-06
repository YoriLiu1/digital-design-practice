# ============================================================
# 50% 占空比三分频 Simulation Makefile
# ============================================================
# Usage:
#   make        : compile and run simulation
#   make wave   : open waveform in GTKWave
#   make clean  : remove generated files
# ============================================================

RTL  = ../rtl/div3.v
TB   = ../tb/tb_div3.v
SRCS = $(RTL) $(TB)

TOP  = tb_div3
OUT  = simv
VCD  = wave.vcd

IV      = iverilog
VVP     = vvp
GTKWAVE = gtkwave
IVFLAGS = -g2012

.PHONY: all sim wave clean

all: sim

sim: $(OUT)
	@echo "=== Running simulation ==="
	$(VVP) $(OUT)
	@echo "=== Simulation done ==="

$(OUT): $(SRCS)
	@echo "=== Compiling ==="
	$(IV) $(IVFLAGS) -o $(OUT) -s $(TOP) $(SRCS)
	@echo "=== Compile done ==="

wave: $(VCD)
	$(GTKWAVE) $(VCD) &

$(VCD): $(OUT)
	$(VVP) $(OUT)

clean:
	rm -f $(OUT) $(VCD)
