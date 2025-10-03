# Assignment 2: Experiment Planning & Execution Progress

This directory documents the current progress on Assignment 2, focusing on the **experimental infrastructure**, **run table generation**, and **pilot testing** across three deployment tiers. While the Assignment 2 report outlines the theoretical experimental design, this documentation captures the practical implementation details and current state of execution.

---

## Current Progress Overview

**Status:** All three tiers validated through controlled testing.

- **Tier 1 (Mock Environment):** Complete - 216 synthetic runs executed successfully
- **Tier 2 (Production Testbed):** Infrastructure validated with real RAPL measurements
- **Tier 3 (Fallback Configuration):** Controlled tests completed on single JAR, ready for full deployment

---

## Three-Tier Infrastructure

Our experimental setup follows a three-tier validation strategy to ensure reproducibility and minimize deployment risks:

### Tier 1: Mock Environment (Development & Validation)

**Purpose:** Cross-platform pipeline validation without requiring Linux hardware access.

- **Implementation:** Mock RAPL interface simulating energy measurements
- **Platform:** macOS/Windows compatible for distributed development
- **Data:** Synthetic energy values based on empirical models from literature
- **Use Case:** Validates ExperimentRunner logic, randomization, CSV schema, and analysis pipeline
- **Status:** Complete (216 runs executed, run_table.csv generated)

**Key Achievement:** Confirmed that our experimental design, factor randomization, and data aggregation work end-to-end before committing production hardware time.

### Tier 2: Production Testbed (Measurement Environment)

**Purpose:** Real energy measurements via Intel RAPL on dedicated hardware.

- **Orchestrator:** Raspberry Pi 4 running ExperimentRunner
- **Device Under Test (DUT):** Linux laptop with Intel Core i7-10750H
- **Measurement:** EnergiBridge collecting RAPL counters from `/sys/class/powercap`
- **Communication:** SSH over dedicated network (orchestrator → DUT)
- **Status:** Infrastructure validated with real RAPL measurements

**Design Rationale:** Separates orchestration from measurement to avoid interference from scheduling overhead.

### Tier 3: Fallback Configuration (Contingency)

**Purpose:** Co-located orchestration and measurement if Raspberry Pi integration fails.

- **Implementation:** ExperimentRunner and EnergiBridge both run on DUT
- **Trade-off:** Minimal orchestration overhead vs. ideal separation of concerns
- **Mitigation:** Logging deferred to cooldown periods to reduce interference
- **Status:** Controlled tests completed on single JAR, validated as operational backup

---

## Experimental Orchestration & Measurement Tools

Our experiment relies on two complementary frameworks for execution control and energy measurement:

### ExperimentRunner

**Purpose:** Automated experiment orchestration and execution management

