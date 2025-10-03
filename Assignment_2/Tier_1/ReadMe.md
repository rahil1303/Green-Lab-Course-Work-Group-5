# Tier 1: Mock Environment - Development & Pipeline Validation

This directory contains the complete mock environment setup used to validate the experimental pipeline before deploying to production hardware. The mock tier simulates EnergiBridge's RAPL measurements with synthetic energy data, allowing cross-platform development and testing without requiring Linux hardware access.

---

## Purpose & Rationale

### Why Mock Testing?

The mock environment addresses several critical challenges in experimental software engineering:

1. **Cross-Platform Development:** Team members working on macOS/Windows can develop and test the pipeline without continuous access to the Linux production testbed
2. **Rapid Iteration:** Configuration changes, randomization logic, and data aggregation can be validated in minutes rather than hours
3. **Pipeline Verification:** Confirms that ExperimentRunner, CSV generation, and analysis scripts work correctly before consuming production hardware time
4. **Risk Mitigation:** Identifies bugs, schema mismatches, or logic errors early in the development cycle

### Architecture

The mock environment consists of three components:

**1. Mock RAPL Interface** (`RunnerConfig.py`)
- Simulates Intel RAPL energy measurements without requiring `/sys/class/powercap` access
- Generates synthetic energy values based on empirical models from literature (Shimchenko et al., 2022)
- Preserves realistic variance and factor relationships observed in prior GC energy studies

**2. ExperimentRunner Integration**
- Uses the same configuration, randomization, and execution logic as production
- Factor definitions, replication counts, and run scheduling are identical to Tier 2
- Only the measurement backend differs (synthetic vs. real RAPL)

**3. Validation Pipeline**
- Exploratory data analysis (EDA.ipynb)
- Assumption testing (normality, homogeneity of variance)
- Preliminary statistical analysis using ART (Aligned Rank Transform)

---

## Mock Energy Model

The synthetic energy measurements are generated using the `_mock_energy_measurement()` function in `RunnerConfig.py`.

### Model Design Rationale

The mock energy model was calibrated based on empirical findings from Shimchenko et al. (2022), who conducted comprehensive energy measurements across six GC strategies in OpenJDK. Their key findings that informed our model:

1. **SerialGC Efficiency:** SerialGC consumed 15-20% less energy than ParallelGC under CPU-bound workloads due to reduced threading overhead
2. **G1 Intermediate Behavior:** G1GC showed energy consumption between Serial and Parallel, with higher variance due to concurrent collection phases
3. **Workload Scaling:** Energy consumption scaled sub-linearly with workload intensity (power law ~0.8 exponent)
4. **JVM Variance:** Measurement variance ranged from 15% (Serial) to 35% (G1) due to non-deterministic JIT compilation and GC heuristics

**Base Values per GC Strategy:**

| GC Strategy | Base Energy (J) | Base Time (s) | Variance | Rationale |
|-------------|-----------------|---------------|----------|-----------|
| SerialGC | 3.2 | 0.35 | 0.15 | Lowest energy, single-threaded |
| ParallelGC | 4.1 | 0.22 | 0.25 | Higher throughput, more power |
| G1GC | 3.8 | 0.28 | 0.35 | Concurrent phases increase variance |

**Workload Multipliers:**
- Light: 1.0× (baseline)
- Medium: 2.3× (empirically observed in Shimchenko)
- Heavy: 3.5× (stress testing allocation rates)

**JDK Factor:**
- Oracle JDK: 1.05× (5% overhead from proprietary JFR monitoring)
- OpenJDK: 1.0× (baseline)

### Calculation Formula

energy_base = base_energy × workload_multiplier × jdk_factor
time_base = base_time × (workload_multiplier ^ 0.8)
energy_joules = energy_base × gaussian_noise(mean=1.0, std=variance)
execution_time = time_base × gaussian_noise(mean=1.0, std=variance×0.8)
power_watts = energy_joules / execution_time

---

## Experimental Subjects

The mock tier tests **4 subjects** (compared to 6 planned for full production):

### Benchmarks

**1. DaCapo Chopin** (`dacapo.jar`)
- Standardized Java benchmark suite
- Allocation-heavy workloads: avrora, h2, jython, luindex
- Used in majority of JVM energy studies for comparability

### Real Applications

