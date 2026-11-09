#!/usr/bin/env bash
# Filter Salmonella isolates carrying beta-lactam and aminoglycoside/quinolone
# resistance genes, retaining the fields consumed by the analysis stage.
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INPUT="${REPO_ROOT}/data/PDG000000002.1697.amr.metadata.tsv"
OUTPUT="${REPO_ROOT}/results/filtered_amr.tsv"
TMP_FILE=""

log() {
    local level="$1"
    shift
    printf '[%s] [%s] [%s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "${level}" "${SCRIPT_NAME}" "$*" >&2
}

die() {
    log ERROR "$*"
    exit 1
}

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [-i INPUT] [-o OUTPUT] [-h]

Extracts clinical/environmental metadata and retains multidrug-resistant
isolates carrying at least one beta-lactam gene (bla*) and one
aminoglycoside/quinolone gene.

Options:
  -i FILE   Input NCBI AMR metadata TSV
  -o FILE   Output filtered TSV
  -h        Show this help
EOF
}

cleanup() {
    if [[ -n "${TMP_FILE}" && -f "${TMP_FILE}" ]]; then
        rm -f -- "${TMP_FILE}"
    fi
}

require_tools() {
    local tool
    for tool in awk cut grep sort uniq head tail; do
        command -v "${tool}" >/dev/null 2>&1 ||
            die "Required tool not found: ${tool}"
    done
}

extract_columns() {
    local input="$1"
    local output="$2"

    awk -F '\t' -v OFS='\t' '
        NR == 1 {
            for (i = 1; i <= NF; i++) {
                if ($i == "epi_type") epi = i
                else if ($i == "isolation_source") source = i
                else if ($i == "serovar") serovar = i
                else if ($i == "AMR_genotypes") amr = i
            }
            if (!epi || !source || !serovar || !amr) {
                print "missing one or more required columns" > "/dev/stderr"
                exit 2
            }
            print "epi_type", "isolation_source", "serovar", "AMR_genotypes"
            next
        }
        {
            print $epi, $source, $serovar, $amr
        }
    ' "${input}" > "${output}" ||
        die "Could not read required columns from ${input}"
}

main() {
    while getopts ":i:o:h" opt; do
        case "${opt}" in
            i) INPUT="${OPTARG}" ;;
            o) OUTPUT="${OPTARG}" ;;
            h) usage; exit 0 ;;
            :) usage >&2; die "Option -${OPTARG} requires an argument" ;;
            \?) usage >&2; die "Unknown option: -${OPTARG}" ;;
        esac
    done
    shift $((OPTIND - 1))
    [[ $# -eq 0 ]] || die "Unexpected argument: $1"
    [[ -f "${INPUT}" ]] || die "Input file does not exist: ${INPUT}"
    [[ -s "${INPUT}" ]] || die "Input file is empty: ${INPUT}"

    require_tools
    mkdir -p -- "$(dirname "${OUTPUT}")"
    TMP_FILE="${OUTPUT}.tmp.$$"
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    extract_columns "${INPUT}" "${TMP_FILE}"

    {
        head -n 1 "${TMP_FILE}"
        tail -n +2 "${TMP_FILE}" |
            cut -f 1-4 |
            { grep -Ei '(^|[,;])[[:space:]]*"?bla|(^|[,;])[[:space:]]*"?(aac|aad|aph|ant|qnr|oqx)' || true; } |
            awk -F '\t' -v OFS='\t' '
                {
                    genotype = tolower($4)
                    gsub(/"/, "", genotype)
                    has_beta = (genotype ~ /(^|[,;])[[:space:]]*bla/)
                    has_other = (genotype ~ /(^|[,;])[[:space:]]*(aac|aad|aph|ant|qnr|oqx)/)
                    if (has_beta && has_other) print
                }
            ' |
            sort -t "$(printf '\t')" -k1,1 -k3,3 -k4,4 |
            uniq
    } > "${OUTPUT}"

    rm -f -- "${TMP_FILE}"
    TMP_FILE=""
    log INFO "Wrote filtered MDR isolates to ${OUTPUT}"
}

main "$@"
