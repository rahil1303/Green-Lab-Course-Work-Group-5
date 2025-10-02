# 🌱 Green Lab Project – Group 5

**Topic:** Energy Efficiency of Java Garbage Collection Strategies  
**Course:** Green Lab 2025/2026 – MSc Computer Science (VU Amsterdam)

---

## 📌 Overview

This repository contains the full replication package and deliverables for our Green Lab project.  
We investigate the **energy–performance trade-offs of Java Garbage Collection (GC) strategies** — Serial, Parallel, and G1 — across different workloads and JDK implementations.

The project is conducted using **ExperimentRunner** and **EnergiBridge** to collect reproducible energy measurements via Intel RAPL counters.

---

## 🧪 Experiment Scope

* **Goal:** Empirically evaluate the energy efficiency of Java GC strategies.
* **Factors:**
  * GC Strategy: {Serial, Parallel, G1}
  * Workload Level: {Light, Medium, Heavy}
  * JDK Implementation: {OpenJDK, Oracle JDK}
* **Design:** Randomized Complete Block Design (RCBD)
* **Subjects:**
  * Benchmarks: DaCapo Chopin, CLBG, Rosetta Code
  * Applications: Simple Web Server, Todo App (JavaFX), Image Editor
* **Metrics:** Energy (J), Power (W), Runtime (s), Throughput (ops/s), Latency (ms), GC pause times (ms)

---

## 📂 Repository Structure


```markdown
Repository Structure
.
├── Assignments/        # LaTeX sources & reports for A1–A3
├── Mock-Server/        # Mock RAPL energy interface for development
├── Overleaf/           # Overleaf-synced LaTeX project files
├── Resources/          # Reference material, papers, datasets
├── scripts/            # Experiment orchestration (setup, run_all, export)
├── src/                # Java subjects & benchmark integration
├── analysis/           # R/Python analysis scripts
├── data/               # Raw + processed experimental results
└── README.md           # This file
```
⚡ Tools & Dependencies

Experiment orchestration: ExperimentRunner

Energy measurement: EnergiBridge

Metrics: Intel RAPL counters

Languages: Java (OpenJDK & Oracle JDK), Python, R

Analysis: R (ANOVA, Tukey HSD), Python (matplotlib, pandas)

🚀 Reproduction Guide

Clone the repository:

```bash
git clone https://github.com/rahil1303/Green-Lab-Course-Work-Group-5.git
cd Green-Lab-Course-Work-Group-5
```

Setup environment:

./scripts/setup_env.sh

Run all experiments:

./scripts/run_all.sh

Analyze results:

Rscript analysis/analyze_results.R

Results will appear under data/results/ and figures in analysis/plots/.

📊 Time Logs

We maintain weekly time logs following the official course template:
Google Sheets – Time Log

🧑‍🤝‍🧑 Authors

Rahil Sharma – 2850828

András Zsolt Sütő – 2856739

Tobias Meyer Innleggen – 2855564

Vivek A Bharadwaj – 2841186

Avaneesh Shetye – 2843910

📖 References

Key references and related work can be found in the Resources/ folder and in our report.

Software Carbon Intensity (SCI)

Awesome Green Software Practices

📜 License

This project is released under the MIT License – see LICENSE file for details.
