# ============================================================
# 轮询仲裁器 Simulation Makefile
# ============================================================
# 依赖: fix_base_arbiter.v (../../fix_arbiter/rtl/)
#
# Usage:
#   make        : compile and run simulation
#   make sim    : compile and run simulation
#   make wave   : open waveform in GTKWave
#   make clean  : remove generated files
# ============================================================

# ---- Source files ----
RTL        = ../rtl/round_robin_arbiter.v
RTL_DEP    = ../../fix_arbiter/rtl/fix_base_arbiter.v
TB         = ../tb/tb_round_arbiter.v
SRCS       = $(RTL) $(RTL_DEP) $(TB)

# ---- Top-level module ----
TOP  = tb_round_arbiter

# ---- Output files ----
OUT  = simv
VCD  = wave.vcd

# ---- Tools ----
IV      = iverilog
VVP     = vvp
GTKWAVE = gtkwave

# ---- IV flags ----
IVFLAGS = -g2012

# ============================================================
# Targets
# ============================================================

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
