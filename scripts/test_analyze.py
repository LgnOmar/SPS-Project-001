"""Contract tests for the AMR analysis command-line interface."""

import csv
import subprocess
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ANALYZER = PROJECT_ROOT / "scripts" / "analyze_amr.py"


def write_fixture(path: Path) -> None:
    rows = [
        {"epi_type": "clinical", "AMR_genotypes": "blaTEM-1;aadA1"},
        {"epi_type": "clinical", "AMR_genotypes": "blaTEM-1"},
        {"epi_type": "environmental", "AMR_genotypes": "sul1"},
    ]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=["epi_type", "AMR_genotypes"], delimiter="\t"
        )
        writer.writeheader()
        writer.writerows(rows)


def run_analyzer(input_path: Path, output_dir: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            str(ANALYZER),
            "--input",
            str(input_path),
            "--output-dir",
            str(output_dir),
        ],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )


def test_analyzer_help_is_available():
    result = subprocess.run(
        [sys.executable, str(ANALYZER), "--help"],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 0
    assert "--input" in result.stdout
    assert "--output-dir" in result.stdout


def test_analyzer_writes_summary_and_plot(tmp_path: Path):
    input_path = tmp_path / "filtered_amr.tsv"
    output_dir = tmp_path / "results"
    write_fixture(input_path)

    result = run_analyzer(input_path, output_dir)

    assert result.returncode == 0, result.stderr

    summary_path = output_dir / "amr_summary.csv"
    plot_path = output_dir / "amr_frequency_plot.png"
    assert summary_path.is_file()
    assert plot_path.is_file()
    assert plot_path.stat().st_size > 0

    summary = summary_path.read_text(encoding="utf-8")
    assert "clinical" in summary
    assert "environmental" in summary
    assert "blaTEM-1" in summary
