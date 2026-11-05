# FPGA-Based Matrix Multiplication: Comparative Analysis of Four Systolic Architectures

## 1. Introduction

Matrix multiplication is one of the fundamental operations in digital signal processing, computer vision, scientific computing, and artificial intelligence. As computational requirements increase, hardware acceleration becomes important for achieving higher computational performance with efficient resource utilization.

This project presents the design, implementation, and comparative analysis of four different systolic array architectures for matrix multiplication using Verilog HDL on the **Nexys A7-100T FPGA development board**.

The main objective is to investigate how different dataflow mechanisms and processing-element arrangements affect computational latency, FPGA resource utilization, power consumption, and computational throughput.

The four architectures implemented in this project are:

1. **DiP:** Diagonal-Input and Permutated Weight-Stationary Architecture.
2. **TRIM:** Weight-Stationary Systolic Array Architecture.
3. **Hybrid:** Hybrid Scale-Up/Scale-Down Architecture.
4. **Versa:** Versa Systolic Architecture.

All four architectures are evaluated using a common FPGA platform to provide a comparative understanding of their hardware performance.

---

## 2. Project Objectives

The primary objectives of this project are:

* Design and implement four different matrix multiplication architectures using Verilog HDL.
* Understand and compare different systolic array dataflow mechanisms.
* Implement the architectures on the Nexys A7-100T FPGA.
* Verify functionality using Vivado behavioral simulation.
* Evaluate hardware resource utilization.
* Analyze computational latency.
* Estimate FPGA power consumption.
* Calculate computational throughput.
* Identify the advantages and limitations of each architecture.

---

## 3. Hardware and Software Requirements

### Hardware

| Component             | Specification                  |
| --------------------- | ------------------------------ |
| FPGA Board            | Digilent Nexys A7-100T         |
| FPGA Device           | Xilinx Artix-7 XC7A100T        |
| Programming Interface | USB JTAG                       |
| Output Interface      | Seven-Segment Display and UART |

### Software

* AMD Xilinx Vivado Design Suite
* Verilog HDL
* Python 3
* PySerial

Install the Python UART dependency:

```bash
pip install pyserial
```

---

# 4. Architecture 1: DiP

## 4.1 Architecture Overview

DiP stands for **Diagonal-Input and Permutated Weight-Stationary** architecture.

It uses a combination of diagonal input propagation and permuted weight-stationary dataflow to perform matrix multiplication.

In this architecture:

* Weights are distributed across processing elements using a column-dependent permutation.
* Input operands propagate through the array using diagonal or cyclic data-transfer patterns.
* Processing elements perform multiplication and accumulation operations.
* Intermediate results propagate through the systolic structure to generate the final output matrix.

The architecture focuses on efficient data movement and reuse while maintaining parallel computation.

## 4.2 Main Implementation Module

**Implementation file:** `dip.v`

The `dip.v` module contains the main DiP systolic array implementation.

Its primary responsibilities include:

* Implementing the processing-element arrangement.
* Managing diagonal input propagation.
* Handling permuted weight distribution.
* Performing multiply-accumulate operations.
* Managing intermediate result propagation.
* Producing the final matrix multiplication output.

The architecture preserves the DiP-specific dataflow mechanism rather than using a conventional parallel matrix multiplier.

## 4.3 Testbench

**Testbench file:** `tb_dip.v`

The testbench verifies the functionality of the DiP architecture through behavioral simulation.

It performs the following operations:

1. Generates the clock signal.
2. Applies reset to the design.
3. Initializes the input matrices and weights.
4. Starts the computation.
5. Monitors the internal signals and output matrix.
6. Checks the generated results against the expected matrix multiplication output.

The testbench is used to verify the correctness of the DiP implementation before FPGA deployment.

## 4.4 Performance Results

| Parameter         |     Result |
| ----------------- | ---------: |
| LUTs              |        620 |
| LUT Utilization   |      0.98% |
| Flip-Flops        |        778 |
| FF Utilization    |      0.61% |
| DSP48E1           |          0 |
| BRAM Tiles        |          0 |
| Power Consumption |    0.136 W |
| Latency           |   0.250 µs |
| Throughput        | 0.512 GOPS |

