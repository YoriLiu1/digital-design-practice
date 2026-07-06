# ============================================================
# 串并转换 (6-bit) Simulation Makefile
# ============================================================
# Usage:
#   make        : compile and run simulation
#   make wave   : open waveform in GTKWave
#   make clean  : remove generated files
# ============================================================

RTL  = ../rtl/Serial2Parallel.v
TB   = ../tb/tb_Serial2Parallel.v
SRCS = $(RTL) $(TB)

TOP  = tb_Serial2Parallel
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
