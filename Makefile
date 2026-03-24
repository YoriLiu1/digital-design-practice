# ========================================
# Digital IC Design - Simulation Makefile
# ========================================

# Variables
RTL_FILE_LIST = rtl_files.txt
TB_FILE_LIST  = tb_files.txt
CLEAN_LIST    = clean_list.txt
FILE_LIST     = file.list

# Module selection (default: async_fifo)
MODULE ?= async_fifo

# Tool settings
VCS      = vcs
VERDI    = verdi
VCS_OPTS = -full64 -sverilog +v2k -debug_acc+all -fsdb +define+FSDB

# Directories
RTL_DIR = rtl/$(MODULE)
TB_DIR  = tb/$(MODULE)
SIM_DIR = sim/$(MODULE)

# ========================================
# File list generation
# ========================================

# Generate RTL file list (exclude testbench files)
rtls:
	@echo "Generating RTL file list for module: $(MODULE)"
	@find $(RTL_DIR) -type f -name '*.v' 2>/dev/null > $(RTL_FILE_LIST)
	@echo "Found $$(wc -l < $(RTL_FILE_LIST)) RTL files"

# Generate TB file list (only testbench files)
tbls:
	@echo "Generating TB file list for module: $(MODULE)"
	@find $(TB_DIR) -type f -name '*.v' -o -name '*.sv' 2>/dev/null > $(TB_FILE_LIST)
	@echo "Found $$(wc -l < $(TB_FILE_LIST)) TB files"

# Generate clean file list (files to remove)
fls:
	@echo "Generating clean file list..."
	@> $(CLEAN_LIST)  # Clear file first
	@find $(SIM_DIR) -name "*.log" 2>/dev/null >> $(CLEAN_LIST)
	@find $(SIM_DIR) -name "*.fsdb" 2>/dev/null >> $(CLEAN_LIST)
	@find $(SIM_DIR) -name "simv*" 2>/dev/null >> $(CLEAN_LIST)
	@find $(SIM_DIR) -name "csrc" 2>/dev/null >> $(CLEAN_LIST)
	@find . -name "*.vpd" 2>/dev/null >> $(CLEAN_LIST)
	@find . -name "verdiLog" 2>/dev/null >> $(CLEAN_LIST)
	@find . -name "*.key" 2>/dev/null >> $(CLEAN_LIST)
	@echo "Clean list generated"

# Generate file list for Verdi (all source files)
filelist:
	@echo "Generating file list for Verdi..."
	@> $(FILE_LIST)  # Clear file first
	@find ./rtl -name "*.v" 2>/dev/null >> $(FILE_LIST)
	@find ./rtl -name "*.sv" 2>/dev/null >> $(FILE_LIST)
	@find ./tb -name "*.v" 2>/dev/null >> $(FILE_LIST)
	@find ./tb -name "*.sv" 2>/dev/null >> $(FILE_LIST)
	@echo "File list generated"

# ========================================
# Build targets
# ========================================

# Prepare all file lists
prepare: rtls tbls

# Compile
cmp: prepare
	@echo "========================================="
	@echo "Compiling module: $(MODULE)"
	@echo "========================================="
	@mkdir -p $(SIM_DIR)
	$(VCS) $(VCS_OPTS) \
		$$(cat $(RTL_FILE_LIST)) \
		$$(cat $(TB_FILE_LIST)) \
		-o $(SIM_DIR)/simv \
		-l $(SIM_DIR)/com.log
	@echo "Compilation done. Log: $(SIM_DIR)/com.log"

# Run simulation
sim:
	@echo "========================================="
	@echo "Running simulation: $(MODULE)"
	@echo "========================================="
	@if [ -f $(SIM_DIR)/simv ]; then \
		cd $(SIM_DIR) && ./simv -l sim.log; \
	else \
		echo "Error: simv not found. Please run 'make cmp' first."; \
		exit 1; \
	fi

# Compile and run
all: cmp sim

# ========================================
# Utility targets
# ========================================

# Open waveform with Verdi
verdi: filelist
	@echo "Opening waveform with Verdi..."
	$(VERDI) -f $(FILE_LIST) -ssf $(SIM_DIR)/*.fsdb +nologo &

# Open waveform with DVE (VCS built-in)
dve:
	@echo "Opening waveform with DVE..."
	dve -vpd $(SIM_DIR)/*.vpd &

# Edit Makefile
m:
	vim Makefile

# Show help
help:
	@echo "========================================="
	@echo "Digital IC Design Simulation Makefile"
	@echo "========================================="
	@echo ""
	@echo "Usage:"
	@echo "  make MODULE=async_fifo all     - Compile and run"
	@echo "  make MODULE=async_fifo cmp     - Compile only"
	@echo "  make MODULE=async_fifo sim     - Run simulation only"
	@echo "  make MODULE=async_fifo verdi   - Open waveform with Verdi"
	@echo "  make MODULE=async_fifo dve     - Open waveform with DVE"
	@echo ""
	@echo "Other commands:"
	@echo "  make list                      - Show all modules"
	@echo "  make clean                     - Clean current module"
	@echo "  make cleanall                  - Clean all modules"
	@echo "  make filelist                  - Generate file list for Verdi"
	@echo "  make m                         - Edit this Makefile"
	@echo ""

# ========================================
# Clean targets
# ========================================

# Clean current module only
clean: fls
	@echo "Cleaning module: $(MODULE)"
	@if [ -f $(CLEAN_LIST) ]; then \
		cat $(CLEAN_LIST) | xargs -r rm -rf; \
	fi
	@rm -rf $(RTL_FILE_LIST) $(TB_FILE_LIST) $(CLEAN_LIST)
	@rm -rf $(SIM_DIR)
	@echo "Clean done"

# Clean all modules
cleanall:
	@echo "Cleaning all modules..."
	@rm -rf sim/*
	@rm -rf rtl_files.txt tb_files.txt clean_list.txt file.list
	@rm -rf simv* *.vpd verdiLog *.key
	@echo "All cleaned"

# ========================================
# List modules
# ========================================

# List all available modules
list:
	@echo "Available modules:"
	@ls -d rtl/*/ 2>/dev/null | sed 's/rtl\///;s/\///' | while read module; do \
		if [ -d "tb/$$module" ]; then \
			echo "  ✓ $$module"; \
		else \
			echo "  ○ $$module (no testbench)"; \
		fi \
	done

# ========================================
# Phony targets
# ========================================

.PHONY: rtls tbls fls prepare cmp sim all verdi dve m help clean cleanall list filelist
