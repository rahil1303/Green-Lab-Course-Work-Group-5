# 🌱 Green Lab Project – Group 5

**Topic:** Energy Efficiency of Java Garbage Collection Strategies  
**Course:** Green Lab 2025/2026 – MSc Computer Science (VU Amsterdam)

# Energy Efficiency of Java Garbage Collection Strategies

**Green Lab 2025/2026** | MSc Computer Science | Vrije Universiteit Amsterdam

An empirical study investigating the energy-performance trade-offs of Java Garbage Collection strategies (Serial, Parallel, G1) across diverse workloads and JDK implementations.

**For the Replication Package, move towards the Replication_Package directory for instructions and clone the repositiory.**

---

## Overview

Modern Java applications consume significant energy in production environments, yet garbage collection strategies are typically optimized for performance rather than energy efficiency. This project provides empirical evidence to help developers make energy-aware GC configuration decisions.

**Key Research Questions:**
- Which GC strategy minimizes energy consumption?
- How does workload intensity affect GC efficiency?
- What are the energy-performance trade-offs?
- Do results generalize across JDK implementations?

---

## Experimental Design

| Aspect | Details |
|--------|---------|
| **Design Type** | Randomized Complete Block Design (RCBD) |
| **Total Runs** | 324 (6 subjects × 3 GC × 3 workloads × 2 JDKs × 3 replications) |
| **Measurement** | Intel RAPL via EnergiBridge |
| **Duration** | ~20-25 hours |

**Independent Variables:**
- GC Strategy: Serial, Parallel, G1
- Workload Level: Light, Medium, Heavy
- JDK Implementation: OpenJDK 17, Oracle JDK 17

**Dependent Variables:**
- Energy consumption (J), Average power (W), Execution time (s), Throughput (ops/s), Latency percentiles (ms), GC pause times (ms)

**Experimental Subjects:**
- Benchmarks: DaCapo Chopin, CLBG, Rosetta Code
- Applications: Spring PetClinic, REST To-Do API, ANDIE Image Editor

---

## Repository Structure

- **Assignment_1/** - LaTeX and technical sources for Assignment 1
- **Assignment_2/** - Run_Table.csv discussion for every setup discussed in Assignment 2 and explaining the progress so far
- **Basic-Topic-Work/** - Initial exploration and setup
- **Mock-Server/** - Development mock RAPL interface
- **Overleaf/** - Overleaf-synced LaTeX files
- **Resources/** - Papers, references, datasets
- **analysis/** - Statistical analysis scripts (R)
- **data/** - Raw EnergiBridge outputs and processed results
- **scripts/** - Environment setup and experiment orchestration
- **src/** - Java subjects and benchmarks

---

## Quick Start

**Prerequisites:**
- Linux system with Intel CPU (RAPL support)
- Java 17 (OpenJDK + Oracle JDK)
- Python 3.8+, R 4.0+
- R packages: `tidyverse`, `ARTool`, `emmeans`

**Setup:**
```bash
git clone https://github.com/rahil1303/Green-Lab-Course-Work-Group-5.git
```


---

## Tools & Technologies

- **Orchestration:** [ExperimentRunner](https://github.com/S2-group/experiment-runner)
- **Energy Measurement:** [EnergiBridge](https://github.com/S2-group/energibridge)
- **Energy Counters:** Intel RAPL
- **Analysis:** Python and R (ARTool, emmeans, ggplot2)
- **Hardware:** Raspberry Pi 4 + Linux laptop

---

## Team

| Name | Student ID | Email |
|------|------------|-------|
| Rahil Sharma | 2850828 | r.sharma4@student.vu.nl |
| András Zsolt Sütő | 2856739 | a.z.suto@student.vu.nl |
| Tobias Meyer Innleggen | 2855564 | t.m.innleggen@student.vu.nl |
| Vivek A Bharadwaj | 2841186 | v.a.bharadwaj@student.vu.nl |
| Avaneesh Shetye | 2843910 | a.shetye@student.vu.nl |

**Time Logs:** [Google Sheets](https://docs.google.com/spreadsheets/d/1333u48gWQoafeC8ukJoe-fx9sy5RInaw/edit?usp=sharing&ouid=105392327583206963909&rtpof=true&sd=true)

---

## Key References

1. Shimchenko et al. (2022) - Analysing and Predicting Energy Consumption of Garbage Collectors in OpenJDK
2. Lengauer et al. (2017) - A Comprehensive Java Benchmark Study on Memory and GC Behavior
3. Ournani et al. (2021) - Evaluating the Impact of Java Virtual Machines on Energy Consumption

Full bibliography: `Resources/references.bib`

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

## Acknowledgments

Conducted as part of the Green Lab course at VU Amsterdam, supervised by the [S2 Research Group](https://s2group.cs.vu.nl/). Thanks to Vincenzo Stoico and Ivano Malavolta for guidance.
