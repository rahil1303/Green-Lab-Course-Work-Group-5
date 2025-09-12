# Experiment Plan – Java Garbage Collection and Energy Efficiency

## Overview
This project investigates the impact of different **Java Garbage Collection (GC) strategies** on the **energy consumption and performance** of Java applications. The experiment is carried out in the context of the Green Lab 2025/2026 course at VU Amsterdam.

We design controlled experiments to evaluate:
1. Which GC strategy minimizes energy consumption.
2. How workload intensity influences energy efficiency.
3. The trade-offs between energy efficiency and performance (execution time, throughput, latency).
4. (Optional) Whether JVM implementation (OpenJDK vs Oracle JDK) affects results.
5. (Extension Idea) How **application type or utility** (e.g., compute-intensive vs memory-intensive vs I/O-heavy) interacts with GC strategy effectiveness.

---

## Research Questions
- **RQ1**: Which garbage collection strategy (Serial, Parallel, G1, ZGC, Shenandoah) minimizes energy consumption across Java applications?
- **RQ2**: How does workload level (light, medium, heavy) influence the energy efficiency of different GC strategies?
- **RQ3**: What are the trade-offs between energy efficiency and performance for each GC strategy?
- **RQ4 (optional)**: Do different JVM implementations (OpenJDK vs Oracle JDK) alter the relationship between GC strategy and energy efficiency?
- **RQ5 (extension)**: Do certain **types of applications** (e.g., compute-heavy, memory-heavy, I/O-heavy) benefit more from specific GC strategies?

---

## Variables
- **Independent Variable (Treatment):** GC strategy.
- **Dependent Variables (Measured):**
  - Energy consumed (Joules, via RAPL/powercap).
  - Execution time (ms).
  - Throughput (ops/sec).
  - Latency (ms).
  - CPU utilization (%).
  - Memory usage (MB).
- **Co-factors:**
  - Workload level (light, medium, heavy).
  - Application type (micro-benchmarks, full apps).
  - JVM implementation (OpenJDK vs Oracle JDK).

---

## Experiment Design
1. **Subjects (Applications):**
   - **Benchmarks:** DaCapo Chopin, CLBG, Rosetta Code, JMH microbenchmarks.
   - **Full Java Applications:** (3–5 real-world apps).
   - **Categorization:**  
     - Compute-heavy (e.g., sorting, math benchmarks).  
     - Memory-heavy (e.g., object creation, graph processing).  
     - I/O-heavy (e.g., file read/write, DB access).  

2. **Environment:**
   - Development on macOS (for setup/testing).
   - Execution on **Linux lab machines** (with RAPL enabled) for energy measurements.
   - Optionally, Docker containers for reproducibility (on Linux hosts).

3. **Procedure:**
   - Run each (App × GC Strategy × Workload Level) configuration ≥30 times.
   - Collect raw logs: energy, execution time, CPU, memory.
   - Store results in CSV format for later analysis.

---

## ⚙️ Tools & Setup
- **Java:** OpenJDK 21 (default), Oracle JDK (for RQ4).
- **Benchmark Suites:** DaCapo, CLBG, JMH.
- **Measurement:** 
  - Energy: Intel RAPL via `powercap` interface (Linux only).  
  - Performance: JMH, `perf`, `time`, or Java profilers.
- **Automation:** Bash/Python scripts for experiment orchestration.
- **Reproducibility:** GitHub repo + (optional) Dockerfiles.

---

## Data Analysis
- **Descriptive statistics:** Mean, stddev, confidence intervals.  
- **Statistical tests:** ANOVA / Kruskal-Wallis for GC comparisons; Tukey HSD for pairwise.  
- **Visualizations:**  
  - Energy vs Execution Time scatterplots.  
  - Throughput vs Energy trade-off curves.  
  - Heatmaps for workload scaling.  
  - Grouped bar charts by application type.  

---

## Expected Outcomes
- Identification of the most energy-efficient GC strategy overall.  
- Insights into how workload intensity and app type shift GC efficiency.  
- Pareto-frontier plots showing trade-offs between **low energy** and **high performance**.  
- Guidelines for practitioners: *“If your app is X-type, prefer GC strategy Y.”*  

---

## Replication Package
The GitHub repository will include:
- Source code for automation scripts.
- Benchmark configurations.
- Raw measurement data.
- Processed CSVs + R scripts for statistical analysis.
- README instructions for replicating results.