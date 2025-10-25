# 🧪 Replication Package — Java GC Energy Efficiency Experiment (Green Lab Group 5, 2025)

This replication package contains all code and configuration required to reproduce the **Java Garbage Collection (GC) Energy Efficiency Experiment** conducted for *Green Lab 2025*.

It provides:
- the complete Python-based **Experiment Runner framework**,  
- integration scripts for **benchmark and service-app workloads**,  
- environment configuration details,  
- and execution instructions to replicate the full energy measurement setup.

---
## 🪄 Quick Replication Steps

* Clone this repository
```bash
git clone https://github.com/rahil1303/Green-Lab-Course-Work-Group-5.git
```

* Have the `subjects` directory available on the DUT main directory (adjust path according to your system). Download from Google Drive: 🔗 [Subjects Directory (Google Drive)](https://drive.google.com/drive/folders/1YRCqwt6g1wSlfiO5stOhibTMjyNQMe5t)

* Have the DUT shell scripts (`Run_Single_Experiment.sh` and `Service_Apps_Run_Single_Experiment.sh`) available on the DUT main directory (adjust path accordingly).

* Run the DUT preparation script before executing from RPi
```bash
./run_benchmark.sh
```

* Inspect and fix Java paths (Oracle JDK and OpenJDK) inside the shell scripts:
```bash
export JDK_OPEN_PATH=/usr/lib/jvm/java-17-openjdk-amd64
export JDK_ORACLE_PATH=/usr/lib/jvm/jdk-17-oracle
```

* Make sure the EnergiBridge framework is installed on the DUT.

* Ensure the DUT user has appropriate pseudo-privileges (sudo access to `/sys/class/powercap`).

* Edit `Run_Config_Batch.py` with the correct user and DUT details:
```python
LAPTOP_USER = "your_username"
LAPTOP_HOST = "192.168.x.x"
LAPTOP_EXPERIMENT_DIR = "/home/your_username/greenlab-dut"
```

* Execute the experiment from the Raspberry Pi:
```bash
python3 -m greenlab_rpi.Run_Config_Batch
```
---

## 📂 Directory Structure
```
Replication_Package/
└── experiment_runner/
    └── experiment-runner/
        ├── RunnerConfig.py
        ├── Validator.py
        ├── greenlab_rpi/
        │   ├── Run_Single_Experiment.sh
        │   └── Service_Apps_Run_Single_Experiment.sh
            └── Run_Config_Batch.py
        ├── Plugins/
        ├── ConfigValidator/
        ├── EventManager/
        ├── ExperimentOrchestrator/
        ├── requirements.txt
        ├── documentation/
        └── ...
```

> ⚠️ The `gc_energy_experiment/subjects` directory (containing compiled JARs and workload applications) is not included here due to size limitations.  
> You can download it from our public Drive:  
> 🔗 [Subjects Directory (Google Drive)](https://drive.google.com/drive/folders/1YRCqwt6g1wSlfiO5stOhibTMjyNQMe5t)

---

## ⚙️ Experiment Overview

The experiment measures energy consumption and runtime efficiency of different **Java Garbage Collectors** (`Serial`, `Parallel`, `G1`)  
under varying **workloads** (`Light`, `Medium`, `Heavy`) and **JDK implementations** (`OpenJDK`, `Oracle JDK`).

### Subjects (8 total)
1. DaCapo  
2. CLBG-BinaryTrees  
3. CLBG-Fannkuch  
4. CLBG-NBody  
5. Rosetta  
6. PetClinic  
7. TodoApp  
8. ANDIE

### Design Summary
- **Experimental Design:** Randomized Complete Block Design (RCBD)
- **Total runs:** 324 (6 factors × 3 GC × 3 workloads × 2 JDK × 3 repetitions)
- **Measurement Tool:** Intel RAPL via EnergiBridge Plugin
- **Target Device:** Linux DUT (Intel Core i7, Ubuntu 22.04+)
- **Controller Device:** Raspberry Pi 4B (8GB)

---
## 📄 Function of Each File

* **`Run_Config_Batch.py`** — Handles the main data collection process. Runs the Experiment Runner framework, builds the run table, SSHs into the DUT, and executes the shell scripts for each experimental variation.

* **`Run_Single_Experiment.sh`** and **`Service_Apps_Run_Single_Experiment.sh`** — Shell scripts executed on the DUT. They launch the Java applications (benchmarks or service apps), monitor runtime and energy via Intel RAPL using the EnergiBridge framework, and save results in `energy.csv` and `result.csv`.

* **`run_benchmark.sh`** — Prepares the DUT for execution (e.g., cleaning temp files, validating directory paths, ensuring correct permissions) before experiments are started from the RPi.

---

## 🪄 Replication Steps

### 1. Clone this repository
```bash
git clone https://github.com/rahil1303/Green-Lab-Course-Work-Group-5.git
cd Green-Lab-Course-Work-Group-5/Replication_Package/experiment_runner/experiment-runner
```

### 2. Install Python dependencies

Create a fresh virtual environment and install required libraries:
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

✅ This installs Experiment Runner core dependencies including Pandas, Paramiko, and EnergiBridge profiler support.

### 3. Configure environment variables

The Experiment Runner communicates with your Device Under Test (DUT) via SSH.
Update the following environment variables before running:
```bash
export LAPTOP_USER=<dut_username>
export LAPTOP_HOST=<dut_ip_address>
export LAPTOP_EXPERIMENT_DIR=<path_to_experiment_directory_on_dut>
```

**Example:**
```bash
export LAPTOP_USER=vivekbharadwaj99
export LAPTOP_HOST=192.168.50.1
export LAPTOP_EXPERIMENT_DIR=/home/vivekbharadwaj99/greenlab-dut
```

### 4. Verify JDK and JVM configuration

Ensure both OpenJDK and Oracle JDK are installed on the DUT.
Update their paths in the `run_single_experiment.sh` scripts if necessary:
```bash
export JDK_OPEN_PATH=/usr/lib/jvm/java-17-openjdk-amd64
export JDK_ORACLE_PATH=/usr/lib/jvm/jdk-17-oracle
```

These paths are used by the shell scripts to switch between JDKs dynamically during execution.

### 5. Execute the experiment

Run the Python controller from the Raspberry Pi:
```bash
python3 -m greenlab_rpi.Run_Config_batch
```

This automatically:
- Connects to the DUT over SSH,
- Executes `Run_Single_Experiment.sh` for benchmark workloads,
- Executes `Service_Apps_Run_Single_Experiment.sh` for service workloads,
- Retrieves result files (`energy.csv` and `result.csv`), and
- Logs all experiment metadata to `run_table.csv`.

### 6. Output Structure

After execution, results are stored automatically under:
```
experiment_runner/experiments/java_gc_energy_experiment/
├── run_table.csv
├── run_<n>/
│   ├── dut_results/
│   │   ├── energy.csv
│   │   └── result.csv
│   └── metadata.json
```

---

## 🧠 Notes & Recommendations

- Run only one experiment at a time to prevent overheating.
- Ensure CPU Governor is set to **performance mode** on the DUT.
- Disable **Turbo Boost** for consistent energy measurements.
- Keep the RPi and DUT on a stable power source (no USB powering).

---

## 🧩 References

- **Experiment Runner Framework:** [S2-Group / experiment-runner](https://github.com/S2-group/experiment-runner)
- **EnergiBridge Profiler:** Built on top of Intel RAPL energy counter APIs
- **Course:** Software Engineering for Green IT, Vrije Universiteit Amsterdam (2025)

---

**Authors:** Green Lab Group 5
