# Tier 2: Production Testbed - Real RAPL Measurements

This directory documents the production infrastructure setup and initial validation using real Intel RAPL energy measurements on dedicated hardware.

---

## Current Status

**Infrastructure:** Operational - Raspberry Pi orchestrator + Linux DUT configured

**Validation:** Single JAR (PetClinic) successfully tested with real RAPL measurements

**Next Phase:** Full experimental campaign pending

---

## Architecture Overview

The production testbed implements a **separated orchestration and measurement** architecture to minimize interference from experimental control overhead.

### Hardware Components

**Orchestrator: Raspberry Pi 4**
- OS: Raspberry Pi OS
- Role: Runs ExperimentRunner, schedules trials, manages SSH communication
- Network: Connected to DUT via WiFi/Ethernet

**Device Under Test (DUT): Linux Laptop**
- CPU: Intel Core i7-10750H (6 cores, 12 threads)
- RAM: 32GB DDR4
- OS: Ubuntu 24.04.3 LTS (kernel 6.8.0)
- GPU: Disabled via `nvidia-smi`

### Software Stack

**Measurement:**
- EnergiBridge - RAPL counter interface
- Intel RAPL access via `/sys/class/powercap/intel-rapl`

**Execution Environment:**
- OpenJDK 17 (latest Temurin)
- Oracle JDK 11 (latest)
- ExperimentRunner

### Communication Protocol

1. Raspberry Pi initiates run via SSH to DUT
2. DUT starts EnergiBridge measurement
3. DUT executes Java workload with specified GC flags
4. EnergiBridge stops, writes CSV
5. Results returned to Raspberry Pi
6. Aggregated into `run_table.csv`

**Design Rationale:** Physical separation ensures ExperimentRunner's overhead does not appear in RAPL measurements.

---

## Setup Process

### Hardware Configuration

**DUT:**
- Fresh Ubuntu 24.04.3 install
- CPU governor locked to `performance` mode
- RAPL permissions configured: `sudo chmod -R a+r /sys/class/powercap/intel-rapl/`
- Discrete GPU disabled

**Raspberry Pi:**
- SSH keys configured for passwordless DUT access
- ExperimentRunner installed with dependencies

### Software Dependencies

**DUT:**

OralceJDK and OpenJDK latest versions




### JAR Files

All benchmark/application JARs deployed to DUT in `/opt/gc-experiment/jars/` with verified SHA256 checksums.

---

## Setup Challenges & Solutions

### Challenge 1: RAPL Access Permissions
Default Linux restricts RAPL counters to root. Resolved with `chmod a+r` on `/sys/class/powercap/intel-rapl/`.

### Challenge 2: SSH Stability
Initial WiFi connection drops during setup. Switched to Ethernet where available and added SSH keepalive configuration.

### Challenge 3: JAR Deployment
450MB of JARs needed transfer with integrity verification. Used Google Drive + `wget` with SHA256 checksum validation.

### Challenge 4: Hardware Dependencies
Ensuring BIOS settings, power management, and thermal conditions were properly configured for measurement stability.

---

## Validation Run: PetClinic

To validate the complete pipeline, we executed a test with **Spring PetClinic** across all factor combinations.

**Test Configuration:**
- Subject: `spring-petclinic-3.5.0-SNAPSHOT.jar`
- All GC strategies tested (SerialGC, ParallelGC, G1GC)
- All workload levels tested (light, medium, heavy)
- Both JDKs tested (OpenJDK 17, Oracle JDK 11)

**Result:** Successfully collected real RAPL measurements. Run completed without errors, confirming:
- EnergiBridge captures energy data correctly
- ExperimentRunner orchestration works via SSH
- CSV output schema matches expected format
- Hardware setup is stable and functional

---

## Run Table Structure

Production `run_table.csv` contains real RAPL measurements with the following columns:

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

Additional RAPL-specific columns may include package, core, and DRAM energy breakdowns depending on hardware support.

---

## Infrastructure Status

**Setup Complete:**
- Hardware configured and stable
- Software dependencies installed
- Communication protocols tested
- Single-subject validation successful
- Ready for full experimental campaign

**Remaining Work:**
- Integration of remaining subjects (DaCapo, CLBG, Rosetta, TodoApp, ImageProc)
- Full 324-run execution

---

## Files in This Directory

- **README.md** - This file
- **run_table.csv** - PetClinic validation run results

---

## References

- EnergiBridge: https://github.com/S2-group/energibridge
- ExperimentRunner: https://github.com/S2-group/experiment-runner
- Assignment 2 Report: Section 5 (Experiment Execution)
