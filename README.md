# Green-Lab-Course-Work-Group-5

# Green Lab – Group 5 (VU MSc CS)

Replication package + report sources for our Green Lab project.

> **Assignments:**
>
> * A1: Experiment description + GQM
> * A2: Experiment design + execution plan
> * A3: Final report + full replication package (this repo) + presentation video
>
> Structured per the official course **Team Project Guide** and **Report Template**.

---

## 1. Project scope (draft): Still in Editing, waiting for finalized choices from faculty! 

We study the **energy impact of Python implementation choices** by comparing baseline benchmark code against “green” variants following published guidelines (e.g., vectorization, data-structure selection). We measure **energy, time, CPU, memory** across representative Python tasks.

*(This scope fits tracks 1/2/11; we’ll finalize in A1 with GQM.)*

---

## 2. How to reproduce

### 2.1 Requirements

* OS: Linux (dual boot recommended for stable energy readings)
* Python 3.11+
* R 4.3+ (for analysis)
* Tools:

  * `pyJoules` (energy metering)
  * (Optional) Experiment Runner if we orchestrate runs via YAML

### 2.2 Setup

```bash
git clone https://github.com/<YOUR_USERNAME>/Green-Lab-Course-Work-Group-5.git
cd Green-Lab-Course-Work-Group-5
bash scripts/setup_env.sh
```

### 2.3 Run benchmarks + collect energy

```bash
bash scripts/run_all.sh
```

Outputs:

* CSVs in `replication/results/` (raw + aggregated)
* Plots/tables in `replication/results/figures` & `replication/results/tables`

### 2.4 Analyze (R)

```bash
Rscript replication/src/r/analysis.R
```

Generates:

* Descriptive statistics, normality checks, hypothesis tests
* Publication-ready figures and tables

---

## 3. Repo layout

```
Green-Lab-Course-Work-Group-5/
├─ README.md
├─ LICENSE
├─ .gitignore
├─ assignments/
│  ├─ 1_experiment_description_GQM/
│  ├─ 2_experiment_design/
│  └─ 3_final_report/
├─ time_logs/
├─ replication/
│  ├─ src/{python,r}
│  ├─ data/{raw,processed}
│  ├─ results/{tables,figures}
│  └─ notebooks/
└─ scripts/
```

---

## 4. Ethics & AI policy

We follow the Green Lab rule: **no AI-generated report content**; tooling/grammar assistance may be used with disclosure if needed. Do not paste AI-generated text into the report sources.

---

## 5. Authors

* Team 5: 

Student 1: Rahil S - 2850828
Student 2: András Sütő
Student 3: Tobias Innleggen
Student 4: Vivek Ananthapadmanabha Bharadwaj
Student 5: Avaneesh Shetye

---

## 6. License

MIT (see `LICENSE`)
