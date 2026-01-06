# APB FIFO Verification using UVM - EDA Playground Version

This is a consolidated version of the APB FIFO Verification project optimized for **EDA Playground**.

## File Structure

The project has been consolidated into the following files:

1. **apb_fifo_design.sv** - The APB FIFO design (DUT)
2. **testbench.sv** - Top module including interface and package
3. **apb_components.sv** - All UVM components (sequence_item, driver, monitor, agent, scoreboard, env, etc.)
4. **apb_sequences.sv** - All test sequences consolidated
5. **apb_tests.sv** - All test classes consolidated

## How to Run on EDA Playground

### Step 1: Go to EDA Playground
Visit: https://www.edaplayground.com/

### Step 2: Upload Files
In the left panel, create and paste the following files in this order:

1. **apb_fifo_design.sv** - Copy the design file content
2. **apb_components.sv** - Copy the components file content
3. **apb_sequences.sv** - Copy the sequences file content
4. **apb_tests.sv** - Copy the tests file content
5. **testbench.sv** - Copy the testbench file content (this should be the top file)

### Step 3: Configure EDA Playground Settings

**Testbench + Design Settings:**
- **Top File:** testbench.sv
- **Testbench Language:** SystemVerilog/Verilog
- **Run Time:** 1ms or more
- **UVM Version:** UVM 1.2

**Tools & Simulators:**
- Select a simulator that supports UVM (recommended):
  - **Cadence Xcelium** (best UVM support)
  - **Synopsys VCS**
  - **Mentor Questa**
  - **Aldec Riviera-PRO**

**Compile Order:**
The files will be compiled in the order they appear in EDA Playground, so make sure testbench.sv is listed last or set as the top file.

### Step 4: Select Test to Run

Edit the `testbench.sv` file and change the test name in the `run_test()` call (around line 163):

```systemverilog
initial begin
    run_test("overflow_test");  // Change this to run different tests
end
```

**Available Tests:**
- `reset_test` - Tests reset behavior
- `basic_operation_test` - Basic push/pop operations
- `overflow_test` - Tests overflow conditions
- `underflow_test` - Tests underflow conditions
- `threshold_test` - Tests threshold detection
- `register_test` - Tests register access
- `random_test` - Random operations (100 transactions)
- `full_coverage_test` - Runs all directed sequences
- `stress_test` - High volume test (1000 transactions)
- `back_to_back_test` - Rapid back-to-back transactions
- `clear_test` - Tests FIFO clear functionality

### Step 5: Run Simulation

Click the **"Run"** button in EDA Playground.

### Step 6: View Results

- Check the **Log** tab for simulation output
- Look for the scoreboard summary report
- Check for UVM_ERROR or UVM_FATAL messages
- The test will display **✓ TEST PASSED ✓** or **✘ TEST FAILED ✘**

## Expected Output

You should see output similar to:

```
UVM_INFO @ 0: reporter [RNTST] Running test overflow_test...
UVM_INFO SEQ: Starting Overflow Sequence
...
UVM_INFO SCB: ╔══════════════════════════════════════════╗
UVM_INFO SCB: ║      SCOREBOARD SUMMARY REPORT           ║
UVM_INFO SCB: ╠══════════════════════════════════════════╣
UVM_INFO SCB: ║  Total Transactions:    XX               ║
UVM_INFO SCB: ║  Passed Checks:         XX               ║
UVM_INFO SCB: ║  Failed Checks:          0               ║
UVM_INFO SCB: ║  Final FIFO Count:       X               ║
UVM_INFO SCB: ╚══════════════════════════════════════════╝
UVM_INFO TEST: ╔═══════════════════════════════════════════╗
UVM_INFO TEST: ║              ✓ TEST PASSED ✓             ║
UVM_INFO TEST: ╚═══════════════════════════════════════════╝
```

## Design Features

The APB FIFO design includes:
- **Width:** 8 bits
- **Depth:** 16 entries
- **APB3 interface**
- **Configurable thresholds** (almost full/empty)
- **Overflow/underflow detection**
- **Drop-on-full mode**
- **Synchronous clear**

## Register Map

| Offset | Name   | Access | Description                          |
|--------|--------|--------|--------------------------------------|
| 0x00   | CTRL   | RW     | Control register (EN, CLR, DROP)     |
| 0x04   | THRESH | RW     | Threshold configuration              |
| 0x08   | STATUS | R      | Status flags and count               |
| 0x0C   | DATA   | RW     | FIFO data (push/pop)                 |

## Troubleshooting

**If simulation doesn't run:**
1. Make sure UVM is enabled in the simulator settings
2. Verify all files are uploaded in the correct order
3. Check that testbench.sv is set as the top module
4. Try a different simulator (Xcelium usually has best UVM support)

**If you see compilation errors:**
1. Check that all files are properly formatted
2. Ensure no extra characters were added during copy/paste
3. Verify the package includes are in the correct order

## Notes

- This version has simplified coverage collection compared to the full project
- The design intentionally contains bugs for verification practice
- Waveforms can be viewed using the EPWave viewer in EDA Playground (if available)

## Original Project Structure

This consolidated version was created from the original project structure:
- components/ - Individual component files
- sequences/ - Individual sequence files
- tests/ - Individual test files
- design/ - Design files
- sim/ - Simulation scripts

For the full development version with separate files, refer to the main project directory.
