# 💡 Proposal: Energy Efficiency of Java Garbage Collection Strategies

## 1. Motivation
Java provides multiple Garbage Collection (GC) strategies (Serial, Parallel, G1, ZGC, Shenandoah).  
Each GC trades off differently between **speed**, **memory management**, and **energy consumption**.  

- Some GCs are optimized for **throughput** (e.g., Parallel).  
- Others aim at **low latency** (e.g., ZGC, Shenandoah).  
- Others provide **simplicity but less scalability** (Serial).  

⚡ **Problem:** We don’t know which GC is most energy-efficient under different **workload types**.  
For example:
- A **database-like app** may create millions of short-lived objects (heap-intensive).  
- A **simulation app** may be CPU-heavy but generate fewer objects.  

Thus, GC energy efficiency might **depend on the kind of application (program utility)**.

---

## 2. Research Questions (RQs)

- **RQ1:** Which GC strategy consumes the least energy overall?  
- **RQ2:** How does workload intensity (light, medium, heavy) affect GC energy efficiency?  
- **RQ3:** What trade-offs exist between energy consumption and performance (time, CPU, memory)?  
- **RQ4:** Does JVM implementation (OpenJDK vs Oracle JDK) influence GC energy efficiency?  
- **RQ5:** Does the **type of application** (CPU-heavy, memory-heavy, mixed) affect which GC is most energy-efficient?

---

## 3. Hypotheses

- **H0₁:** No difference in mean energy use across GC strategies.  
- **H1₁:** At least one GC strategy differs in mean energy use.  

- **H0₂:** Workload level has no effect on relative GC energy efficiency.  
- **H1₂:** Workload level moderates the effect of GC strategy.  

- **H0₃:** No difference in energy–performance trade-off across GC strategies.  
- **H1₃:** Some GCs provide a better energy–performance trade-off.  

- **H0₄:** JVM implementation does not change GC efficiency results.  
- **H1₄:** JVM implementation changes relative GC performance.  

- **H0₅:** Application type does not influence GC energy efficiency.  
- **H1₅:** Application type moderates the effect of GC strategy.  

---

## 4. Experimental Variables

- **Independent variable (treatment):**  
  GC strategy → Serial, Parallel, G1, ZGC, Shenandoah.  

- **Dependent variables (measured):**  
  - Energy consumption (Joules, via Intel RAPL / powercap).  
  - Execution time (ms, wall-clock or JMH).  
  - CPU utilization (%).  
  - Memory usage (MB, peak RSS / heap usage).  
  - GC logs: number of collections, pause times.  
  - Derived metric: Joules per operation / Joules per second.  

- **Co-factors (varied):**  
  - Workload intensity (light, medium, heavy).  
  - Application type (CPU-heavy, memory-heavy, mixed).  
  - JVM implementation (OpenJDK vs Oracle JDK).  
  - Heap size (fixed: e.g., `-Xms2g -Xmx2g`).  

---

## 5. Subjects (Benchmarks & Applications)

- **Benchmarks:**  
  - **DaCapo Chopin** (e.g., `h2`, `xalan`, `avrora`, `luindex`, `sunflow`).  
  - **CLBG (Computer Language Benchmark Game)**.  
  - **Rosetta Code Java programs** (smaller micro-benchmarks).  

- **Applications (3–5 real-world Java apps):**  
  Select lightweight CLI/utility apps (e.g., database engines, parsers, simulations).

---

## 6. Experimental Design

- **Factorial design:**  
  GC strategy × workload level × application type × JVM implementation.  

- **Repetitions:** ≥ 10 runs per configuration to reduce noise.  
- **Randomization:** Random run order to avoid thermal drift.  

### Infrastructure & Tooling
- **Host environment:** Linux laptop (dual boot, fixed kernel version).  
- **Isolation:**  
  - Run benchmarks inside **Docker containers** to control environment (consistent JDK, heap size, configs).  
  - Each GC strategy has its own container build with the proper JVM flags.  
- **Monitoring:**  
  - **Energy:** RAPL (`/sys/class/powercap/intel-rapl`) from the host machine.  
  - **System metrics:** `pidstat`, `perf`, or Docker stats API.  
  - **GC logs:** `-Xlog:gc*:file=gc.log`.  

### Example setup
```bash
# Example Docker run with G1GC
docker run --rm \
  --cpus=4 --memory=4g \
  openjdk:24 \
  java -XX:+UseG1GC -Xms2g -Xmx2g -jar dacapo-*.jar h2 -n 5
