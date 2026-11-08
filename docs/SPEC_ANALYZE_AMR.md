# Technical Specification: `scripts/analyze_amr.py`

> **Note for AI Coding Assistants (Cursor, Copilot, Antigravity, Claude Code):**  
> Implement `scripts/analyze_amr.py` strictly according to this document. The automated test suite `scripts/test_analyze.py` contains pre-written integration tests that validate this exact specification. When you finish, run `pytest scripts/test_analyze.py` to confirm that all tests pass.

---

## 1. Overview & Objectives
* **Script Location:** `scripts/analyze_amr.py`
* **Assigned Developer:** Zakaria Bouchene
* **Purpose:** Process the filtered Salmonella AMR metadata TSV, calculate antibiotic resistance gene frequencies across epidemiological sources (`clinical` vs `environmental`), export a structured CSV summary, and generate a publication-quality chart.

---

## 2. CLI Interface Requirements (`argparse`)
The script must be executable from the command line and parse arguments using Python's built-in `argparse`:

```bash
python3 scripts/analyze_amr.py --input <path/to/filtered.tsv> --output-dir <path/to/output_dir>
```

### Supported Arguments:
| Argument | Type | Required | Description |
| :--- | :--- | :---: | :--- |
| `--input`, `-i` | `str` / `Path` | **Yes** | Path to the input TSV data file. |
| `--output-dir`, `-o` | `str` / `Path` | **Yes** | Destination folder where outputs will be saved. |
| `--help`, `-h` | Flag | Optional | Prints usage help and exits with code `0`. |

* **Exit behavior on missing input:** If `--input` does not exist or is not a file, print a clear error message to `sys.stderr` and exit with code `1`.
* **Output directory handling:** Automatically create `--output-dir` if it does not already exist (`os.makedirs(output_dir, exist_ok=True)`).

---

## 3. Data Processing & Gene Parsing Rules

### Input TSV Structure:
The input file is tab-separated (`\t`) with column headers. The primary columns are:
* `epi_type`: Biological context of isolation (e.g., `clinical`, `environmental`, `environmental/other`).
* `AMR_genotypes`: List of detected resistance genes (e.g., `"blaTEM-1,catA1,sul1"` or `"blaTEM-1;aadA1"`).

### ⚠️ Critical Parsing Rule (Delimiters):
Individual isolates may carry multiple resistance genes. Depending on whether the source is the raw NCBI dataset or the test fixture, genes are separated by either **commas (`,`)** or **semicolons (`;`)**, and may contain whitespace or quotes.

You **must** parse genes using a regular expression that handles both separators:
```python
import re
import pandas as pd

def extract_genes(genotype_value):
    if pd.isna(genotype_value) or str(genotype_value).strip() in ("", "NULL", "none"):
        return []
    # Split on either comma or semicolon, strip whitespace
    return [g.strip() for g in re.split(r'[,;]', str(genotype_value)) if g.strip()]
```

---

## 4. Mandatory Output Files (Exact Names Required by Tests)

The test suite in `scripts/test_analyze.py` asserts the existence and contents of these **exact files** inside `--output-dir`:

### 1. `amr_summary.csv`
A CSV file containing the summary statistics of gene frequencies.
* **Must contain columns/values matching:**
  * Source categories: `clinical` and `environmental`
  * Gene names: (e.g., `blaTEM-1`, `aadA1`, etc.)
  * Counts or frequencies
* **Example structure:**
  ```csv
  gene,epi_type,count,frequency
  blaTEM-1,clinical,2,0.6667
  aadA1,clinical,1,0.3333
  sul1,environmental,1,1.0000
  ```

### 2. `amr_frequency_plot.png`
A visualization generated via `matplotlib.pyplot` or `seaborn`:
* **Contents:** Barplot comparing gene counts or frequencies between `clinical` and `environmental` isolates.
* **Saving:** Save using `plt.savefig(output_path, dpi=300, bbox_inches='tight')`.
* **Requirement:** Must be a valid, non-empty PNG file (`file_size > 0`).

### 3. *(Optional Bonus)* `amr_summary.json`
Exporting a JSON version of the summary metrics provides structured data access for downstream tools.

---

## 5. Automated Verification Checklist

Before opening a Pull Request, verify that your implementation satisfies:

```bash
# 1. Verify help flag and argument parsing
python3 scripts/analyze_amr.py --help

# 2. Run the test suite
pytest scripts/test_analyze.py
```

Expected result:
```text
scripts/test_analyze.py ..                                              [100%]
============================== 2 passed in 0.45s ==============================
```
