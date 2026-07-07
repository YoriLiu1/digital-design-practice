# ============================================================
# sync_fifo Simulation Makefile
# ============================================================
# Usage: make | make sim | make wave | make clean
# ============================================================

RTL  = ../rtl/sync_fifo.v
TB   = ../tb/tb_sync_fifo.v
SRCS = $(RTL) $(TB)
TOP  = tb_sync_fifo
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
