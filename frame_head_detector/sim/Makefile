# ============================================================
# 帧头检测器 Simulation Makefile
# ============================================================
# Usage:
#   make        : compile and run simulation
#   make sim    : compile and run simulation
#   make wave   : open waveform in GTKWave
#   make clean  : remove generated files
# ============================================================

# ---- Source files ----
RTL  = ../rtl/frame_head.v
TB   = ../tb/tb_frame_head.v
SRCS = $(RTL) $(TB)

# ---- Top-level module ----
TOP  = tb_frame_head

# ---- Output files ----
OUT  = simv
VCD  = tb_frame_head.vcd

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
