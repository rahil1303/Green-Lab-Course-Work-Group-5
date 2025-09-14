# Energy Efficiency of Java Garbage Collection Strategies

**Group 5 - Green Lab Course (VU MSc CS)**

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

## 2.3 Run Experiments

```bash
# Execute full experimental suite (324 runs)
python experiment_runner/RunnerConfig.py

# Alternative: Run individual GC strategies
./scripts/run_gc_experiment.sh Serial
./scripts/run_gc_experiment.sh Parallel
./scripts/run_gc_experiment.sh G1
