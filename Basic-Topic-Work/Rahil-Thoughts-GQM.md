# 🧩 GQM Framework (with Code-Base & Profiling Analysis)

## 🎯 Goal
Analyze the impact of **different Java Garbage Collection (GC) strategies**  
for the purpose of **improving energy efficiency and understanding workload-specific trade-offs**  
with respect to **energy consumption, execution time, and resource usage**  
from the point of view of **software engineers and researchers**  
in the context of **Java applications whose behavior is studied via code-base and runtime profiling**.

---

## ❓ Questions

- **Q1:** Which GC strategy minimizes overall energy consumption across Java applications?  
- **Q2:** How does **workload intensity** (light, medium, heavy inputs) influence GC energy efficiency?  
- **Q3:** What are the **trade-offs** between energy consumption and performance metrics (execution time, CPU load, memory usage, GC pauses)?  
- **Q4:** Does **JVM implementation** (OpenJDK vs Oracle JDK) affect the efficiency of different GCs?  
- **Q5:** Do **program characteristics** (CPU-bound vs memory-bound vs mixed), identified through **code-base inspection and profiling** (object allocation rates, GC logs, CPU hotspots), influence which GC is most energy-efficient?

---

## 📏 Metrics

- **Energy (Joules)** → via Intel RAPL / powercap.  
- **Execution Time (ms)** → wall-clock or JMH.  
- **CPU Utilization (%)** → average during run.  
- **Memory Usage (MB)** → peak heap usage, RSS.  
- **GC-specific metrics** → number of collections, pause durations, throughput (from `-Xlog:gc*`).  
- **Profiling metrics (for app classification):**
  - Object allocation rates (objects/sec, bytes/sec).  
  - Frequency of GC events.  
  - CPU hotspots (method-level profiling).  

**Derived Metrics**
- Joules per operation (normalized).  
- Energy–performance ratio (Joules per second).  
- GC efficiency index segmented by **program profile type**.

---

## 🔍 Mapping Goal → Questions → Metrics

| **Goal** | **Question** | **Metrics** |
|----------|--------------|--------------|
| Improve energy efficiency of Java GC strategies | Q1: Which GC uses least energy overall? | Total Joules consumed per run |
|  | Q2: Does workload intensity affect GC efficiency? | Energy & time per workload size (light/med/heavy) |
|  | Q3: What are the energy–performance trade-offs? | Joules per operation, exec time, CPU%, memory, GC pauses |
|  | Q4: Does JVM implementation matter? | Compare metrics across OpenJDK vs Oracle JDK |
|  | Q5: Do program characteristics (CPU-heavy vs memory-heavy vs mixed) influence GC efficiency? | Profiling-based classification (allocation rates, GC frequency, CPU hotspots) + energy/time metrics per category |