## 4.5 Advantages

* Lowest LUT utilization among the four implementations.
* Lowest flip-flop utilization.
* Lowest reported power consumption.
* Efficient hardware resource utilization.
* Structured data propagation through the processing array.

## 4.6 Disadvantages

* Lower throughput than Hybrid and Versa.
* Diagonal input propagation requires careful scheduling.
* Permuted weight distribution introduces additional control complexity.
* Data alignment between processing elements must be maintained.

---

# 5. Architecture 2: TRIM

## 5.1 Architecture Overview

TRIM implements a **Weight-Stationary Systolic Array** architecture.

In weight-stationary dataflow, weights remain stored within their respective processing elements while input operands propagate through the array.

Each processing element performs multiplication and accumulation operations, contributing to the final matrix multiplication result.

The primary objective of this architecture is to reuse weights locally and organize computation through a structured systolic dataflow.

## 5.2 Main Implementation Module

**Implementation file:** `ws_top.v`

The `ws_top.v` module contains the main TRIM weight-stationary systolic array implementation.

Its primary responsibilities include:

* Organizing the processing-element array.
* Maintaining weight values within processing elements.
* Managing input operand propagation.
* Performing multiply-accumulate operations.
* Managing intermediate partial sums.
* Generating the final output matrix.

## 5.3 Testbench

**Testbench file:** `tb_trim.v`

The testbench verifies the functionality of the TRIM architecture.

The simulation includes:

1. Clock generation.
2. Reset initialization.
3. Loading the input matrices.
4. Applying the computation start signal.
5. Monitoring the processing-element activity.
6. Observing the output matrix.
7. Verifying the final matrix multiplication result.

## 5.4 Performance Results

| Parameter         |     Result |
| ----------------- | ---------: |
| LUTs              |      1,096 |
| LUT Utilization   |      1.73% |
| Flip-Flops        |      1,204 |
| FF Utilization    |      0.95% |
| DSP48E1           |          0 |
| BRAM Tiles        |          0 |
| Power Consumption |    0.149 W |
| Latency           |   0.256 µs |
| Throughput        | 0.500 GOPS |

## 5.5 Advantages

* Structured weight-stationary dataflow.
* Local reuse of weight values.
* Regular processing-element organization.
* Moderate FPGA resource requirements.
* Straightforward systolic computation structure.

## 5.6 Disadvantages

* Lowest reported computational throughput.
* Slightly higher latency than DiP.
* Greater LUT and flip-flop utilization than DiP.
* Performance depends on efficient operand scheduling.

---

# 6. Architecture 3: Hybrid

## 6.1 Architecture Overview

The Hybrid architecture combines scale-up and scale-down mechanisms to organize data movement and computation within the hardware structure.

The architecture aims to balance operand distribution and computational activity across the processing elements.

Its performance is evaluated to understand how combining different architectural mechanisms affects hardware utilization and computational throughput.

## 6.2 Main Implementation Module

**Implementation file:** `hybrid_top.v`

The `hybrid_top.v` module contains the primary Hybrid architecture implementation.

Its responsibilities include:

* Organizing the hybrid processing structure.
* Managing input operand distribution.
* Controlling scale-up and scale-down operations.
* Performing matrix multiplication computations.
* Managing intermediate results.
* Producing the final output matrix.

## 6.3 Testbench

**Testbench file:** `tb_hybrid.v`

The testbench verifies the Hybrid architecture using behavioral simulation.

It performs:

1. Clock generation.
2. Reset initialization.
3. Input matrix initialization.
4. Computation initiation.
5. Monitoring of internal control signals.
6. Observation of intermediate and final outputs.
7. Verification of the final computation.

## 6.4 Performance Results

| Parameter         |      Result |
| ----------------- | ----------: |
| LUTs              |       1,905 |
| LUT Utilization   |       3.00% |
| Flip-Flops        |       1,652 |
| FF Utilization    |       1.30% |
| DSP48E1           |           0 |
| BRAM Tiles        |           0 |
| Power Consumption |     0.140 W |
| Latency           |      0.236* |
| Throughput        | 0.5424 GOPS |

