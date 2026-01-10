#------------------------------------------------------------------------------
# Directories
#------------------------------------------------------------------------------
DESIGN_DIR    = ../design
DESIGN_FILES  = $(DESIGN_DIR)/fifo.sv
INTERFACE_FILE = ../components/apb_fifo_interface.sv
TB_FILE       = ../tb_top.sv

# Include directories
INC_DIRS      = +incdir+../components +incdir+../sequences +incdir+../tests

#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
TEST_NAME = basic_operation_test
VERBOSITY = UVM_MEDIUM
#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII

#------------------------------------------------------------------------------
# Available Tests:
# - reset_test
# - basic_operation_test
# - fifo_clear_test
# - fifo_enable_test
# - overflow_test
# - underflow_test
# - threshold_test
# - random_test
# - stress_test
#------------------------------------------------------------------------------

# VCS Flags
VCS_FLAGS = -full64 -sverilog -ntb_opts uvm-1.2 +define+VCS -debug_access+all $(INC_DIRS)

# Simulation Executable
SIMV = simv


# Run-time flags
RUN_FLAGS = +UVM_TESTNAME=$(TEST_NAME) +UVM_VERBOSITY=$(VERBOSITY) -l sim.log

#------------------------------------------------------------------------------
# Targets
# ------------------------------------------------------------------------------

.PHONY: all compile run clean coverage waves

all: clean compile run

compile:
	@echo "============================================"
	@echo "Compiling with VCS..."
	@echo "============================================"
	vcs $(VCS_FLAGS) $(DESIGN_FILES) $(INTERFACE_FILE) $(TB_FILE) -o $(SIMV)

run:
	@echo "============================================"
	@echo "Running test: $(TEST_NAME)"
	@echo "============================================"
	./$(SIMV) $(RUN_FLAGS)

coverage:
	@echo "============================================"
	@echo "Running with coverage enabled..."
	@echo "============================================"
	vcs $(VCS_FLAGS) -cm line+cond+fsm+tgl+branch $(DESIGN_FILES) $(INTERFACE_FILE) $(TB_FILE) -o $(SIMV)
	./$(SIMV) $(RUN_FLAGS) -cm line+cond+fsm+tgl+branch
	urg -dir $(SIMV).vdb -report coverage_report

waves:
	dve -vpd vcdplus.vpd &

clean:
	rm -rf $(SIMV) $(SIMV).daidir csrc
	rm -rf *.log *.vpd *.fsdb *.vcd
	rm -rf DVEfiles urgReport coverage_report
	rm -rf ucli.key vc_hdrs.h
	rm -rf *.vdb