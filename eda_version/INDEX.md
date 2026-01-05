# EDA Playground Version - File Index

## 📁 Complete File List

### 📘 Documentation Files
1. **README.md** - Complete setup and usage instructions
2. **QUICK_START.md** - Fast reference guide
3. **FILE_STRUCTURE.md** - Comparison with original project
4. **INDEX.md** - This file

### 📝 SystemVerilog Files (Upload to EDA Playground in this order)

#### 1. apb_fifo_design.sv
**Purpose:** Design Under Test (DUT)
**Contains:** APB FIFO design module
**Lines:** ~180 lines
**Upload Order:** 1st

#### 2. apb_components.sv  
**Purpose:** All UVM verification components
**Contains:**
- apb_sequence_item (transaction class)
- apb_sequencer
- apb_driver (APB protocol driver)
- apb_monitor (monitors APB transactions)
- apb_agent (active agent with driver+sequencer+monitor)
- apb_fifo_ref_model (golden reference model)
- apb_fifo_scoreboard (comparison and checking)
- apb_subscriber (coverage collector - simplified)
- apb_fifo_env (top-level environment)

**Lines:** ~550 lines
**Upload Order:** 2nd

#### 3. apb_sequences.sv
**Purpose:** All test sequences
**Contains:**
- apb_base_sequence (base class with utility tasks)
- reset_sequence
- fifo_enable_sequence
- basic_push_pop_sequence
- fill_fifo_sequence
- overflow_sequence
- underflow_sequence
- threshold_sequence
- fifo_clear_sequence
- random_sequence
- reg_access_sequence
- full_coverage_sequence
- back_to_back_sequence

**Lines:** ~530 lines
**Upload Order:** 3rd

#### 4. apb_tests.sv
**Purpose:** All test classes
**Contains:**
- apb_fifo_base_test (base test class)
- reset_test
- basic_operation_test
- overflow_test
- underflow_test
- threshold_test
- register_test
- random_test
- full_coverage_test
- stress_test
- back_to_back_test
- clear_test

**Lines:** ~260 lines
**Upload Order:** 4th

#### 5. testbench.sv
**Purpose:** Top-level testbench
**Contains:**
- apb_fifo_if (interface definition)
- apb_fifo_pkg (package with includes)
- top_tb (top module with DUT instantiation)
- Clock generation
- Reset generation
- Waveform dumping

**Lines:** ~180 lines
**Upload Order:** 5th (TOP MODULE)

## 🎯 Quick Navigation

### Want to modify the design?
→ Edit **apb_fifo_design.sv**

### Want to add a new sequence?
→ Edit **apb_sequences.sv** (add new class at the end)

### Want to add a new test?
→ Edit **apb_tests.sv** (add new class at the end)

### Want to change which test runs?
→ Edit **testbench.sv** line 163: `run_test("test_name")`

### Want to modify driver/monitor behavior?
→ Edit **apb_components.sv**

## 📊 Statistics

| File | Type | Lines | Classes/Modules |
|------|------|-------|-----------------|
| apb_fifo_design.sv | Design | ~180 | 1 module |
| apb_components.sv | UVM | ~550 | 9 classes |
| apb_sequences.sv | UVM | ~530 | 13 classes |
| apb_tests.sv | UVM | ~260 | 12 classes |
| testbench.sv | Testbench | ~180 | 1 interface, 1 package, 1 module |
| **TOTAL** | | **~1700** | **35 classes/modules** |

## 🚀 Usage Workflow

1. **Read:** QUICK_START.md
2. **Upload:** All 5 .sv files to EDA Playground
3. **Configure:** Simulator settings (UVM 1.2, Xcelium/VCS)
4. **Select Test:** Edit testbench.sv
5. **Run:** Click Run button
6. **Analyze:** Check logs for PASSED/FAILED

## 🔍 Finding Specific Code

### Looking for APB protocol implementation?
- **Driver:** apb_components.sv (line ~130-180)
- **Monitor:** apb_components.sv (line ~185-220)

### Looking for FIFO reference model?
- **Location:** apb_components.sv (line ~230-400)

### Looking for scoreboard checking logic?
- **Location:** apb_components.sv (line ~405-500)

### Looking for sequence tasks?
- **Base tasks:** apb_sequences.sv (line ~1-100)
- **Individual sequences:** apb_sequences.sv (line 100+)

### Looking for test run_phase?
- **Location:** apb_tests.sv (each test class)

## 💡 Tips

- All files are self-contained and can be read independently
- Comments are preserved from original files
- Line numbers are approximate (may shift with edits)
- Use Ctrl+F to search within files
- Classes maintain same names as original project

## 📞 Support

For questions about:
- **Original project structure:** See main README.md
- **EDA Playground setup:** See QUICK_START.md
- **File organization:** See FILE_STRUCTURE.md
- **Quick reference:** You're reading it! (INDEX.md)