*The original latency value was reported as 0.236 ns. Its unit must be verified against the Vivado timing or simulation report. If the intended unit is µs, it should be reported as 0.236 µs.*

## 6.5 Advantages

* Higher throughput than DiP and TRIM.
* Moderate power consumption.
* Improved computational performance.
* Provides an intermediate resource-performance trade-off.
* Combines different dataflow mechanisms.

## 6.6 Disadvantages

* Higher resource utilization than DiP and TRIM.
* More complex hardware organization.
* Requires additional control logic.
* Uses more LUTs and flip-flops than the first two architectures.

---

# 7. Architecture 4: Versa

## 7.1 Architecture Overview

Versa is implemented as a separate systolic architecture for matrix multiplication.

The architecture is evaluated to study its computational performance and hardware resource requirements.

The reported results demonstrate the highest computational throughput among the four implementations.

## 7.2 Main Implementation Module

**Implementation file:** `versa_top.v`

The `versa_top.v` module contains the primary Versa architecture implementation.

Its responsibilities include:

* Organizing the Versa processing structure.
* Managing input operand distribution.
* Controlling the computational datapath.
* Performing multiplication and accumulation operations.
* Managing intermediate results.
* Generating the final matrix multiplication output.

## 7.3 Testbench

**Testbench file:** `tb_versa.v`

The testbench verifies the functionality of the Versa architecture.

The simulation procedure includes:

1. Clock generation.
2. Reset initialization.
3. Input matrix initialization.
4. Starting the computation.
5. Monitoring internal signals.
6. Observing the output matrix.
7. Verifying the final computation.

## 7.4 Performance Results

| Parameter         |      Result |
| ----------------- | ----------: |
| LUTs              |       2,800 |
| LUT Utilization   |       4.42% |
| Flip-Flops        |       2,172 |
| FF Utilization    |       1.71% |
| DSP48E1           |           0 |
| BRAM Tiles        |           0 |
| Power Consumption |     0.159 W |
| Latency           |    0.256 µs |
| Throughput        | 0.8050 GOPS |

## 7.5 Advantages

* Highest computational throughput.
* Strong computational performance.
* Suitable for throughput-oriented applications.
* Demonstrates effective parallel computation in the evaluated implementation.

## 7.6 Disadvantages

* Highest LUT utilization.
* Highest flip-flop utilization.
* Highest reported power consumption.
* Requires more FPGA resources than the other three architectures.

---

# 8. FPGA Implementation Procedure

All four architectures are implemented as separate Vivado projects.

The general implementation procedure is the same for each architecture.

