
import argparse
from pathlib import Path
import re

import matplotlib
matplotlib.use("Agg")

import matplotlib.pyplot as plt
import pandas as pd


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Analyze Salmonella antimicrobial resistance genes"
    )
    parser.add_argument("--input", required=True, help="Input TSV file")
    parser.add_argument(
        "--output-dir", required=True, help="Directory for results"
    )
    return parser.parse_args()


def extract_genes(value):
    """Extract individual resistance genes from a genotype field."""
    if pd.isna(value):
        return []

    genes = re.split(r"[,;]", str(value))
    return list({
        gene.strip().strip('"')
        for gene in genes
        if gene.strip().strip('"')
    })



def classify_source(row):
    """Classify isolates based on NCBI epidemiological metadata."""

    epi_type = str(row["epi_type"]).strip().lower()

    if epi_type == "clinical":
        return "Clinical"

    if epi_type == "environmental/other":
        return "Environmental/Other"

    return "Unknown"



def analyze_data(input_path, output_dir):
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(input_path, sep="\t", dtype=str)

    required = {
        "epi_type", "isolation_source",
        "serovar", "AMR_genotypes"
    }

    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {sorted(missing)}")

    if df.empty:
        raise ValueError("The filtered dataset contains no isolates.")

    df["genes"] = df["AMR_genotypes"].apply(extract_genes)
    df["category"] = df.apply(classify_source, axis=1)

    # Count each gene once per isolate.
    exploded = df[["genes", "category"]].explode("genes")
    exploded = exploded.dropna(subset=["genes"])
    exploded = exploded[exploded["genes"] != ""]

    frequencies = exploded["genes"].value_counts()

    summary = pd.DataFrame({
        "gene": frequencies.index,
        "isolate_count": frequencies.values,
        "frequency_percent": (
            frequencies.values / len(df) * 100
        ).round(2)
    })

    summary.to_csv(output_dir / "amr_summary.csv", index=False)

    # Compare the genes by source category.
    comparison = pd.crosstab(
        exploded["genes"], exploded["category"]
    )
    comparison.to_csv(output_dir / "amr_source_comparison.csv")

    # Generate the frequency plot.
    top_genes = summary.head(15)

    plt.figure(figsize=(12, 7))
    plt.barh(
        top_genes["gene"][::-1],
        top_genes["frequency_percent"][::-1]
    )
    plt.xlabel("Percentage of filtered isolates (%)")
    plt.ylabel("Resistance gene")
    plt.title("Top 15 AMR genes in filtered Salmonella isolates")
    plt.tight_layout()
    plt.savefig(
        output_dir / "amr_frequency_plot.png",
        dpi=300
    )
    plt.close()

    print(f"Analyzed {len(df)} isolates.")
    print("Results saved to:", output_dir)
    print("Source categories:")
    print(df["category"].value_counts().to_string())


def main():
    args = parse_arguments()
    analyze_data(args.input, args.output_dir)


if __name__ == "__main__":
    main()
