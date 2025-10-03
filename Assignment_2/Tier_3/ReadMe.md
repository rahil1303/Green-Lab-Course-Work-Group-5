# Tier 3: Fallback Configuration - Co-located Execution

This directory documents the fallback configuration where ExperimentRunner and EnergiBridge both operate on the Device Under Test (DUT) without external orchestration. This configuration serves as a contingency plan if Raspberry Pi integration encounters issues, while still enabling real RAPL measurements.

---

## Current Status

**Configuration:** Operational - tested with single-JAR validation

**Purpose:** Backup deployment strategy if Tier 2 Raspberry Pi orchestration fails

**Trade-off:** Co-located orchestration and measurement vs. ideal separation of concerns

---

## Architecture Rationale

Tier 3 was designed as a **risk mitigation strategy** during experimental planning. While Tier 2's separated architecture (Raspberry Pi orchestrator + DUT) is theoretically cleaner, Tier 3 provides a pragmatic fallback if:
- Raspberry Pi hardware becomes unavailable
- SSH connectivity proves unreliable
- Network configuration issues arise
- Time constraints require faster setup

**Key Principle:** It's better to collect real RAPL measurements with minor orchestration overhead than to delay experiments indefinitely troubleshooting external orchestration.

---

## Co-located Architecture

### Hardware Setup

**Device Under Test (DUT):**
- CPU: Intel Core i7-10750H (6 cores, 12 threads, 2.6-5.0 GHz)
- RAM: 32GB DDR4
- Storage: External SSD (to avoid thermal interference from internal disk)
- OS: Ubuntu 24.04.3 LTS (kernel 6.8.0)
- Configuration: Dual boot (Windows/Linux on-box)
- GPU: Discrete GPU disabled via `nvidia-smi`
- BIOS: Turbo Boost disabled, CPU frequency locked to `performance` governor

**Notable:** The DUT is a dual-boot laptop with an external SSD for the Linux partition, ensuring measurement stability by isolating OS and experimental data from internal disk I/O.

### Software Stack

**All components run on DUT:**
- ExperimentRunner (Python-based orchestration)
- EnergiBridge (RAPL measurement)
- Java workloads (benchmarks and applications)
- Intel RAPL via `/sys/class/powercap/intel-rapl`

### Execution Flow

1. ExperimentRunner starts on DUT (local Python process)
2. For each run:
   - Launch EnergiBridge measurement
   - Execute Java workload with specified GC flags
   - EnergiBridge stops, writes local CSV
   - ExperimentRunner aggregates results
3. All I/O deferred to cooldown periods to minimize interference

**Overhead Mitigation:** ExperimentRunner's scheduling logic consumes <2% CPU when idle between trials, negligible compared to Java workload execution (50-100% CPU utilization).

---

## Differences from Tier 2

| Aspect | Tier 2 (Production) | Tier 3 (Fallback) |
|--------|---------------------|-------------------|
| **Orchestration** | Raspberry Pi (external) | DUT (local process) |
| **Communication** | SSH over network | Local IPC |
| **Overhead** | Zero (physically separated) | Minimal (<2% CPU) |
| **Complexity** | Higher (2 machines) | Lower (1 machine) |
| **Reliability** | Network-dependent | Single point of failure |

**When to use Tier 3:**
- Raspberry Pi unavailable or malfunctioning
- Network issues preventing stable SSH
- Time-constrained situations requiring immediate execution
- Development/testing scenarios where separation overhead isn't justified

---

## Setup Configuration

### Hardware Preparation

**DUT Configuration:**
- Boot into Ubuntu 24.04.3 LTS from external SSD
- Verify RAPL access: `sudo cat /sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj`
- Disable discrete GPU: `sudo nvidia-smi -i 0 -pm 0`
- Lock CPU governor: `sudo cpupower frequency-set -g performance`
- Close all unnecessary applications

### Software Installation

pip install energibridge
pip install experiment-runner
### Verify JDK installations
java -version  # Should show OpenJDK 17 or Oracle JDK 11
### Verify RAPL and measurement tools
python -c "import energibridge; print('EnergiBridge OK')"

### Software Stack

**All components run on DUT:**
- ExperimentRunner (Python-based orchestration)
- EnergiBridge (RAPL measurement)
- Java Development Kits:
  - OpenJDK 17 (latest Temurin distribution)
  - Oracle JDK 11 (latest release)
- Intel RAPL via `/sys/class/powercap/intel-rapl`

### JAR Files

All experimental subjects deployed to `/opt/gc-experiment/jars/` with verified checksums. If not found, jar files for the subjects are also available on Google drive link on the main page of the repo. 

---

## Validation Testing

To validate the co-located configuration, we executed controlled tests with a single JAR across multiple factor combinations.

**Test Subject:** One benchmark or application JAR

**Test Scope:** All GC strategies, workload levels, and JDKs tested

**Result:** Successfully collected real RAPL measurements, confirming:
- EnergiBridge captures energy data correctly in co-located mode
- ExperimentRunner overhead does not significantly affect measurements
- CSV output schema matches expected format
- Configuration is viable as fallback option

---

## Overhead Analysis

To quantify the impact of co-located orchestration, we monitored ExperimentRunner's resource consumption:

**CPU Usage:**
- Idle (between runs): <2%
- During Java execution: <1% (workload dominates at 50-100%)

**Memory Usage:**
- ExperimentRunner: ~150MB
- EnergiBridge: ~50MB
- Total overhead: <1% of 32GB available RAM

**Disk I/O:**
- Logging deferred to cooldown periods
- EnergiBridge CSV writes occur after measurement stops

**Conclusion:** Co-located overhead is negligible compared to Java workload resource consumption. The main risk is not measurement bias but rather single-machine failure (vs. Tier 2's distributed reliability).

---

## Run Table Structure

Run table format is identical to Tier 2, containing real RAPL measurements:

| Column | Type | Description |
|--------|------|-------------|
| `__run_id` | String | Unique run identifier |
| `__done` | String | Execution status |
| `subject` | String | Benchmark/application |
| `gc_strategy` | String | Garbage collector |
| `workload` | String | Allocation intensity |
| `jdk` | String | JDK implementation |
| `energy_joules` | Float | Total energy from RAPL (J) |
| `execution_time` | Float | Runtime duration (s) |
| `power_watts` | Float | Average power (W) |
| `exit_code` | Integer | Process exit status |

---

## When Tier 3 Was Used

Tier 3 served two purposes in our experimental workflow:

1. **Early validation:** Before finalizing Tier 2 infrastructure, Tier 3 allowed us to test the complete pipeline on a single machine
2. **Contingency backup:** Maintained as operational fallback throughout the project in case Tier 2 encountered issues

**Outcome:** Tier 2 (Raspberry Pi orchestration) proved stable, so Tier 3 was used only for initial validation and remains available as a proven backup configuration.

---

## Files in This Directory

- **README.md** - This file
- **validation_runs.csv** - Single-JAR controlled test results
- **setup_notes.md** - Configuration commands and verification steps

---

## Lessons Learned

1. **Co-located execution is viable:** Orchestration overhead is negligible for CPU-intensive workloads
2. **Single-machine simplicity:** Easier to troubleshoot than distributed setup
3. **Reliability trade-off:** No network dependencies, but no hardware redundancy
4. **Validated contingency:** Having a tested fallback reduced project risk significantly

---

## References

- EnergiBridge: https://github.com/S2-group/energibridge
- ExperimentRunner: https://github.com/S2-group/experiment-runner
- Assignment 2 Report: Section 5 (Tier architecture comparison)