[ExperimentRunner](https://github.com/S2-group/experiment-runner) is a Java-based framework that handles the systematic execution of controlled experiments. It provides:

- **Factor Management:** Reads experimental factors from configuration files (JSON/YAML)
- **Randomization:** Generates fully randomized run schedules with specified replications
- **Isolation:** Executes each run in a fresh JVM process to prevent state leakage
- **Synchronization:** Coordinates timing between measurements and workload execution
- **Aggregation:** Collects results from multiple sources into structured CSV format

**Configuration for our experiment:**

Factors include 4 subjects (dacapo, petclinic, todoapp, imageproc), 3 GC strategies (SerialGC, ParallelGC, G1GC), 3 workload levels (light, medium, heavy), and 2 JDK implementations (openjdk17, oraclejdk11). With 3 replications per unique combination, this yields 216 total runs (4 × 3 × 3 × 2 × 3).

**Randomization:** ExperimentRunner shuffles execution order to distribute runs across temporal blocks, preventing systematic bias from thermal drift, time-of-day effects, or order-dependent JVM behavior.

### EnergiBridge

**Purpose:** Unified energy measurement interface for CPU and system-level power consumption

[EnergiBridge](https://github.com/S2-group/energibridge) is a lightweight framework that provides consistent access to hardware energy counters across different platforms. It handles:

- **RAPL Interface:** Reads Intel Running Average Power Limit counters from `/sys/class/powercap/intel-rapl`
- **Multi-domain Measurement:** Captures package-level, CPU core, and DRAM energy separately
- **Synchronized Sampling:** Aligns energy measurements with workload execution boundaries
- **Structured Output:** Generates timestamped CSV files for each measurement interval
- **Cross-platform Abstraction:** Provides uniform API regardless of underlying measurement technology

**Measured Domains:**
- `package-0`: Total CPU package energy (cores + integrated components)
- `core`: Energy consumed by CPU cores only
- `dram`: Memory subsystem energy (when available)

**Output Format:** EnergiBridge generates individual CSV files per run, which ExperimentRunner aggregates into the unified `run_table.csv`.

**Integration:** ExperimentRunner invokes EnergiBridge at the start of each trial, collects measurements during execution, and terminates collection when the workload completes. This tight integration ensures energy data is synchronized with performance metrics.

---

## Run Table Generation & Structure

The `run_table.csv` is the core artifact of our experimental design, generated automatically by ExperimentRunner with energy data from EnergiBridge.

### Generation Process

**Workflow:**

1. ExperimentRunner reads factor configuration and generates randomized run schedule
2. For each run:
   - Start EnergiBridge measurement
   - Execute Java workload with specified GC/JDK/workload configuration
   - Stop EnergiBridge measurement
   - Collect exit code and execution time
3. Aggregate all runs into single CSV file

### CSV File Structure

The generated `run_table.csv` contains the following columns:

| Column | Type | Description | Example Value |
|--------|------|-------------|---------------|
| `__run_id` | String | Unique identifier for each trial | `run_42_repetition_1` |
| `__done` | String | Execution status flag | `DONE` |
| `subject` | String | Experimental subject (benchmark/app) | `dacapo` |
| `gc_strategy` | String | Garbage collection algorithm | `SerialGC`, `ParallelGC`, `G1GC` |
| `workload` | String | Allocation intensity level | `light`, `medium`, `heavy` |
| `jdk` | String | JDK implementation | `openjdk17`, `oraclejdk11` |
| `energy_joules` | Float | Total energy consumed (J) | `7.662583` |
| `execution_time` | Float | Runtime duration (s) | `0.649036` |
| `power_watts` | Float | Average power draw (W) | `11.806094` |
| `exit_code` | Integer | Process exit status (0 = success) | `0` |

**Additional Columns:**
- Path to run output directory (logs, intermediate files)
- Sequential run number for tracking execution order

**CSV Properties:**

- Total rows: 216 (Tier 1), 324 planned (full execution)
- Delimiter: Comma (`,`)
- Header row: Present
- Missing values: None (all runs completed successfully)
- Encoding: UTF-8

**Derived Metrics:** Additional metrics (e.g., energy per operation, throughput) are calculated during statistical analysis based on these core measurements.

---

## Experimental Variables

### Independent Variables (Factors)

These variables are **manipulated** across runs to observe their effects:

**1. GC Strategy** (Nominal, 3 levels)

- `SerialGC`: Single-threaded mark-sweep-compact
- `ParallelGC`: Multi-threaded throughput collector
- `G1GC`: Garbage-First region-based collector
- **JVM Flags:** `-XX:+UseSerialGC`, `-XX:+UseParallelGC`, `-XX:+UseG1GC`

**2. Workload Level** (Ordinal, 3 levels)

- `light`: Low allocation rate, minimal GC stress
- `medium`: Moderate allocation, regular GC activity
- `heavy`: High allocation rate, frequent collections
- **Operationalization:** Varies by subject (iteration counts, dataset sizes, concurrent clients)

**3. JDK Implementation** (Nominal, 2 levels)

- `openjdk17`: OpenJDK 17 (Temurin distribution)
- `oraclejdk11`: Oracle JDK 11
- **Rationale:** Tests generalizability across mainstream JVM distributions

**4. Subject** (Nominal, 4 levels)

- `dacapo`: DaCapo Chopin benchmark suite
- `petclinic`: Spring Boot REST web service
- `todoapp`: JavaFX GUI application
- `imageproc`: Batch image processing tool

### Dependent Variables (Measurements)

These variables are **observed** as outcomes:

1. **Energy Consumption** (J) - Primary outcome, measured via RAPL
2. **Execution Time** (s) - Runtime duration
3. **Average Power** (W) - Calculated as Energy ÷ Time
4. **Throughput** (ops/s) - Operations completed per second
5. **Latency** (ms) - Response time percentiles (p95, p99)
6. **GC Pause Time** (ms) - Duration of stop-the-world pauses

**Measurement Source:**

- **Tier 1:** Synthetic values generated by mock interface
- **Tier 2:** Real measurements from EnergiBridge + JVM logs
- **Tier 3:** Same as Tier 2, co-located execution

---

## Experimental Subjects (JAR Files)

All benchmark and application JARs used in this experiment are version-controlled and accessible via:

**[Google Drive - Experimental Subjects](https://drive.google.com/drive/folders/1HIcJ1-OL1r8-Wo8bR1z-Ui4oXSX42G2H?usp=sharing)**

### Included Subjects:

1. **DaCapo Chopin** - Standardized Java benchmark suite
2. **Computer Language Benchmarks Game** - Micro-benchmarks (binary-trees, fannkuch-redux, n-body)
3. **Rosetta Code** - Algorithmic tasks for GC stress testing
4. **Spring PetClinic** - Real-world REST web service with database persistence
5. **REST To-Do App** - Lightweight microservice for CRUD operations
6. **ANDIE Image Editor** - GUI application with compute-intensive filters

**Note:** JARs are hosted externally due to file size constraints. SHA256 checksums provided in `subjects/checksums.txt`.

---

## Directory Structure

- **README.md** - This file
- **run_table_backup.csv** - Tier 1 mock run table (216 rows)
- **Tier_1_Mock/** - Mock environment details
  - README.md - Setup, methodology, CSV explanation
  - run_table.csv - Synthetic data runs (216 rows)
  - analysis_pilot.R - Preliminary statistical tests
- **Tier_2_Production/** - Production testbed
  - README.md - Hardware setup, RAPL config, results
  - run_table.csv - Real RAPL measurements
  - energibridge_logs/ - Raw EnergiBridge CSVs
- **Tier_3_Fallback/** - Fallback configuration
  - README.md - Co-located execution, single JAR tests
  - validation_runs.csv - Controlled test results
  - setup_notes.md - Configuration details

Each tier subdirectory contains detailed README explaining experiment status, setup, findings, complete run_table.csv with tier-specific results, CSV format documentation with column descriptions, and analysis scripts or validation outputs.

---

## Key Achievements

1. **Tier 1 Pipeline Validated:** ExperimentRunner + mock interface confirmed functional end-to-end (216 runs)
2. **Tier 2 Infrastructure Ready:** Real RAPL measurements validated on production hardware
3. **Tier 3 Controlled Tests:** Single JAR validation confirms fallback configuration works
4. **Randomization Working:** All runs executed in randomized order as designed
5. **Data Schema Confirmed:** CSV structure ready for statistical analysis in R
6. **Factor Coverage:** All 72 unique treatment combinations tested with 3 replications each

---

## Next Steps

1. Execute full 324-run campaign on Tier 2 production testbed
2. Document detailed findings in tier-specific READMEs
3. Validate baseline stability across extended runs
4. Proceed to Assignment 3 statistical analysis

---

## References

- **ExperimentRunner:** https://github.com/S2-group/experiment-runner
- **EnergiBridge:** https://github.com/S2-group/energibridge
- **Assignment 2 Report:** `../Assignments/Assignment_2_Report.pdf`
- **Experimental Subjects:** [Google Drive](https://drive.google.com/drive/folders/1HIcJ1-OL1r8-Wo8bR1z-Ui4oXSX42G2H?usp=sharing)

---

## Contact

For questions about the experimental setup or run table generation, contact the team via the main repository README or course Canvas page.
