#------------------------------------------------------------------------------
# Directories
#------------------------------------------------------------------------------
TOP_DIR       = ..
DESIGN_DIR    = $(TOP_DIR)/design
COMP_DIR      = $(TOP_DIR)/components
TB_FILE       = $(TOP_DIR)/tb_top.sv

#------------------------------------------------------------------------------
# Source Files
#------------------------------------------------------------------------------
DESIGN_FILES  = $(DESIGN_DIR)/fifo.sv
TB_FILES      = $(TB_FILE)

#------------------------------------------------------------------------------
# Default Test
#------------------------------------------------------------------------------
TEST ?= full_coverage_test

#------------------------------------------------------------------------------
# Available Tests:
#   - reset_test          : Tests reset behavior
#   - basic_operation_test: Tests basic push/pop operations
#   - overflow_test       : Tests overflow conditions
#   - underflow_test      : Tests underflow conditions
#   - threshold_test      : Tests almost full/empty thresholds
#   - register_test       : Tests register read/write access
#   - random_test         : Random FIFO operations
#   - full_coverage_test  : Comprehensive coverage test
#   - stress_test         : High volume stress test
#   - back_to_back_test   : Rapid transaction test
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# VCS Flags
#------------------------------------------------------------------------------
VCS_FLAGS = -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm-1.2 +define+VCS -debug_access+all -l compile.log

#------------------------------------------------------------------------------
# Simulation Executable
#------------------------------------------------------------------------------
SIMV = simv

#------------------------------------------------------------------------------
# Run-time flags
#------------------------------------------------------------------------------
RUN_FLAGS = +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_MEDIUM -l sim_$(TEST).log

#------------------------------------------------------------------------------
# Targets
# ------------------------------------------------------------------------------

.PHONY: all compile run clean help coverage waves

all: compile run

#------------------------------------------------------------------------------
# Compile
#------------------------------------------------------------------------------
compile:
	@echo "============================================"
	@echo "Compiling with VCS..."
	@echo "============================================"
	vcs $(VCS_FLAGS) $(DESIGN_FILES) $(TB_FILES) -o $(SIMV)

#------------------------------------------------------------------------------
# Run
#------------------------------------------------------------------------------
run:
	@echo "============================================"
	@echo "Running test: $(TEST)"
	@echo "============================================"
	./$(SIMV) $(RUN_FLAGS)

#------------------------------------------------------------------------------
# Run specific tests
#------------------------------------------------------------------------------
test_reset:
	$(MAKE) run TEST=reset_test

test_basic:
	$(MAKE) run TEST=basic_operation_test

test_overflow:
	$(MAKE) run TEST=overflow_test

test_underflow:
	$(MAKE) run TEST=underflow_test

test_threshold:
	$(MAKE) run TEST=threshold_test

test_register:
	$(MAKE) run TEST=register_test

test_random:
	$(MAKE) run TEST=random_test

test_full:
	$(MAKE) run TEST=full_coverage_test

test_stress:
	$(MAKE) run TEST=stress_test

test_b2b:
	$(MAKE) run TEST=back_to_back_test

#------------------------------------------------------------------------------
# Run all tests
#------------------------------------------------------------------------------
run_all: compile
	@echo "Running all tests..."
	$(MAKE) run TEST=reset_test
	$(MAKE) run TEST=basic_operation_test
	$(MAKE) run TEST=overflow_test
	$(MAKE) run TEST=underflow_test
	$(MAKE) run TEST=threshold_test
	$(MAKE) run TEST=register_test
	$(MAKE) run TEST=random_test
	$(MAKE) run TEST=full_coverage_test

#------------------------------------------------------------------------------
# Coverage
#------------------------------------------------------------------------------
coverage:
	@echo "============================================"
	@echo "Running with coverage enabled..."
	@echo "============================================"
	vcs $(VCS_FLAGS) -cm line+cond+fsm+tgl+branch $(DESIGN_FILES) $(TB_FILES) -o $(SIMV)
	./$(SIMV) $(RUN_FLAGS) -cm line+cond+fsm+tgl+branch
	urg -dir $(SIMV).vdb -report coverage_report

#------------------------------------------------------------------------------
# Waveform viewing
#------------------------------------------------------------------------------
waves:
	dve -vpd vcdplus.vpd &

#------------------------------------------------------------------------------
# Clean
#------------------------------------------------------------------------------
clean:
	rm -rf $(SIMV) $(SIMV).daidir csrc
	rm -rf *.log *.vpd *.fsdb *.vcd
	rm -rf DVEfiles urgReport coverage_report
	rm -rf ucli.key vc_hdrs.h

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------
help:
	@echo "============================================"
	@echo "APB FIFO UVM Testbench Makefile (VCS)"
	@echo "============================================"
	@echo ""
	@echo "Usage: make [target] [TEST=<test_name>]"
	@echo ""
	@echo "Targets:"
	@echo "  all            - Compile and run (default: full_coverage_test)"
	@echo "  compile        - Compile design and testbench"
	@echo "  run            - Run simulation"
	@echo "  coverage       - Run with coverage enabled"
	@echo "  run_all        - Run all tests sequentially"
	@echo "  waves          - Open waveform viewer (DVE)"
	@echo "  clean          - Clean generated files"
	@echo "  help           - Show this help"
	@echo ""
	@echo "Individual Tests:"
	@echo "  test_reset     - Run reset_test"
	@echo "  test_basic     - Run basic_operation_test"
	@echo "  test_overflow  - Run overflow_test"
	@echo "  test_underflow - Run underflow_test"
	@echo "  test_threshold - Run threshold_test"
	@echo "  test_register  - Run register_test"
	@echo "  test_random    - Run random_test"
	@echo "  test_full      - Run full_coverage_test"
	@echo "  test_stress    - Run stress_test"
	@echo "  test_b2b       - Run back_to_back_test"
	@echo ""
	@echo "Examples:"
	@echo "  make                          # Compile and run full_coverage_test"
	@echo "  make TEST=random_test         # Run random_test"
	@echo "  make test_overflow            # Run overflow_test"
	@echo "  make run_all                  # Run all tests"
	@echo "  make coverage TEST=stress_test # Run stress_test with coverage"
