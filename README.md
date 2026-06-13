<div align="center">

# 🔬 APB FIFO Verification Using UVM

[![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue?style=for-the-badge&logo=verilog)](https://en.wikipedia.org/wiki/SystemVerilog)
[![UVM](https://img.shields.io/badge/Methodology-UVM%201.2-orange?style=for-the-badge)](https://www.accellera.org/downloads/standards/uvm)
[![Synopsys VCS](https://img.shields.io/badge/Simulator-Synopsys%20VCS-red?style=for-the-badge)](https://www.synopsys.com/verification/simulation/vcs.html)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)


</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Project Structure](#-project-structure)
- [Design Under Test](#-design-under-test)
- [Verification Architecture](#-verification-architecture)
- [Test Suite](#-test-suite)
- [Bugs Discovered](#-bugs-discovered)
- [Quick Start](#-quick-start)
- [Coverage](#-coverage)

---

## 🧠 Overview

This project implements a **complete UVM testbench** to verify a buggy APB3-accessible synchronous FIFO peripheral.

### 🎯 Objectives

- ✅ Verify all functional aspects of the FIFO (push/pop, overflow, underflow, thresholds, reset, enable)
- ✅ Build a **self-checking** environment using a golden reference model and scoreboard
- ✅ Collect **functional coverage** across all major FIFO states and transitions
- ✅ Identify and document **RTL bugs** with evidence from simulation

### 🏗️ Technology Stack

| Tool / Standard | Purpose |
|---|---|
| **SystemVerilog** | Testbench and RTL coding language |
| **UVM 1.2** | Verification methodology framework |
| **Synopsys VCS** | Simulation and code/functional coverage |
| **AMBA APB3** | Bus protocol for FIFO register access |

---

## 📁 Project Structure

```
APB-FIFO-Verification-using-UVM/
│
├── 📄 README.md                        ← This file
├── 📋 Bug_Report.pdf                   ← Detailed bug report with evidence
├── 🔧 tb_top.sv                        ← Top-level testbench module
│
├── 📐 design/
│   └── fifo.sv                         ← RTL Design Under Test (DUT)
│
├── 🧩 components/                      ← UVM building blocks
│   ├── apb_fifo_pkg.sv                ← Package (includes all components)
│   ├── apb_fifo_interface.sv          ← APB3 virtual interface
│   ├── apb_sequence_item.sv           ← APB transaction item
│   ├── apb_sequencer.sv               ← UVM sequencer
│   ├── apb_driver.sv                  ← APB3 protocol driver
│   ├── apb_monitor.sv                 ← Passive transaction observer
│   ├── apb_agent.sv                   ← Active agent (driver+monitor+sequencer)
│   ├── apb_fifo_env.sv                ← Top-level UVM environment
│   ├── apb_fifo_ref_model.sv          ← Golden behavioral reference model
│   ├── apb_fifo_scoreboard.sv         ← Self-checking scoreboard
│   └── apb_subscriber.sv              ← Functional coverage collector
│
├── 🔁 sequences/                       ← Stimulus sequences
│   ├── apb_base_sequence.sv           ← Base class with helper tasks
│   ├── basic_push_pop_sequence.sv     ← Core push/pop operations
│   ├── fifo_clear_sequence.sv         ← Synchronous clear verification
│   ├── fifo_enable_sequence.sv        ← Enable/disable control
│   ├── fifo_reset_sequence.sv         ← Reset behavior verification
│   ├── overflow_sequence.sv           ← Overflow and DROP_ON_FULL mode
│   ├── random_sequence.sv             ← Constrained-random operations
│   ├── threshold_sequence.sv          ← Almost-full/almost-empty thresholds
│   └── underflow_sequence.sv          ← Underflow detection
│
├── 🧪 tests/                           ← UVM test classes
│   ├── apb_fifo_base_test.sv          ← Base test with environment setup
│   ├── basic_operation_test.sv
│   ├── fifo_clear_test.sv
│   ├── fifo_enable_test.sv
│   ├── overflow_test.sv
│   ├── random_test.sv
│   ├── reset_test.sv
│   ├── stress_test.sv
│   ├── threshold_test.sv
│   └── underflow_test.sv
│
├── ⚙️ sim/
│   └── Makefile                        ← VCS compilation and run scripts
│
└── 🖥️ eda_version/                     ← EDA Playground-compatible version
    ├── apb_components.sv
    ├── apb_sequences.sv
    ├── apb_tests.sv
    ├── design.sv
    └── testbench.sv
```

---

## 📐 Design Under Test

The DUT is an **8-bit wide, 16-entry synchronous FIFO** accessible through the **AMBA APB3** bus interface.

### 📌 FIFO Specifications

| Parameter | Value |
|---|---|
| **Data Width** | 8 bits |
| **FIFO Depth** | 16 entries |
| **Bus Protocol** | AMBA APB3 |
| **Reset** | Active-low asynchronous (`PRESETn`) |
| **Clock** | Single clock domain (`PCLK`) |

### 🗺️ Register Map

| Offset | Register | Access | Description |
|---|---|---|---|
| `0x00` | **CTRL** | R/W | `[0]` Enable · `[1]` Clear · `[2]` Drop-on-Full |
| `0x04` | **THRESH** | R/W | `[3:0]` Almost-Empty · `[7:4]` Almost-Full |
| `0x08` | **STATUS** | R | `[0]` Empty · `[1]` Full · `[2]` A.Empty · `[3]` A.Full · `[4]` OVF · `[5]` UDF · `[11:6]` Count |
| `0x0C` | **DATA** | R/W | Write → push · Read → pop |

### ✨ Key Features

- 🔄 Programmable almost-full and almost-empty thresholds
- ⚠️ Sticky overflow and underflow error flags (cleared by software)
- 🚫 Drop-on-Full mode with `PSLVERR` error response
- 🔃 Synchronous FIFO clear via control register
- 📊 Real-time FIFO entry count in STATUS register

---

## 🏛️ Verification Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    apb_fifo_test                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  apb_fifo_env                         │  │
│  │                                                       │  │
│  │  ┌─────────────────────┐   ┌───────────────────────┐ │  │
│  │  │     apb_agent       │   │  apb_fifo_ref_model   │ │  │
│  │  │  ┌───────────────┐  │   │  (Golden Reference)   │ │  │
│  │  │  │  apb_driver   │  │   └───────────┬───────────┘ │  │
│  │  │  │  (APB3 Proto) │  │               │ predicted   │  │
│  │  │  └───────────────┘  │               ▼             │  │
│  │  │  ┌───────────────┐  │   ┌───────────────────────┐ │  │
│  │  │  │ apb_sequencer │  │   │ apb_fifo_scoreboard   │ │  │
│  │  │  └───────────────┘  │   │  (Pass / Fail Check)  │ │  │
│  │  │  ┌───────────────┐  │   └───────────────────────┘ │  │
│  │  │  │  apb_monitor  │──┼──►┌───────────────────────┐ │  │
│  │  │  │  (Observer)   │  │   │   apb_subscriber      │ │  │
│  │  │  └───────────────┘  │   │ (Functional Coverage) │ │  │
│  │  └─────────────────────┘   └───────────────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
│                          │ APB3 Interface                    │
│                 ┌────────▼────────┐                         │
│                 │  apb_sync_fifo  │  ← Design Under Test    │
│                 │    (DUT RTL)    │                         │
│                 └─────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

### 🔑 Component Descriptions

| Component | Role |
|---|---|
| **`apb_driver`** | Implements full APB3 protocol (SETUP → ACCESS → IDLE phases) |
| **`apb_monitor`** | Passively observes all bus transactions and broadcasts via TLM |
| **`apb_fifo_ref_model`** | Software FIFO model that predicts the expected DUT response |
| **`apb_fifo_scoreboard`** | Compares DUT actual output vs reference model prediction; reports pass/fail with field-by-field details |
| **`apb_subscriber`** | Collects functional coverage on FIFO states, transitions, and error conditions |

---

## 🧪 Test Suite

The testbench includes **9 directed tests** and **1 stress test**, each targeting a specific FIFO feature.

| # | Test | Sequence | What It Verifies |
|---|---|---|---|
| 1 | `reset_test` | `fifo_reset_sequence` | Reset assertion/deassertion, FIFO cleared on reset |
| 2 | `fifo_enable_test` | `fifo_enable_sequence` | Enable/disable control, push/pop rejected when disabled |
| 3 | `fifo_clear_test` | `fifo_clear_sequence` | Synchronous clear, empty/full flag updates |
| 4 | `basic_operation_test` | `basic_push_pop_sequence` | Push/pop data integrity, fill to capacity |
| 5 | `overflow_test` | `overflow_sequence` | Overflow detection, DROP_ON_FULL mode, `PSLVERR`, sticky flags |
| 6 | `underflow_test` | `underflow_sequence` | Underflow detection, sticky flag persistence |
| 7 | `threshold_test` | `threshold_sequence` | Programmable almost-full/almost-empty transitions |
| 8 | `random_test` | `random_sequence` | Constrained-random mix of all operations |
| 9 | `stress_test` | All sequences chained | 1000 operations, sequence combinations, endurance |

---

## 🐛 Bugs Discovered

The testbench successfully identified **5 critical RTL bugs** in the design. Full details, waveform evidence, and root cause analysis are in [Bug_Report.pdf](Bug_Report.pdf).

---

### 🔴 BUG-001 — Reset Logic Inversion

| Field | Detail |
|---|---|
| **Severity** | Critical |
| **Location** | [design/fifo.sv](design/fifo.sv) line 96 |
| **Test** | `reset_test` |

**Problem:** The always block triggers on `posedge PRESETn` instead of `negedge PRESETn`. Since `PRESETn` is active-low, this means the FIFO "resets" when the signal goes *high* and operates abnormally when it goes *low*.

```systemverilog
// ❌ Buggy
always_ff @(posedge PCLK or posedge PRESETn)

// ✅ Fixed
always_ff @(posedge PCLK or negedge PRESETn)
```

---

### 🔴 BUG-002 — Overflow Flag Not Sticky

| Field | Detail |
|---|---|
| **Severity** | Critical |
| **Location** | [design/fifo.sv](design/fifo.sv) lines 71–74 |
| **Test** | `overflow_test` |

**Problem:** The overflow flag is cleared on every STATUS register *read*, instead of persisting until explicitly cleared by software via the CTRL register.

```systemverilog
// ❌ Buggy — clears flag on any read
if (PSEL && PENABLE && !PWRITE) overflow <= 1'b0;

// ✅ Fixed — only clear on CTRL write with clear bit set
if (ctrl_reg[CLEAR_BIT]) overflow <= 1'b0;
```

---

### 🔴 BUG-003 — DROP_ON_FULL / PSLVERR Not Functional

| Field | Detail |
|---|---|
| **Severity** | Critical |
| **Location** | [design/fifo.sv](design/fifo.sv) line 40 |
| **Test** | `overflow_test` (Test 2) |

**Problem:** `PSLVERR` is hardcoded to `0`, so the APB master never receives an error response when writing to a full FIFO with DROP_ON_FULL enabled.

```systemverilog
// ❌ Buggy — always 0
assign PSLVERR = 1'b0;

// ✅ Fixed — drive PSLVERR when DROP_ON_FULL and FIFO is full
assign PSLVERR = (ctrl_reg[DROP_ON_FULL] && fifo_full && write_attempt);
```

---

### 🔴 BUG-004 — Underflow Flag Not Sticky

| Field | Detail |
|---|---|
| **Severity** | Critical |
| **Location** | [design/fifo.sv](design/fifo.sv) lines 71–74 |
| **Test** | `underflow_test` |

**Problem:** Same root cause as BUG-002. The underflow flag is cleared on every STATUS read instead of requiring a software clear. Any diagnostic read after underflow destroys the event record.

---

### 🔴 BUG-005 — Full Flag Asserts One Entry Early

| Field | Detail |
|---|---|
| **Severity** | Critical |
| **Location** | [design/fifo.sv](design/fifo.sv) line 142 |
| **Test** | `basic_operation_test` |

**Problem:** The full flag asserts when `count == DEPTH-1` (15), treating a 16-entry FIFO as if it has only 15 slots. The 16th push is incorrectly flagged as overflow.

```systemverilog
// ❌ Buggy — full at 15
full <= (count == DEPTH - 1);

// ✅ Fixed — full at 16
full <= (count == DEPTH);
```

---

## 🚀 Quick Start

There are two ways to run this project — choose whichever fits your environment.

---

### 🖥️ Option 1 — Synopsys VCS (Simulation Server)

#### Prerequisites

- Access to a **Synopsys VCS** simulation server
- SystemVerilog and UVM 1.2 support (included in VCS)

#### ⚙️ Setup & Compilation

```bash
# Clone the repository
git clone https://github.com/osaidnur/APB-FIFO-Verification-using-UVM.git
cd APB-FIFO-Verification-using-UVM/sim

# Compile the design and testbench
make compile
```

#### ▶️ Running Tests

```bash
# Run the default test (basic_operation_test)
make run

# Run a specific test
make run TEST_NAME=reset_test
make run TEST_NAME=overflow_test
make run TEST_NAME=underflow_test
make run TEST_NAME=threshold_test
make run TEST_NAME=random_test
make run TEST_NAME=stress_test

# Run with verbose UVM output
make run TEST_NAME=basic_operation_test VERBOSITY=UVM_HIGH
```

#### 📊 Coverage & Waveforms

```bash
# Generate coverage report
make coverage

# View waveforms (VCD)
make waves

# Clean simulation artifacts
make clean

# Full flow: compile + run + coverage
make all
```

---

### 🌐 Option 2 — EDA Playground (No Installation Required)

The [`eda_version/`](eda_version/) folder contains pre-merged, EDA Playground-ready files. All components, sequences, tests, and the design are bundled into single flat files for easy copy-paste.

#### Steps

1. Go to [https://www.edaplayground.com](https://www.edaplayground.com) and create a free account
1. Create a new playground and select:
   - **Language**: SystemVerilog/VHDL
   - **Simulator**: Synopsys VCS (with UVM 1.2)
1. Copy the file contents into the playground:

| EDA Playground Tab | File to use |
|---|---|
| **design.sv** | [`eda_version/design.sv`](eda_version/design.sv) |
| **testbench.sv** | [`eda_version/testbench.sv`](eda_version/testbench.sv) |

> The testbench file already includes and imports `apb_components.sv`, `apb_sequences.sv`, and `apb_tests.sv` — everything is bundled together.

1. Click **Run** ▶️

---

## 📊 Coverage

The `apb_subscriber` component collects functional coverage across:

| Coverage Group | Description |
|---|---|
| **FIFO States** | Empty, almost-empty, nominal, almost-full, full |
| **Operations** | Push, pop, clear, reset, enable/disable |
| **Error Conditions** | Overflow, underflow, DROP_ON_FULL response |
| **Threshold Transitions** | Crossing almost-full and almost-empty boundaries |
| **APB Transactions** | Read/write to all 4 registers |

---



</div>
