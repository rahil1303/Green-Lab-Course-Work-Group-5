# 📊 Exploratory Data Analysis (EDA)

This directory contains the exploratory and statistical groundwork for the **Green Lab Java GC Energy Efficiency Experiment**. It bridges raw experimental data and formal inferential modeling by uncovering early energy–performance patterns across Java Garbage Collection strategies.

---

## 🎯 Purpose

The goal of this EDA was to:

* Inspect data structure and ensure measurement consistency across **486 runs**
* Explore factor-level effects of **GC** (Serial, Parallel, G1), **workload** (Light/Medium/Heavy), and **JDK** (OpenJDK vs Oracle)
* Derive and visualize core metrics:
   * **EDP** (Energy–Delay Product)
   * **NEE** (Normalized Energy Efficiency)
   * **CoP** (Coefficient of Performance)
   * **Power Ratio** and **Efficiency Index**

---

## 🔍 Key Insights

* **Workload intensity** dominated energy variation (≈ 25–30% higher for heavy workloads)
* **Parallel GC** showed slightly lower mean energy, while **G1** offered steadier energy–runtime balance
* **OpenJDK vs Oracle JDK** differences were negligible (< 1%)
* Derived indicators (EDP, NEE, CoP) clarified **trade-offs and scalability** rather than absolute savings
* Originally we had 576 data points, but upon normalization, we were left with around 490 data points to work with.

---

## 📊 Statistical Path

The analysis evolved through multiple methodological stages:

1. **Normality & Variance Checks** — Shapiro–Wilk and Levene's tests confirmed non-normal, heteroscedastic data
2. **ANOVA Attempt** — Repeated-measures ANOVA failed due to multiple observations per subject and non-independent cells
3. **Non-parametric Tests** — Kruskal–Wallis used for within-subject GC effects
4. **Final Adaptation** — Transitioned to **Linear Mixed-Effects Models (LMMs)** to handle nested subject structure and heterogeneity

> ⚠️ **Key Learning:** The dataset's repeated-measures nature and subject-level variance demanded a variance-aware modeling approach, making traditional ANOVA unsuitable.

---

## 🧠 Structure

| File | Purpose |
|------|---------|
| `EDA_Data_1.ipynb` | Main exploratory notebook – preprocessing, visualization, metric derivation |
| `EDA_Data_Work_2.pdf` | Static export showing diagnostic output, test results, and transition rationale |
| `run_table_z.csv` | Consolidated dataset of 486 runs (loaded from DUT experiments) |

---

## 🪜 Next Steps

The outcomes from this EDA directly informed the **statistical modeling phase** (in R / Python), where Linear Mixed-Effects Models quantified factor significance and validated the observed efficiency patterns.
