# Topic: Energy Efficiency of Java Garbage Collection Strategies

**Group 5 - Green Lab Course (VU MSc CS)**

Members:
Rahil S - 2850828
András Zsolt Sütő - 2856739
Tobias Meyer Innleggen - 2855564
Vivek A Bharadwaj - 2841186
Avaneesh Shetye - 2843910

Replication package and report sources for our empirical study comparing the energy consumption and performance trade-offs of Java garbage collection strategies.

> **Course Assignments:**
> * **A1**: Experiment description + GQM framework *(Due: Sept 15)*
> * **A2**: Experiment design + execution plan *(Due: Oct 2)*
> * **A3**: Final report + replication package + presentation video *(Due: Oct 24)*

---

## 1. Project Overview

We investigate the **energy efficiency of Java garbage collection strategies** by comparing Serial, Parallel, and G1 collectors across diverse benchmarks and real-world applications. Our study measures energy consumption, runtime performance, and GC behavior under varying workload conditions and JDK implementations.

**Research Questions:**
- Which GC strategy minimizes energy consumption across Java applications?
- How does workload intensity influence energy efficiency of different GC strategies?
- What are the trade-offs between energy and performance for each GC strategy?
- How does JDK implementation affect energy efficiency of GC strategies?

---

## 2. Experimental Setup

### 2.1 Requirements
* **OS**: Linux (required for RAPL energy measurements)
* **Java**: OpenJDK 17+ and Oracle JDK 17+
* **Python**: 3.11+ (for ExperimentRunner orchestration)
* **R**: 4.3+ (for statistical analysis)
* **Tools**:
  * [ExperimentRunner](https://github.com/S2-group/experiment-runner) (experiment orchestration)
  * [EnergiBridge](https://github.com/tdurieux/EnergiBridge) (energy measurement)

### 2.2 Setup Environment
```bash
git clone https://github.com/<YOUR_USERNAME>/Green-Lab-Course-Work-Group-5.git
cd Green-Lab-Course-Work-Group-5

# Install dependencies
pip install -r requirements.txt

# Install EnergiBridge (follow platform-specific instructions)
# Install ExperimentRunner
git clone https://github.com/S2-group/experiment-runner.git
```

### 2.3 Run Experiments

```bash
# Execute full experimental suite (324 runs)
python experiment_runner/RunnerConfig.py

# Alternative: Run individual GC strategies
./scripts/run_gc_experiment.sh Serial
./scripts/run_gc_experiment.sh Parallel
./scripts/run_gc_experiment.sh G1
```

Output Structure
```bash
results/
├── raw_data/           # Individual EnergiBridge CSV files
├── run_table.csv       # Consolidated experimental data
├── logs/               # Execution logs and metadata
└── analysis/           # R analysis outputs
```

### 2.4 Data Analysis
```bash

# Run statistical analysis
Rscript analysis/statistical_analysis.R

# Generate figures and tables
Rscript analysis/generate_plots.R
```

## 3. Repository Structure
```bash
Green-Lab-Course-Work-Group-5/
├── README.md
├── LICENSE
├── .gitignore
├── requirements.txt
├── assignments/
│   ├── A1_experiment_description/
│   │   ├── report.pdf
│   │   └── sources/
│   ├── A2_experiment_design/
│   └── A3_final_report/
├── experiment/
│   ├── RunnerConfig.py         # ExperimentRunner configuration
│   ├── subjects/               # Java applications and benchmarks
│   │   ├── benchmarks/         # DaCapo, CLBG, Rosetta Code
│   │   └── applications/       # Web server, Todo app, Image processor
│   └── scripts/                # JVM configuration and execution scripts
├── analysis/
│   ├── statistical_analysis.R  # Hypothesis testing and effect sizes
│   ├── generate_plots.R        # Visualization scripts
│   └── utils/                  # Helper functions
├── results/                    # Experimental outputs (gitignored)
└── docs/                       # Additional documentation
```

## 4. Experimental Design

Design: Randomized Complete Block Design (RCBD)

Treatments: 3 GC strategies (Serial, Parallel, G1)

Blocks: 6 Java subjects (3 benchmarks + 3 applications)

Co-factors: Workload level (light/medium/heavy) × JDK implementation (OpenJDK/Oracle)

Replications: 3 per condition

Total runs: 324 (3 × 6 × 3 × 2 × 3)

Energy Measurement: EnergiBridge with RAPL counters
Performance Metrics: Runtime, throughput, latency, GC pause times

## 5. Development Workflow
Mock Energy Interface

For development on non-Linux systems, we provide a mock RAPL interface:
```bash

# Enable mock mode for development
export ENERGY_MOCK_MODE=true
python experiment_runner/RunnerConfig.py
```

Team Collaboration

Each team member can develop and test the complete pipeline locally.

Deploy on Linux machines for actual energy measurements.

## 6. Reproducibility

Our experimental setup follows Green Lab best practices:

Randomized execution order to mitigate temporal effects

Cool-down periods between runs to prevent thermal interference

Controlled environment with minimized background processes

Statistical rigor with appropriate sample sizes and hypothesis testing

Complete replication package with all code, data, and analysis scripts

## 7. Ethics & Academic Integrity

We adhere to VU Amsterdam academic integrity policies:

Original research: All experimental work conducted by team members

Proper attribution: All tools and prior work appropriately cited

AI assistance: Limited to coding support and grammar checking (disclosed where used)

Data integrity: Raw experimental data preserved and version controlled

## 8. License

This project is licensed under the MIT License — see the LICENSE
 file for details.