## Step 1: Clone the Repository

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
```

Navigate to the required architecture folder:

```bash
cd FPGA-Matrix-Multiplication/DiP
```

For the remaining implementations, use the corresponding folder:

```text
TRIM/
Hybrid/
Versa/
```

## Step 2: Create the Vivado Project Using Tcl

Open Vivado and access the Tcl Console.

Execute the following commands:

```tcl
cd {PATH_TO_ARCHITECTURE_FOLDER}
source Create_Project.tcl
```

For example:

```tcl
cd {C:/Users/YourName/Downloads/FPGA-Matrix-Multiplication/DiP}
source Create_Project.tcl
```

The Tcl script creates the Vivado project and imports the required RTL files, constraints, memory files, and simulation sources.

## Step 3: Open the Generated Project

```tcl
open_project {PATH_TO_GENERATED_PROJECT.xpr}
```

## Step 4: Run Behavioral Simulation

In Vivado:

1. Open the Simulation section.
2. Select Run Simulation.
3. Select Run Behavioral Simulation.
4. Inspect the input, control, and output waveforms.
5. Verify the final matrix multiplication result.

## Step 5: Run Synthesis

Select **Run Synthesis** in Vivado.

After synthesis, inspect the following:

* LUT utilization.
* Flip-flop utilization.
* DSP48E1 utilization.
* BRAM utilization.
* Synthesis warnings.

## Step 6: Run Implementation

Select **Run Implementation**.

Vivado performs optimization, placement, and routing.

## Step 7: Generate Reports

The following Tcl commands can be used to generate reports:

```tcl
report_utilization -file utilization.rpt
report_timing_summary -file timing.rpt
report_power -file power.rpt
```

## Step 8: Generate the Bitstream

Select **Generate Bitstream**.

Alternatively:

```tcl
write_bitstream -force design.bit
```

## Step 9: Program the Nexys A7 FPGA

1. Connect the FPGA board through USB.
2. Open Vivado Hardware Manager.
3. Select Open Target.
4. Select Auto Connect.
5. Select Program Device.
6. Choose the generated bitstream file.

---

# 9. Comparative Performance Analysis

This section compares the four architectures using the measured or reported implementation results.

## 9.1 Resource Utilization Comparison

The following table presents the FPGA resources consumed by each architecture.

| Resource        |     DiP |    TRIM |  Hybrid |   Versa |
| --------------- | ------: | ------: | ------: | ------: |
| LUTs Used       |     620 |   1,096 |   1,905 |   2,800 |
| LUT Available   |  63,400 |  63,400 |  63,400 |  63,400 |
| LUT Utilization |   0.98% |   1.73% |   3.00% |   4.42% |
| Flip-Flops Used |     778 |   1,204 |   1,652 |   2,172 |
| FF Available    | 126,800 | 126,800 | 126,800 | 126,800 |
| FF Utilization  |   0.61% |   0.95% |   1.30% |   1.71% |
| DSP48E1         |       0 |       0 |       0 |       0 |
| BRAM Tiles      |       0 |       0 |       0 |       0 |

### Analysis

DiP demonstrates the lowest hardware resource utilization, requiring only 620 LUTs and 778 flip-flops.

Versa consumes the highest resources, requiring 2,800 LUTs and 2,172 flip-flops.

This indicates that the four architectures have different hardware complexity and implementation requirements.

All four implementations report zero DSP48E1 and BRAM usage.

## 9.2 Power Consumption Comparison

| Architecture | Power Consumption |
| ------------ | ----------------: |
| DiP          |           0.136 W |
| TRIM         |           0.149 W |
| Hybrid       |           0.140 W |
| Versa        |           0.159 W |

### Analysis

DiP demonstrates the lowest reported power consumption of 0.136 W.

Hybrid follows with 0.140 W, while TRIM consumes 0.149 W.

Versa has the highest reported power consumption at 0.159 W.

The difference reflects the resource and switching requirements of the respective implementations.

These values should be interpreted as Vivado power estimates unless independently verified using physical board measurements.

## 9.3 Latency Comparison

| Architecture |  Latency |
| ------------ | -------: |
| DiP          | 0.250 µs |
| TRIM         | 0.256 µs |
| Hybrid       |   0.236* |
| Versa        | 0.256 µs |

*Hybrid latency was originally reported as 0.236 ns. Verify the unit before comparing it with the other architectures.*

### Analysis

DiP and Versa have different architectural organizations but share the same reported latency of 0.256 µs only for Versa and 0.250 µs for DiP.

TRIM reports 0.256 µs.

Hybrid reports 0.236, but its unit requires verification.

A fair latency comparison requires identical start and completion definitions, clock constraints, and measurement methodology.

## 9.4 Computational Throughput Comparison

| Architecture |  Throughput |
| ------------ | ----------: |
| DiP          |  0.512 GOPS |
| TRIM         |  0.500 GOPS |
| Hybrid       | 0.5424 GOPS |
| Versa        | 0.8050 GOPS |

### Analysis

Versa achieves the highest reported computational throughput at 0.8050 GOPS.

Hybrid achieves 0.5424 GOPS, followed by DiP at 0.512 GOPS.

TRIM demonstrates the lowest throughput at 0.500 GOPS.

Versa provides approximately 57.2% higher reported throughput than DiP.

This makes Versa the strongest candidate when maximum computational throughput is the primary objective.

---

# 10. Overall Comparison Matrix

| Evaluation Parameter   | DiP        | TRIM       | Hybrid      | Versa      |
| ---------------------- | ---------- | ---------- | ----------- | ---------- |
| LUT Utilization        | 0.98%      | 1.73%      | 3.00%       | 4.42%      |
| FF Utilization         | 0.61%      | 0.95%      | 1.30%       | 1.71%      |
| DSP48E1                | 0          | 0          | 0           | 0          |
| BRAM Tiles             | 0          | 0          | 0           | 0          |
| Power                  | 0.136 W    | 0.149 W    | 0.140 W     | 0.159 W    |
| Latency                | 0.250 µs   | 0.256 µs   | 0.236*      | 0.256 µs   |
| Throughput             | 0.512 GOPS | 0.500 GOPS | 0.5424 GOPS | 0.805 GOPS |
| Resource Efficiency    | Highest    | Moderate   | Moderate    | Lowest     |
| Throughput Performance | Moderate   | Lowest     | Improved    | Highest    |

---

# 11. Final Advantages and Disadvantages

| Architecture | Advantages                                                   | Disadvantages                                                  |
| ------------ | ------------------------------------------------------------ | -------------------------------------------------------------- |
| DiP          | Lowest LUTs, flip-flops, and power consumption               | Lower throughput than Hybrid and Versa                         |
| TRIM         | Structured weight-stationary dataflow and local weight reuse | Lowest reported throughput                                     |
| Hybrid       | Improved throughput with moderate power consumption          | Higher resource requirements and control complexity            |
| Versa        | Highest computational throughput                             | Highest LUT utilization, FF utilization, and power consumption |

## Which Architecture Is Better?

The answer depends on the design objective.

### For minimum FPGA resource utilization: DiP

DiP requires the fewest LUTs and flip-flops, making it attractive for resource-constrained FPGA applications.

### For minimum power consumption: DiP

With 0.136 W reported power, DiP provides the lowest power consumption among the four implementations.

### For balanced performance: Hybrid

Hybrid provides higher throughput than DiP and TRIM while maintaining moderate power consumption.

### For maximum throughput: Versa

Versa achieves 0.8050 GOPS, the highest throughput among the four architectures.

However, this improvement comes with increased hardware resource requirements and power consumption.

---

# 12. Conclusion

This project presents the FPGA implementation and comparative analysis of four different systolic architectures for matrix multiplication.

The experimental results demonstrate that architectural dataflow and processing-element organization have a significant impact on hardware resource utilization, computational latency, power consumption, and throughput.

DiP provides the most resource-efficient implementation and the lowest reported power consumption.

TRIM demonstrates a structured weight-stationary approach but achieves the lowest reported throughput.

Hybrid provides an intermediate design point, offering improved throughput compared with DiP and TRIM while maintaining moderate resource and power requirements.

Versa achieves the highest computational throughput, making it suitable for applications where computational performance is prioritized over minimum hardware utilization.

Overall, the comparison demonstrates that architecture selection involves balancing computational performance, power requirements, and available FPGA resources.

No single architecture is universally optimal. The most suitable implementation depends on the target application's requirements.

---

# 13. Future Work

Potential improvements and future research directions include:

* Increasing the systolic array dimensions.
* Evaluating larger matrix multiplication workloads.
* Exploring DSP48E1-based multiply-accumulate operations.
* Optimizing memory access and data movement.
* Improving pipeline scheduling.
* Evaluating dynamic power using realistic switching activity.
* Comparing implementations on higher-capacity FPGA platforms.
* Investigating performance scaling with matrix dimensions.

---

## 14. Acknowledgements

The project uses AMD Xilinx Vivado Design Suite and the Digilent Nexys A7-100T FPGA development board for hardware design, simulation, synthesis, implementation, and evaluation.

**Target FPGA:** Xilinx Artix-7 XC7A100T
**Development Board:** Digilent Nexys A7-100T
**Hardware Description Language:** Verilog HDL
**Implementation Tool:** AMD Xilinx Vivado
