# Assignment 1: Experiment Description and GQM Framework

**Energy Efficiency of Java Garbage Collection Strategies**

This directory contains the deliverables for Assignment 1 of the Green Lab course, focusing on the experiment definition and the Goal–Question–Metric (GQM) framework for our Java garbage collection energy-efficiency study.

---

## Assignment Scope

**Deliverable:** Experiment goal, scope description, and related work  
**Due Date:** 15 September 2025, 23:59 CEST  
**Weight:** 20% of final grade

---

## Key Components

### 1) Introduction
- **Problem:** Energy optimization in Java runtime configurations
- **Context:** Growing importance of green software practices
- **Motivation:** Gap between performance tuning and energy efficiency
- **Stakeholders:** Software developers, DevOps engineers, researchers

### 2) Related Work
Representative papers on Java GC & energy (full citations in `references.bib`; verify venues/spelling before finalizing):
- Contreras et al. (2006) — early GC energy measurement  
- Kumar (2020) — GC sustainability in cloud environments  
- Ournani et al. (2021) — comprehensive JVM energy evaluation *(verify citation)*  
- Shimchenko et al. (2022) — modern GC energy prediction  
- Nou et al. (2017) — JVM GC power consumption analysis

### 3) Goal–Question–Metric (GQM)

**Goal:** Analyze Java GC strategies for energy efficiency and performance trade-offs from the perspective of developers, DevOps engineers, and researchers.

**Research Questions**
- **RQ1:** Which GC strategy minimizes energy consumption across Java applications?  
- **RQ2:** How does workload level influence the energy efficiency of different GC strategies?  
- **RQ3:** What are the trade-offs between energy and performance for each GC strategy?  
- **RQ4:** How does JDK implementation affect the energy efficiency of GC strategies?

**Metrics:** Energy (J), Power (W), Runtime (s), Throughput (ops/s), Latency (ms), GC pause times (ms)

---

## Experimental Setup Overview

- **Subjects:** 3 GC strategies — Serial, Parallel, G1  
- **Environment:** Linux testbed with RAPL-based energy measurement  
- **Tools:** Experiment Runner + EnergiBridge  
- **Design:** Randomized Complete Block Design (RCBD)  
- **Scale:** 6 blocks × 3 GCs × 3 loads × 2 JDKs × 3 reps = **324** runs

**Quick start (developer snippet):**
```bash
# Example run (G1 on OpenJDK 21)
java -XX:+UseG1GC -Xms2g -Xmx2g -jar subject.jar --workload heavy

# EnergiBridge wrapper (RAPL) around the run
energibridge --summary -o run.csv -- \
  java -XX:+UseG1GC -jar subject.jar --workload heavy
```

## ✅ Checklist & Submission Work Done

**Checklist PDF:** [Checklist for Green Lab projects](./docs/Checklist_for_Green_Lab_projects.pdf)  
*(Place the PDF at `docs/Checklist_for_Green_Lab_projects.pdf` in this repo.)*

**Assignment 1 — Status Snapshot**

- [x] Context & motivation described
- [x] Problem statement linked to context
- [x] Stakeholders identified
- [x] Goal stated (mentions energy) + GQM table
- [x] RQs are quantitative and include relevant metrics
- [x] Metrics listed with units; relationships (E = P × t) stated
- [ ] Strong claims double-checked & properly cited (fix intro stats)
- [ ] Related work: ≥5 papers with explicit similarity/difference lines (verify all citations)
- [ ] Technological context illustrated (tool snippet/figure)
- [ ] Figures render & are referenced once (Overview + RCBD)
- [ ] Template artifacts removed; metadata consistent (year/authors)
- [x] Repo structure + README in place

**Submission Tasks**

- [ ] Export final PDF to `report/report.pdf`
- [ ] Push all LaTeX sources and figures (`report/sources/`)
- [ ] Upload PDF to Canvas (due **15 Sep 2025, 23:59 CEST**)



## Next Steps (Assignment 2)

Detailed experimental design and variables definition

Hypotheses formulation (null/alternative pairs)

Run-table specification

Threats to validity analysis

Timeline and resource planning


## Submission Details

Format: PDF report (≈5 pages)

Submission: Canvas, before 23:59 on 15 September 2025

Team: Group 5

Course: Green Lab 2025/2026