**2. Spring PetClinic** (`spring-petclinic-3.5.0-SNAPSHOT.jar`)
- REST web service with database persistence
- Simulates enterprise application patterns (MVC, ORM, connection pooling)
- Workload: Concurrent HTTP requests with CRUD operations

**3. REST To-Do App** (`todoappbackend-0.0.1-SNAPSHOT.jar`)
- Lightweight microservice for task management
- I/O-bound workload with minimal computation
- Tests GC behavior under network-bound conditions

**4. Image Processing Tool** (`image-process-tool-1.0.jar`)
- Batch image transformations (filters, resizing, format conversion)
- Compute-intensive with large temporary object allocations
- Stresses young generation and promotion rates

**Note:** The full production experiment (Tier 2) will add CLBG and Rosetta Code benchmarks for broader coverage.

---

## Run Table Structure

The `run_table.csv` file contains **216 rows** (4 subjects × 3 GC × 3 workloads × 2 JDKs × 3 replications).

### Column Descriptions

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `__run_id` | String | Unique run identifier | `run_42_repetition_1` |
| `__done` | String | Execution status | `DONE` |
| `subject` | String | Benchmark or application name | `dacapo`, `petclinic`, `todoapp`, `imageproc` |
| `gc_strategy` | String | Garbage collector | `SerialGC`, `ParallelGC`, `G1GC` |
| `workload` | String | Allocation intensity | `light`, `medium`, `heavy` |
| `jdk` | String | JDK implementation | `openjdk17`, `oraclejdk11` |
| `energy_joules` | Float | Total energy consumed (J) | `7.662583` |
| `execution_time` | Float | Runtime duration (s) | `0.649036` |
| `power_watts` | Float | Average power (W) | `11.806094` |
| `exit_code` | Integer | Process exit status | `0` (success) |

### Data Characteristics

**Energy Range:** 2.57J - 15.37J across all factor combinations

**Execution Time Range:** 0.22s - 1.04s

**Success Rate:** 100% (all 216 runs completed with `exit_code=0`)

**Randomization:** Run order was shuffled by ExperimentRunner to distribute factor combinations across the execution timeline

**Balance:** Each GC×workload×JDK combination has exactly 12 observations (4 subjects × 3 replications)

---

## Preliminary Statistical Analysis

The `EDA.ipynb` notebook contains comprehensive exploratory data analysis performed on the mock data.

### Descriptive Statistics

**Mean Energy Consumption by Factor Combination:**

Representative examples:
- SerialGC + light + OpenJDK: 3.19J (±0.42)
- ParallelGC + medium + OracleJDK: 10.72J (±2.19)
- G1GC + heavy + OpenJDK: 15.37J (±4.40)

**Key Observations:**
- Workload is the dominant factor (light→heavy increases energy by ~3-4×)
- GC strategy shows moderate effects (SerialGC consistently lower than Parallel)
- JDK implementation has minimal impact (Oracle ~5% higher on average)

### Assumption Testing

**Normality (Shapiro-Wilk Test):**
- Raw data: W = 0.956, p = 2.97×10⁻⁶ (violated)
- Log-transformed: W = 0.912, p = 5.08×10⁻¹⁰ (still violated)

**Interpretation:** Energy distributions are right-skewed, likely due to outliers in heavy workload conditions. Log transformation did not resolve non-normality.

