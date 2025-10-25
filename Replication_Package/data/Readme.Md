# Data Directory — Java GC Energy Efficiency Study

## 📋 Overview

This directory contains the **processed experimental data** used for statistical analysis in Assignment 3. The dataset comprises **486 valid experimental runs** measuring energy consumption, runtime, and performance metrics across three garbage collection strategies (Serial, Parallel, G1), three workload levels (Light, Medium, Heavy), and eight Java applications.

## 📂 Directory Contents

| Item | Description |
|------|-------------|
| **`run_table_w.csv`** | Primary dataset (486 rows × 22 columns) — cleaned, validated, and ready for analysis |
| **`Exploratory_Data_Analysis/`** | Python-based EDA outputs (visualizations, summary statistics, data quality checks) |
| **`R_Data_Analysis/`** | R-based statistical modeling (mixed-effects models, hypothesis tests, inference) |
| **`raw_data/`** | Original unprocessed experimental outputs from ExperimentRunner |
| **`Readme.Md`** | This file — data documentation and guide |

## 📊 Dataset Overview: `run_table_w.csv`

### Data Collection & Cleaning

- **Original runs collected:** 576 experimental executions
- **Outliers removed:** ~90 runs (timeout failures, measurement errors, extreme anomalies)
- **Final validated dataset:** **486 runs** with complete energy, runtime, and performance metrics
- **Quality assurance:** Missing value checks, range validation, duplicate detection

### Experimental Design

- **Factors:**
  - **GC Strategy:** Serial, Parallel, G1 (3 levels)
  - **Workload:** Light, Medium, Heavy (3 levels)
  - **JDK:** OpenJDK, Oracle (2 levels)
  - **Subject (Application):** 8 diverse Java applications
- **Replication:** Multiple runs per configuration to ensure statistical reliability
- **Blocking:** Randomized Complete Block Design (RCBD) with applications as blocks

### Key Variables (22 columns)

| Variable | Description | Unit |
|----------|-------------|------|
| `entry_id` | Unique run identifier | — |
| `run_id` | Experiment run label | — |
| `subject` | Java application name | — |
| `gc` | Garbage collector strategy | Serial/Parallel/G1 |
| `workload` | Load intensity level | Light/Medium/Heavy |
| `jdk` | JDK implementation | OpenJDK/Oracle |
| `energy_j` | Total energy consumption | Joules (J) |
| `runtime_s` | Execution time | Seconds (s) |
| `power_w` | Instantaneous power | Watts (W) |
| `edp` | Energy-Delay Product | J·s |
| `throughput` | Operations per second | ops/s |
| `energy_per_op` | Energy efficiency | J/op |
| `nee` | Normalized Energy Efficiency | — |
| `cop` | Coefficient of Performance | — |
| `is_frontier` | Pareto-optimal flag | Boolean |
| `eff_index` | Composite efficiency score | — |
| *(+ 6 additional derived metrics)* | — | — |

## 🔍 Data Subdirectories

### **`Exploratory_Data_Analysis/`**
Python-based exploratory analysis revealing:
- Distribution patterns (energy, runtime, power)
- Outlier detection and validation
- Correlation structures (energy-performance relationships)
- Initial hypothesis generation

### **`R_Data_Analysis/`**
Formal statistical modeling answering:
- **RQ1:** Which GC minimizes energy? → **Parallel GC (1351 J)**
- **RQ2:** How does workload influence efficiency? → **Dominant factor (+277 J Heavy vs Light)**
- **RQ3:** Energy-performance trade-offs? → **None — positive correlation (r = 0.31)**
- **RQ4:** JDK implementation effects? → **No difference (p = 0.62)**

### **`raw_data/`**
Original unprocessed outputs from ExperimentRunner, preserved for:
- Transparency and reproducibility
- Re-analysis with alternative cleaning criteria
- Validation of preprocessing decisions

## 📈 Data Quality Metrics

✅ **Completeness:** 486/486 runs (100%) have complete energy + runtime measurements  
✅ **Balance:** 162 runs per GC strategy (54 per GC-workload combination)  
✅ **Validity:** All values within physically plausible ranges (energy: 238–3959 J; runtime: 120–8350 s)  
✅ **Reliability:** High inter-run consistency (CV < 50% for most configurations)

## 🚀 Getting Started

### Load the Dataset

**Python:**
```python
import pandas as pd
df = pd.read_csv('run_table_w.csv')
print(f"Loaded {len(df)} runs with {len(df.columns)} variables")
```

**R:**
```r
library(tidyverse)
df <- read_csv("run_table_w.csv")
glimpse(df)  # 486 rows × 22 columns
```

### Explore the Data

1. **Start with EDA outputs** in `Exploratory_Data_Analysis/` to understand patterns
2. **Consult R analysis** in `R_Data_Analysis/` for statistical inference
3. **Reference raw data** in `raw_data/` for preprocessing validation

## 🌟 Key Insights from This Dataset

✅ **486 high-quality runs** enable robust statistical inference with 96% power for medium effects

✅ **Workload explains 2.9% of variance**, GC explains 0.21% — application type dominates (45%)

✅ **No missing data** in primary response variables (energy_j, runtime_s)

✅ **Balanced design** supports valid factorial analysis and interaction testing

✅ **Diverse applications** (benchmarks + service apps) ensure findings generalize beyond synthetic workloads

## 📝 Data Citation

When using this dataset, please reference:

> **Assignment 3: Java Garbage Collection Energy Efficiency Study**  
> Experimental data collected via ExperimentRunner framework  
> 486 validated runs across 3 GC strategies × 3 workload levels × 8 applications  
> Cleaned dataset: `run_table_w.csv` (original: 576 runs, outliers removed)

---

**Next Steps:** Explore subdirectories for detailed analysis pipelines (Python EDA, R statistical modeling) or dive directly into `run_table_w.csv` for custom analyses.
