# Experiment Definition: Java Garbage Collection Strategies

## 🎯 Goal
Evaluate how different garbage collection (GC) strategies in Java impact **energy consumption** and **performance trade-offs** when running standard benchmarks and real applications.

---

## ❓ Research Questions (RQs)

- **RQ1:** Which garbage collection strategy (Serial, Parallel, G1, ZGC, Shenandoah) minimizes **energy consumption** across Java applications?  
- **RQ2:** How does the **workload level** (light, medium, heavy) influence the energy efficiency of different GC strategies?  
- **RQ3:** What are the **trade-offs between energy and performance** (execution time, throughput, latency) for each GC strategy?  
- **RQ4 (optional):** Do different JVM implementations (OpenJDK vs Oracle JDK) alter the relationship between GC strategy and energy efficiency?

---

## 📐 Variables

- **Independent variable (treatment):** GC strategy (Serial, Parallel, G1, ZGC, Shenandoah).  
- **Dependent variables (measured):**
  - Energy consumed (Joules, measured with RAPL/powercap).  
  - Execution time (ms, wall-clock or JMH).  
  - CPU utilization (%).  
  - Memory usage (peak RSS, heap usage).  
  - GC pauses (from GC logs).  
- **Co-factors (controlled/varied):**
  - Workload size (light, medium, heavy).  
  - JVM brand/version (OpenJDK vs Oracle JDK).  
  - Heap size (fixed, e.g., `-Xms2g -Xmx2g`).  

---

## 📊 Hypotheses

### RQ1 (GC vs energy)
- **H0₁:** There is no significant difference in mean energy consumption across GC strategies.  
- **H1₁:** At least one GC strategy differs significantly in mean energy consumption.  

### RQ2 (workload effect)
- **H0₂:** Workload level has no effect on the relative energy efficiency of GC strategies.  
- **H1₂:** Workload level moderates the effect of GC strategy on energy consumption (interaction effect).  

### RQ3 (energy–performance trade-off)
- **H0₃:** GC strategies do not differ in the ratio of energy consumed to execution time (Joules per second).  
- **H1₃:** Some GC strategies show a better energy–performance trade-off (lower Joules per unit time).  

### RQ4 (JVM brand)
- **H0₄:** JVM implementation does not change the effect of GC strategy on energy consumption.  
- **H1₄:** JVM implementation changes the relative performance of GC strategies (interaction effect).  

---

## 📏 Testing Approach

- **Design:** Factorial (GC strategy × workload level × subjects).  
- **Analysis:** ANOVA (or Kruskal–Wallis if non-normal) for comparing means; post-hoc Tukey/Dunn for pairwise GC comparisons.  
- **Effect sizes:** η² or Cliff’s δ to quantify practical impact.  
- **Validation:** Repeat runs (≥10 per configuration) to reduce noise; randomize run order.  
