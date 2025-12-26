VCS = vcs
main_dir = ../
design_dir = ../design/
components_dir = ../components/
SOURCES = $(design_dir)interface.sv $(design_dir)adder.sv $(design_dir)wrapper.sv $(components_dir)transaction.sv $(components_dir)generator.sv $(components_dir)driver.sv $(components_dir)monitor.sv $(components_dir)scoreboard.sv $(components_dir)agent.sv $(components_dir)environment.sv $(components_dir)test.sv $(main_dir)testbench.sv

SIMV = simv

all: compile run

compile:
	$(VCS) -sverilog -full64 $(SOURCES) -o $(SIMV)

run: compile
	./$(SIMV) -l simulation.log

clean:
	rm -rf $(SIMV) csrc *.daidir ucli.key *.log

.PHONY: all compile run clean
