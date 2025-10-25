# GreenLab RPI — Primary Experiment Runner

## 📋 Overview

This directory contains the **primary automated framework** for running the complete experimental suite. The `Run_Config_batch.py` orchestrator executes all 486 experimental runs across GC strategies, workload levels, JDK implementations, and Java applications.

**⚡ Quick Start:** Run `python3 Run_Config_batch.py` and the framework handles the rest automatically.

## 📂 Key Files

| File | Purpose |
|------|---------|
| **`Run_Config_batch.py`** | **Master orchestrator** — run this to execute all experiments |
| **`run_single_experiment.sh`** | Shell script for **benchmark JARs** (CLBG, DaCapo, Rosetta) |
| **`service_apps_experiment.sh`** | Shell script for **service applications** (PetClinic, TodoApp, ANDIE) |
| **`pre_check.bash`** | Pre-flight validation (dependencies, paths, permissions) |
| **`pre_check.txt`** | Human-readable checklist for manual verification |
| **`Run_Single_Experiment.sh`** | Generic single-run template (used by orchestrator) |
| **`Service_Apps_Run_Single_Experiment.sh`** | Service app single-run template |
| **`fallback/`** | Simplified standalone scripts (use if this framework fails) |

## 🚀 Running the Experiments

### Option 1: Automated Full Suite (Recommended)
```bash
# Navigate to this directory
cd experiment-runner/greenlab_rpi/

# Run pre-flight checks (optional but recommended)
bash pre_check.bash

# Execute all experiments
python3 Run_Config_batch.py
```

**Expected behavior:**
- Iterates through all experimental configurations (3 GC × 3 workload × 2 JDK × 8 apps × ~3 reps)
- Calls `run_single_experiment.sh` for benchmarks
- Calls `service_apps_experiment.sh` for service applications
- Logs results to `results/` and progress to `logs/`
- Total runtime: **~6-12 hours** depending on system performance

### Option 2: Manual Single Runs (For Testing)
```bash
# Test a benchmark run
bash run_single_experiment.sh Serial Light openjdk CLBG-BinaryTrees

# Test a service app run
bash service_apps_experiment.sh Parallel Medium oracle PetClinic
```

## ⚙️ Configuration Requirements

### Environment Variables

The framework relies on these environment variables (set in your shell profile or export before running):
```bash
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"  # Adjust to your Java installation
export ENERGIBRIDGE_HOME="/usr/local/bin"              # EnergieBridge installation path
export EXPERIMENT_ROOT="/absolute/path/to/experiment-runner"
```

**Verify setup:**
```bash
echo $JAVA_HOME
echo $ENERGIBRIDGE_HOME
which energibridge  # Should return: /usr/local/bin/energibridge
```

### File Path Dependencies

The scripts expect this directory structure:
```
experiment-runner/
├── greenlab_rpi/
│   ├── Run_Config_batch.py          ← You are here
│   ├── run_single_experiment.sh
│   └── service_apps_experiment.sh
├── benchmarks/
│   ├── Computer_Language_Benchmarks_Game/
│   ├── dacapo-23.11-chopin.jar
│   └── rosetta/
└── service_apps/
    ├── spring-petclinic-3.3.0-SNAPSHOT.jar
    ├── TodoApp/
    └── ANDIE/
```

**If paths differ**, edit these scripts:
1. Open `run_single_experiment.sh` → Lines 10-15 (JAR paths)
2. Open `service_apps_experiment.sh` → Lines 10-15 (service app paths)
3. Open `Run_Config_batch.py` → Lines 20-30 (script locations)

## ⚠️ Common Issues & Solutions

### Issue 1: "Command not found: energibridge"

**Solution:**
```bash
# Add EnergieBridge to PATH
export PATH=$PATH:/usr/local/bin

# OR use absolute path in scripts
# Edit run_single_experiment.sh line ~50:
/usr/local/bin/energibridge --duration 300 ...
```

### Issue 2: "JAR file not found"

**Solution:**
```bash
# Verify JAR locations
ls -la ../benchmarks/dacapo-23.11-chopin.jar
ls -la ../service_apps/spring-petclinic-3.3.0-SNAPSHOT.jar

# Update paths in shell scripts if different
```

### Issue 3: Service apps hang indefinitely

**Cause:** Service applications don't exit on their own — they run as servers.

**Solution:** The `service_apps_experiment.sh` script uses a **custom measurement framework**:
1. Starts service in background
2. Executes scripted workload (HTTP requests)
3. Captures energy during fixed measurement window
4. Kills service process after measurement

**If this fails**, see [fallback/Readme.md](fallback/Readme.md) for manual control approach.

### Issue 4: Python script errors

**Solution:**
```bash
# Check Python version (requires 3.7+)
python3 --version

# Install required packages
pip3 install pandas numpy pyyaml

# Verify script paths are correct
python3 -c "import os; print(os.path.exists('run_single_experiment.sh'))"
```

## 🛟 When to Use the Fallback Directory

**Use `fallback/` instead if you encounter:**
- Persistent environment variable conflicts
- Complex file path resolution errors
- Service app timeout/hanging issues
- Need for step-by-step debugging transparency

The fallback scripts are **simpler but require manual path editing** — see [fallback/Readme.md](fallback/Readme.md) for details.

## 📊 Expected Output
```
greenlab_rpi/
├── results/
│   ├── run_001_Serial_Light_openjdk_CLBG-BinaryTrees.csv
│   ├── run_002_Parallel_Medium_oracle_PetClinic.csv
│   └── ... (486 total files)
├── logs/
│   ├── batch_execution_2025-01-20.log
│   ├── error_summary.txt
│   └── progress.txt
└── checkpoints/
    └── completed_runs.txt  # Resumable execution tracking
```

## ✅ Pre-Flight Checklist

Before running experiments, verify:

- [ ] **Java installed** (`java -version` works)
- [ ] **EnergieBridge installed** (`energibridge --version` works)
- [ ] **All JAR files present** (check `benchmarks/` and `service_apps/`)
- [ ] **Sufficient disk space** (~5 GB for results + logs)
- [ ] **Stable power supply** (experiments take 6-12 hours)
- [ ] **No competing processes** (close browsers, IDEs to minimize interference)

**Run automated checks:**
```bash
bash pre_check.bash  # Reviews environment setup
cat pre_check.txt    # Manual verification guide
```

## 🆘 Getting Help

**If you encounter issues with this framework:**

1. **Check the fallback directory** — simpler execution path with explicit paths
2. **Review error logs** in `logs/error_summary.txt` for diagnostic info
3. **Contact the research group:**
   - **Email:** 
   - **GitHub Issues**
   - **Slack** 

**Include in your help request:**
- Output of `bash pre_check.bash`
- Contents of `logs/error_summary.txt`
- Operating system and Java version (`uname -a`, `java -version`)

## 🎯 Success Criteria

You've successfully run the framework when:

✅ **486 CSV files** appear in `results/` (one per experimental run)  
✅ **Log file** shows "Batch execution complete: 486/486 runs successful"  
✅ **No error entries** in `logs/error_summary.txt`  
✅ **Results validate** using `data/run_table_w.csv` as reference

---

**Remember:** This framework handles environment complexity automatically. If it's not working smoothly, the `fallback/` directory provides a simpler alternative — **reliability over automation!** 🎯
