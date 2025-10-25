# Fallback Execution Scripts — Standalone Replication

## 📋 Overview

This directory provides **simplified, standalone execution scripts** as a fallback option if the primary ExperimentRunner framework (in `greenlab_rpi/`) encounters environment configuration issues. These scripts offer a **more direct execution path** with explicit file paths and minimal dependency on complex orchestration logic.

## ⚠️ When to Use This Fallback

Use these scripts if you experience:
- **File path resolution errors** in the main ExperimentRunner
- **Environment variable conflicts** (e.g., `JAVA_HOME`, `ENERGIBRIDGE_HOME`)
- **Service app timeout issues** where EnergieBridge doesn't capture measurements properly
- **Complex dependency chains** that are difficult to debug in the integrated framework

The fallback approach trades automation convenience for **debugging transparency** and **execution reliability**.

## 📂 Directory Contents

| File | Purpose |
|------|---------|
| **`RunConfig.py`** | Master orchestration script — configures and launches batch experiments |
| **`Run_Config_batch.py`** | Batch execution wrapper — iterates through GC × Workload × JDK combinations |
| **`run_single_experiment.sh`** | Shell script for **benchmark JARs** (CLBG, DaCapo, Rosetta) |
| **`service_apps_experiment.sh`** | Shell script for **service applications** (PetClinic, TodoApp, ANDIE) |
| **`single_experiment.sh`** | Generic single-run template (basis for specialized scripts) |
| **`Readme.md`** | This file — fallback execution guide |

## 🚀 Quick Start: Running the Fallback Scripts

### Step 1: Edit File Paths

**Open `Run_Config_batch.py` and update script paths:**
```python
# Line ~15-20: Point to the correct shell scripts
BENCHMARK_SCRIPT = "/absolute/path/to/fallback/run_single_experiment.sh"
SERVICE_APP_SCRIPT = "/absolute/path/to/fallback/service_apps_experiment.sh"
```

**Open `run_single_experiment.sh` and verify paths:**
```bash
# Line ~5-10: Ensure JAR locations are correct
CLBG_DIR="/path/to/Computer_Language_Benchmarks_Game"
DACAPO_JAR="/path/to/dacapo-23.11-chopin.jar"
ROSETTA_DIR="/path/to/rosetta"
```

**Open `service_apps_experiment.sh` and verify paths:**
```bash
# Line ~5-10: Ensure service app locations are correct
PETCLINIC_JAR="/path/to/spring-petclinic-3.3.0-SNAPSHOT.jar"
TODOAPP_JAR="/path/to/TodoApp/target/todo-app.jar"
ANDIE_JAR="/path/to/ANDIE/andie.jar"
```

### Step 2: Run Batch Experiments
```bash
# Execute the batch orchestrator
python3 Run_Config_batch.py

# OR run individual experiments manually
bash run_single_experiment.sh Serial Light openjdk CLBG-BinaryTrees
bash service_apps_experiment.sh Parallel Medium oracle PetClinic
```

### Step 3: Monitor Output

