# ============================================================
# 轮询仲裁器 (mask 法) Simulation Makefile
# ============================================================
# 实现: prefix-OR mask 法, 输出 binary index
# 不依赖 fix_base_arbiter
#
# Usage:
#   make        : compile and run simulation
#   make sim    : compile and run simulation
#   make wave   : open waveform in GTKWave
#   make clean  : remove generated files
# ============================================================

# ---- Source files ----
RTL  = ../rtl/round_robin_arbiter.v
TB   = ../tb/tb_round_arbiter.v
SRCS = $(RTL) $(TB)

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
