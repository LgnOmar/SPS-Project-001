# SPS Project: Salmonella AMR Investigation
## Team Task Assignments & GitHub Collaboration Guide

- **Project Lead & Repo Owner:** Ahmed Amar LAGGOUNE
- **Disease Studied:** Salmonellosis (*Salmonella enterica*)
- **Dataset:** NCBI Pathogen Detection AMR Metadata (`PDG000000002.1697.amr.metadata.tsv` — 123 MB)
- **Repository URL:** [https://github.com/LgnOmar/SPS-Project-001.git](https://github.com/LgnOmar/SPS-Project-001.git)
- **Live Google Doc:** [Open in Google Docs](https://docs.google.com/document/d/13fnxnRYPBjwRCeCEQsxe1DwPcWliYaZucaSFx4AzGDE/edit?usp=sharing)

---

### ⏱️ Key Deadlines
* **Monday, Nov 9, 2026 @ 23:59:** Working Functional Version Due (for cross-testing)
* **Nov 9 – Nov 13, 2026:** Cross-Group Evaluation (48h turnaround report)
* **Friday, Nov 20, 2026 @ 23:59:** Final Code & 4-Page Report Due (**Strict — No late submissions**)
* **Post-Submission:** Individual Oral Defense (25 min: 10 min presentation + live code modification by a designated student)

---

# PART 1: TEAM TASK ASSIGNMENTS (5 MEMBERS)

To guarantee that everyone gets full credit in the Git commit history and is fully prepared for the oral defense, each member has an independent module and file.

---

### 1. Ahmed Amar LAGGOUNE (Repository Owner & Integration Lead)
* **Assigned Branch:** `feature/orchestrator-run-sh`
* **Assigned File:** `run.sh` (root directory)
* **Responsibilities:**
  - **Repository Owner duties:** Review and merge teammates' Pull Requests on GitHub.
  - **Master pipeline script (`run.sh`):** orchestrates the execution from raw data to final outputs.
  - **Argument handling with `getopts`:** (`-h` for help, `-d` for data dir, `-o` for output dir).
  - **Safety & error handling:** `set -euo pipefail`, `trap` for automatic cleanup of temporary files.
  - **Reusable Bash functions:** at least 3 modular functions (logging, validation, packaging).
  - **Results packaging:** creates a timestamped archive (`results/archive_YYYYMMDD_HHMMSS.tar.gz`).
  - **Idempotent execution:** pipeline can be run repeatedly without manual folder cleanup.
* **Rubric Criteria Covered:** Shell options, help flag, trap, pipefail, reusable functions, idempotence, dated tar archive.

---

### 2. Mohamed Bouabdelli (Data Acquisition & Integrity Lead)
* **Assigned Branch:** `feature/data-acquisition`
* **Assigned Files:** `scripts/download_and_verify.sh`, `SOURCES.md`
* **Responsibilities:**
  - **Automated download:** checks if `data/PDG000000002.1697.amr.metadata.tsv` exists; if not, downloads it via `curl`/`wget`.
  - **Integrity verification:** calculates and checks `sha256sum` of the downloaded file.
  - **System security:** sets read-only permissions on raw data (`chmod 444`).
  - **Documentation:** keeps `SOURCES.md` updated with exact download URL, file size (123 MB), date, and NCBI cluster ID.
* **Rubric Criteria Covered:** Checksum calculation & verification, read-only data permissions, complete `SOURCES.md`.

---

### 3. Idriss HECHAM (Group Delegate, Shell Pipeline & Report Lead)
* **Assigned Branch:** `feature/shell-filter-motifs`
* **Assigned Files:** `scripts/filter_motifs.sh`, `rapport.pdf` coordination
* **Responsibilities:**
  - **Shell data processing:** extracts relevant columns from the 49-column dataset (`AMR_genotypes`, `epi_type`, `isolation_source`, `serovar`).
  - **Multi-command Unix pipe:** implements a chain of 3 or more piped commands (`cut | grep | awk | sort | uniq`).
  - **Motif extraction:** identifies multidrug-resistant (MDR) isolates carrying critical co-occurring resistance genes (e.g. beta-lactams `bla*` and aminoglycosides/quinolones).
  - **Output generation:** writes clean filtered data to `results/filtered_amr.tsv`.
  - **Report coordination:** leads the drafting of the mandatory 4-page `rapport.pdf`.
* **Rubric Criteria Covered:** 3+ piped shell commands on data, biological motif extraction, 4-page report structure.

---

### 4. Zakaria Bouchene (Python Data Science Lead)
* **Assigned Branch:** `feature/python-analysis`
* **Assigned File:** `scripts/analyze_amr.py`
* **Responsibilities:**
  - **Python CLI interface:** parses command-line arguments using `argparse` (`--input`, `--output-dir`).
  - **Data processing:** reads `results/filtered_amr.tsv` with `pandas` and calculates AMR frequencies.
  - **Comparative metrics:** evaluates resistance gene distribution between Clinical vs. Environmental isolates.
  - **Structured output:** exports numerical statistics to `results/amr_summary.csv` or JSON.
  - **Automated visualization:** generates and saves a publication-quality figure to `results/amr_frequency_plot.png`.
* **Rubric Criteria Covered:** Python called with `argparse`, automatic figure production, structured CSV/JSON results.

---

### 5. Nadir FARTAS (Testing, Cron & Environment Lead)
* **Assigned Branch:** `feature/tests-and-cron`
* **Assigned Files:** `scripts/test_analyze.py`, `cron/crontab.sample`, `requirements.txt`, `environment.yml`
* **Responsibilities:**
  - **Automated testing:** writes unit tests with `pytest` in `scripts/test_analyze.py` to validate the analysis logic on mock data.
  - **Task scheduling:** creates `cron/crontab.sample` documenting how to schedule periodic pipeline runs (e.g., weekly cron job).
  - **Execution logging:** configures timestamped logs in `logs/` (e.g., `[YYYY-MM-DD HH:MM:SS] [INFO]`).
  - **Environment reproducibility:** validates `requirements.txt` and `environment.yml` for clean virtualenv/conda installation.
* **Rubric Criteria Covered:** Automated `pytest` test, cron task provided & documented, timestamped logs, reproducible environment.

---

# PART 2: GITHUB COLLABORATION WORKFLOW & INSTRUCTIONS

### Why We Use Feature Branches
Never commit directly to the `main` branch. The `main` branch must always remain clean, functional, and ready for evaluation. By giving every person their own branch and their own file, we guarantee **ZERO merge conflicts**.

---

### Step-by-Step Instructions for Each Team Member

#### Step 1: Set Up Your Git Identity (First Time Only)
Open your terminal and run:
```bash
git config --global user.name "Your Full Name"
git config --global user.email "your.school.email@univ.edu"
```
> *Note: This ensures your commits are linked to your real identity for the professor to see!*

#### Step 2: Clone the Repository
```bash
git clone https://github.com/LgnOmar/SPS-Project-001.git
cd SPS-Project-001
```

#### Step 3: Create Your Feature Branch
```bash
git checkout -b feature/your-assigned-branch-name
```

#### Step 4: Work Only on Your Assigned File
Create and edit your assigned file inside `scripts/` (or `cron/`). Do not edit files assigned to other teammates!

#### Step 5: Verify, Stage, and Commit Your Changes
```bash
git status
git add scripts/your_file.sh
git commit -m "feat: implement feature description"
```

#### Step 6: Push Your Branch to GitHub
```bash
git push -u origin feature/your-assigned-branch-name
```

#### Step 7: Create a Pull Request (PR) on GitHub
1. Go to [https://github.com/LgnOmar/SPS-Project-001](https://github.com/LgnOmar/SPS-Project-001) in your browser.
2. Click the green **"Compare & pull request"** button that appears.
3. Write a brief 1–2 sentence description of what your script does.
4. Click **"Create pull request"**.

#### Step 8: Review and Merge (Handled by Ahmed Amar LAGGOUNE)
Ahmed reviews the Pull Request on GitHub, verifies the code, and clicks **"Merge pull request"**.
Your work is now permanently part of `main`, credited under your name in the commit history!

---

# PART 3: ORAL DEFENSE WARNING (LIVE CODE MODIFICATION)

Keep in mind:
- **30% of the entire course grade** is based on the individual oral defense.
- The professor will ask individual questions to each member.
- The professor will ask a designated student to **MODIFY CODE LIVE** during the defense!
- Because each student writes their own module, everyone will genuinely understand their code and be ready for the live questions.