- **Benchmark runs** will complete automatically and log results to `results/`
- **Service app runs** require manual termination after workload completes (see [Service Apps Handling](#service-apps-handling) below)

## 🔧 Key Differences from Main Framework

| Aspect | Main Framework (`greenlab_rpi/`) | Fallback Scripts (`fallback/`) |
|--------|----------------------------------|--------------------------------|
| **Orchestration** | Integrated Python framework with config files | Standalone shell scripts + simple Python wrapper |
| **Path Resolution** | Relative paths + environment variables | Absolute paths hardcoded in scripts |
| **Service App Handling** | Automated timeout + cleanup (complex) | Manual intervention required (simple but explicit) |
| **Error Handling** | Comprehensive logging + retry logic | Basic error messages + manual debugging |
| **Flexibility** | Highly configurable via YAML/JSON | Modify scripts directly (easier to troubleshoot) |

## 🛠️ Service Apps Handling

### The Challenge

Service applications (PetClinic, TodoApp, ANDIE) **run indefinitely** as servers and don't exit on their own, making automated energy measurement difficult:

- **Benchmark JARs** complete execution → EnergieBridge captures full lifecycle ✅
- **Service apps** start server → wait for requests → **never exit** → EnergieBridge can't determine endpoint ❌

### Our Solution (Custom EnergieBridge Framework)

The `service_apps_experiment.sh` script implements a **three-phase measurement approach**:

1. **Startup Phase:** Launch service app + wait for initialization (5-10 seconds)
2. **Workload Phase:** Execute scripted requests (Light: 100 ops, Medium: 500 ops, Heavy: 2000 ops)
3. **Measurement Window:** EnergieBridge captures energy during fixed time window (2-5 minutes)
4. **Manual Termination:** Script kills service app process after measurement completes

**Implementation snippet (simplified):**
```bash
# Start service app in background
java -XX:+Use${GC}GC -jar ${APP_JAR} &
APP_PID=$!

# Wait for startup
sleep 10

# Start EnergieBridge measurement
energibridge --duration ${WORKLOAD_DURATION} --output results/${RUN_ID}.csv &

# Execute workload (e.g., curl requests to localhost:8080)
bash workload_scripts/${WORKLOAD_LEVEL}_load.sh

# Wait for measurement window to complete
wait

# Terminate service app
kill -9 ${APP_PID}
```

### Why This Approach?

✅ **Deterministic measurement window** — exact control over energy capture period  
✅ **Reproducible workloads** — scripted requests ensure consistent load patterns  
✅ **Avoids timeout complexity** — explicit lifecycle management eliminates race conditions  
✅ **Easier debugging** — manual steps make failure points obvious  

⚠️ **Trade-off:** Requires manual workload scripting (provided in `workload_scripts/`) instead of automated black-box testing

## 📊 Expected Output Structure
```
fallback/
├── results/
│   ├── run_001_Serial_Light_openjdk_CLBG-BinaryTrees.csv
│   ├── run_002_Parallel_Medium_oracle_PetClinic.csv
│   └── ...
├── logs/
│   ├── experiment_batch_2025-01-20.log
│   └── error_summary.txt
└── checkpoints/
    └── completed_runs.txt  # Track progress for resumable execution
```

## ⚡ Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| **"JAR not found" error** | Update absolute paths in `.sh` scripts (lines 5-10) |
| **EnergieBridge not starting** | Verify `energibridge` is in `$PATH` or use absolute path `/usr/local/bin/energibridge` |
| **Service app won't start** | Check port availability (`lsof -i :8080`) and kill conflicting processes |
| **Incomplete measurements** | Increase `WORKLOAD_DURATION` in `service_apps_experiment.sh` (line ~25) |
| **Python script fails** | Check script paths in `Run_Config_batch.py` match your directory structure |

## 🎯 Success Criteria

You've successfully run the fallback scripts when:

✅ **Benchmark runs complete** with exit code 0 and CSV output in `results/`  
✅ **Service app measurements** capture energy during workload execution (verify non-zero energy values)  
✅ **Log files** show no unhandled exceptions or path resolution errors  
✅ **Results match expected dimensions** (486 runs total: 3 GC × 3 workload × 2 JDK × 8 subjects × 3 replications)

## 🔄 Returning to Main Framework

Once you've validated that experiments run successfully with these fallback scripts, you can:

1. **Use fallback results** directly for analysis (same data format as main framework)
2. **Debug main framework** using insights from fallback execution (e.g., correct paths, EnergieBridge settings)
3. **Contribute fixes** to `greenlab_rpi/` to improve robustness for future users

## 📝 Notes on Reproducibility

- **Absolute paths** in these scripts mean they require manual editing per deployment environment
- **Workload scripts** (`workload_scripts/*.sh`) must be customized for your network/system configuration
- **Results are equivalent** to main framework outputs — data format and measurement methodology are identical

---

**When in doubt:** Start here, get experiments running, then optimize with the main framework later. **Reliability over elegance** for replication packages! 🎯
