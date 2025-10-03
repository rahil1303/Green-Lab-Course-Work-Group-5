# 🌱 Green Lab Project – Group 5

**Topic:** Energy Efficiency of Java Garbage Collection Strategies  
**Course:** Green Lab 2025/2026 – MSc Computer Science (VU Amsterdam)

# Energy Efficiency of Java Garbage Collection Strategies

**Green Lab 2025/2026** | MSc Computer Science | Vrije Universiteit Amsterdam

An empirical study investigating the energy-performance trade-offs of Java Garbage Collection strategies (Serial, Parallel, G1) across diverse workloads and JDK implementations.

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

- **Assignment_1/** - LaTeX sources for Assignment 1
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
