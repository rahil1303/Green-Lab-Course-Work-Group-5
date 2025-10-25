# Statistical Analysis in R — Java GC Energy Efficiency

## 📋 Overview

This directory contains the **statistical modeling and inference** for Assignment 3, advancing from exploratory patterns (Python EDA) to formal hypothesis testing using **Linear Mixed-Effects Models (LMMs)**. The analysis answers four research questions about garbage collection (GC) energy efficiency in Java applications.

## 📂 Directory Contents

| File | Description |
|------|-------------|
| **`Statistical Analysis in R — Java GC Energy Efficiency.html`** | Complete analysis report with narrative, code, visualizations, and findings |
| **`Statistical Analysis in R — Java GC Energy Efficiency.pdf`** | PDF version for offline viewing and archival |
| **`R_Analysis_backup_2.Rmd`** | Source R Markdown file (reproducible notebook with all code blocks) |
| **`Readme.Md`** | This file — navigation guide |

## 🎯 Research Questions Addressed

1. **RQ1:** Which GC strategy (Serial, Parallel, G1) minimizes energy consumption?
2. **RQ2:** How does workload level (Light/Medium/Heavy) influence GC energy efficiency?
3. **RQ3:** What are the energy-performance trade-offs for each GC strategy?
4. **RQ4:** How does JDK implementation (OpenJDK vs Oracle) affect outcomes?

## 🔬 Analytical Approach

- **Mixed-Effects Models** account for repeated measures across 8 Java applications (subjects)
- **Post-hoc contrasts** (Tukey-adjusted) provide pairwise GC comparisons
- **Effect size analysis** (Cohen's d) quantifies practical significance beyond p-values
- **Interaction testing** examines whether GC performance depends on workload or application type
- **Bootstrap resampling** and **equivalence tests** validate findings with robust inference

## ✨ Key Findings (Optimistic Highlights)

✅ **Parallel GC emerges as efficiency leader** — consistent energy advantage (4% lower than G1) compounds to meaningful savings at scale

✅ **No energy-performance trade-offs** — faster execution correlates with lower energy (r = 0.31), enabling win-win optimization

✅ **Workload management offers 5× greater impact** than GC tuning — complementary optimization levers

✅ **JDK implementation agnostic** — OpenJDK and Oracle perform identically (p = 0.62), providing deployment flexibility

✅ **Application-specific insights** — service apps show 20% GC sensitivity where benchmarks show none, guiding targeted optimization

## 🚀 Getting Started

### View the Analysis

1. **Open the HTML report** for interactive navigation with table of contents
2. **Consult the PDF** for offline review or printing
3. **Explore the .Rmd source** to reproduce or extend the analysis

### Reproduce the Analysis
```r
# Install required packages
install.packages(c("tidyverse", "lme4", "lmerTest", "emmeans", 
                   "car", "effectsize", "ggpubr", "TOSTER", "pwr", "boot"))

# Open and knit the R Markdown file
# File → Open → R_Analysis_backup_2.Rmd
# Click "Knit" to regenerate the HTML/PDF
```

## 📊 What to Expect

- **Comprehensive statistical rigor:** Formal hypothesis tests, model diagnostics, power analysis
- **Clear visualizations:** Interaction plots, heatmaps, effect size comparisons
- **Actionable insights:** Data-driven GC recommendations for different application contexts
- **Transparent methods:** Full code + narrative explaining every analytical decision

## 🌟 Bottom Line

This analysis reveals an **encouraging optimization landscape** — Parallel GC provides measurable efficiency gains without performance penalties, workload tuning amplifies benefits, and flexible JDK deployment is supported. The consistency across experimental conditions enables **confident, data-driven decisions** for sustainable Java computing.

---

**Next Steps:** Combine these statistical findings with Python EDA patterns and experimental setup documentation for a complete replication package.
