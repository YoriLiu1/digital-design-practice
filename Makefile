# ========================================
# Digital IC Design Practice - Universal Simulation Makefile
# ========================================

# Module selection (default: async_fifo)
MODULE ?= async_fifo

# Directories
RTL_DIR  = rtl/$(MODULE)
TB_DIR   = tb/$(MODULE)
SIM_DIR  = sim/$(MODULE)

# Tool settings
VCS      = vcs
VERDI    = verdi
VCS_OPTS = -sverilog -debug_all -timescale=1ns/1ps

# Find source files
RTL_FILES = $(wildcard $(RTL_DIR)/*.v)
TB_FILES  = $(wildcard $(TB_DIR)/*.v)

# Default target
all: compile run

# Compile
compile:
@echo "========================================="
@echo "Compiling module: $(MODULE)"
@echo "========================================="
mkdir -p $(SIM_DIR)
$(VCS) $(VCS_OPTS) $(RTL_FILES) $(TB_FILES) -o $(SIM_DIR)/simv

# Run simulation
run:
@echo "Running simulation: $(MODULE)"
cd $(SIM_DIR) && ./simv

# View waveform
wave:
$(VERDI) -ssf $(SIM_DIR)/*.fsdb &

# Clean all simulation files
clean:
rm -rf sim/*

# List all available modules
list:
@echo "Available modules:"
@ls -d rtl/*/ 2>/dev/null | sed 's/rtl\///;s/\///'

# Help
help:
@echo "Usage:"
@echo "  make MODULE=async_fifo all    - Simulate async FIFO"
@echo "  make MODULE=sync_fifo all     - Simulate sync FIFO"
@echo "  make MODULE=crc all           - Simulate CRC"
@echo "  make list                     - List all modules"
@echo "  make clean                    - Clean all simulation files"
@echo ""
@echo "Targets:"
@echo "  all      - Compile and run"
@echo "  compile  - Compile only"
@echo "  run      - Run simulation only"
@echo "  wave     - Open waveform viewer"
@echo "  clean    - Remove simulation files"
@echo "  list     - Show available modules"
@echo "  help     - Show this message"

.PHONY: all compile run wave clean list help