**Homogeneity of Variance (Levene's Test):**
- Raw data: F = 6.62, p = 2.30×10⁻¹² (violated)
- Log-transformed: F = 2.18, p = 0.0059 (still violated)

**Interpretation:** Variance is heterogeneous across factor levels, with G1GC showing highest variability (consistent with literature).

**Conclusion:** ANOVA assumptions not met. Proceeded with non-parametric Aligned Rank Transform (ART).

### Hypothesis Testing Results (ART-ANOVA)

**Main Effects:**

| Factor | F-statistic | p-value | Interpretation |
|--------|-------------|---------|----------------|
| GC Strategy | 24.34 | 3.65×10⁻¹⁰ | Highly significant |
| Workload | 265.17 | 2.37×10⁻⁵⁶ | Dominant effect |
| JDK | 2.88 | 0.091 | Not significant |

**Interactions:**

| Interaction | F-statistic | p-value | Interpretation |
|-------------|-------------|---------|----------------|
| GC × Workload | 2.33 | 0.058 | Borderline significant |
| GC × JDK | 4.37 | 0.014 | Significant |
| Workload × JDK | 1.72 | 0.183 | Not significant |
| GC × Workload × JDK | 2.02 | 0.093 | Not significant |

**Key Findings:**
1. Workload intensity dominates energy consumption (expected)
2. GC strategy has significant but secondary effect
3. JDK implementation shows minimal main effect but interacts with GC
4. GC × Workload interaction suggests efficiency varies by load (aligns with hypothesis H₁₂γ)

### Effect Size Analysis

**Pairwise Cohen's d for GC Strategies:**

Post-hoc comparisons using Tukey HSD with Benjamini-Hochberg correction:

**Heavy Workload:**
- ParallelGC vs. SerialGC: d = 0.86, p = 0.0055 (large effect, significant)
- G1GC vs. SerialGC: d = 0.58, p = 0.10 (medium effect, borderline)
- G1GC vs. ParallelGC: d = 0.28, p = 0.51 (small effect, not significant)

**Medium Workload:**
- ParallelGC vs. SerialGC: d = 0.83, p = 0.0055 (large effect, significant)
- Other comparisons not significant

**Light Workload:**
- No significant pairwise differences (all p > 0.24)

**Interpretation:** GC strategy differences are most pronounced under medium/heavy workloads, with Serial consistently more efficient than Parallel (large effect size). G1 shows intermediate behavior.

### Outlier Analysis

No extreme outliers were detected by `boxplot.stats()`. All 216 runs are retained for analysis.

---

## Mock vs. Production Validation Plan

When Tier 2 production data becomes available, we will validate the mock model by comparing:

### 1. Distribution Characteristics
- **Mean energy per factor combination:** Expected ±20% deviation from mock
- **Variance structure:** Check if real variance matches mock predictions (15-35% CV)
- **Skewness:** Confirm right-skew in energy distributions

### 2. Factor Effect Sizes
- **GC strategy effect:** Verify SerialGC < G1GC < ParallelGC ordering holds
- **Workload scaling:** Confirm sub-linear scaling (exponent ~0.8)
- **JDK minimal effect:** Validate <10% difference between implementations

### 3. Statistical Test Consistency
- **Assumption violations:** Expect similar normality/homogeneity failures
- **ART results:** Confirm workload as dominant factor, GC as secondary
- **Interaction patterns:** Validate GC × Workload borderline significance

### 4. Model Refinement
If production data deviates significantly (>30% error in means or different rank order):
- Recalibrate base values using production measurements
- Adjust variance parameters to match observed CV
- Update workload multipliers based on actual scaling

**Success Criteria:** Mock predictions within ±25% of production means for at least 80% of factor combinations.

---

## Limitations of Mock Testing

1. **Synthetic Data:** Energy values are modeled approximations, not real measurements
2. **No Thermal Effects:** Mock does not simulate CPU temperature drift or frequency scaling
3. **Simplified Variance:** Real RAPL measurements may exhibit different noise characteristics
4. **JVM Warmup Ignored:** Mock does not account for JIT compilation effects
5. **Reduced Subject Count:** 4 subjects vs. 6 planned for production
6. **No System Noise:** Real systems have background processes, interrupts, and OS scheduler interference

**Critical Note:** Mock results are for **pipeline validation only** and are **not used for hypothesis testing or research conclusions**. All Assignment 3 analysis will be based exclusively on Tier 2 real RAPL measurements.

---

## Files in This Directory

- **README.md** - This file
- **run_table.csv** - Complete mock execution results (216 rows)
- **EDA.ipynb** - Exploratory data analysis with assumption testing and preliminary statistics
- **RunnerConfig.py** - ExperimentRunner configuration with mock energy model

---

## Reproduction Instructions

To regenerate the mock data:

1. Install ExperimentRunner dependencies
2. Place JAR files in `jars/` directory
3. Configure JDK paths in `RunnerConfig.py`
4. Run: `python experiment-runner/experiment-runner/ RunnerConfig.py`
5. Output appears in `experiments/gc_energy_experiment/`
6. Analyze with: `EDA.ipynb` in Jupyter/Colab

---

## Next Steps

- Transition to Tier 2 production testbed with real RAPL measurements
- Execute validation plan comparing mock predictions to production data
- Refine energy model if significant deviations observed
- Use validated model for future experimental planning

