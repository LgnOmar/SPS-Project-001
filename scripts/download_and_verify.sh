#!/usr/bin/env bash
# =============================================================================
# download_and_verify.sh
# Projet « Enquête sur une maladie » - Salmonella AMR (NCBI Pathogen Detection)
# Auteur : Mohamed Bouabdelli (acquisition & intégrité des données)
#
# Rôle :
#   1. Télécharge le fichier de métadonnées AMR si absent (curl, sinon wget)
#   2. Vérifie qu'il s'agit bien d'un TSV valide (et pas d'une page d'erreur HTML)
#   3. Calcule le sha256 et le compare à la somme de référence versionnée
#      (checksums/<fichier>.sha256). Si aucune référence n'existe encore, elle
#      est créée au premier téléchargement (à committer ensuite dans Git).
#   4. Verrouille le fichier en lecture seule (chmod 444)
#
# Codes de retour :
#   0  succès
#   1  erreur générique
#   2  erreur d'usage (option invalide, outil manquant)
#   3  échec du téléchargement
#   4  somme de contrôle incorrecte
#   5  contenu invalide (fichier vide, trop petit, HTML, colonnes manquantes)
#   130 interruption (Ctrl+C), 143 (SIGTERM)
# =============================================================================
set -euo pipefail

# ----------------------------- Valeurs par défaut ----------------------------
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SCRIPT_NAME SCRIPT_DIR REPO_ROOT

readonly DEFAULT_URL="https://ftp.ncbi.nlm.nih.gov/pathogen/Results/Salmonella/PDG000000002.1697/AMR/PDG000000002.1697.amr.metadata.tsv"
readonly MIN_SIZE_BYTES=$((50 * 1024 * 1024))   # le fichier fait ~123 Mo : < 50 Mo = suspect
readonly REQUIRED_COLUMN="AMR_genotypes"        # doit apparaître dans l'en-tête

URL="${DEFAULT_URL}"
DATA_DIR="${REPO_ROOT}/data"
CHECKSUM_DIR="${REPO_ROOT}/checksums"
FORCE=0
TMP_FILE=""                                     # fichier .part en cours de téléchargement

# ------------------------------- Fonctions -----------------------------------
# Journal horodaté sur stderr (+ fichier si LOG_FILE est défini par run.sh)
log() {
    local level="$1"; shift
    local line
    line="[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] [${SCRIPT_NAME}] $*"
    echo "${line}" >&2
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "${line}" >> "${LOG_FILE}"
    fi
}

# Message d'erreur + sortie avec un code précis
die() {
    local code="$1"; shift
    log ERROR "$*"
    exit "${code}"
}

usage() {
    cat <<EOF
Usage : ${SCRIPT_NAME} [-d DATA_DIR] [-u URL] [-c CHECKSUM_DIR] [-f] [-h]

Télécharge (si besoin) le jeu de données NCBI Pathogen Detection, vérifie son
intégrité (sha256) et le verrouille en lecture seule.

Options :
  -d DIR   Dossier des données brutes            (défaut : ${DATA_DIR})
  -u URL   URL de téléchargement                 (défaut : URL NCBI de SOURCES.md)
  -c DIR   Dossier des sommes de contrôle        (défaut : ${CHECKSUM_DIR})
  -f       Forcer : supprimer le fichier local et le re-télécharger
  -h       Afficher cette aide et quitter

Variable d'environnement optionnelle :
  LOG_FILE   chemin d'un journal où les messages sont aussi ajoutés

Codes de retour : 0 ok | 2 usage | 3 téléchargement | 4 sha256 | 5 contenu invalide
EOF
}

# Supprime le fichier temporaire partiel (appelé par trap)
cleanup() {
    if [[ -n "${TMP_FILE}" && -f "${TMP_FILE}" ]]; then
        rm -f -- "${TMP_FILE}"
        log WARN "Fichier temporaire supprimé : ${TMP_FILE}"
    fi
}

# Vérifie que les outils nécessaires sont installés
require_tools() {
    local tool
    for tool in sha256sum awk head stat; do
        command -v "${tool}" >/dev/null 2>&1 || die 2 "Outil requis introuvable : ${tool}"
    done
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        die 2 "Ni curl ni wget n'est installé (sudo apt install curl)"
    fi
}

# Taille d'un fichier en octets (compatible Linux et macOS)
file_size() {
    stat -c %s "$1" 2>/dev/null || stat -f %z "$1"
}

# Télécharge $1 (URL) vers $2 (fichier). Retourne non nul en cas d'échec.
download() {
    local url="$1" dest="$2"
    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error \
             --retry 3 --retry-delay 5 --connect-timeout 20 \
             --output "${dest}" "${url}"
    else
        wget --quiet --tries=3 --timeout=30 --output-document="${dest}" "${url}"
    fi
}

# Contrôle de validité : taille minimale, pas de HTML, colonne attendue dans l'en-tête
validate_content() {
    local file="$1" size header
    [[ -s "${file}" ]] || die 5 "Fichier vide : ${file}"

    size="$(file_size "${file}")"
    if (( size < MIN_SIZE_BYTES )); then
        die 5 "Fichier trop petit (${size} octets, minimum ${MIN_SIZE_BYTES}) : téléchargement incomplet ou page d'erreur ?"
    fi

    header="$(head -n 1 "${file}")"
    if [[ "${header}" == *"<html"* || "${header}" == *"<!DOCTYPE"* || "${header}" == *"<HTML"* ]]; then
        die 5 "Le fichier téléchargé est une page HTML, pas un TSV (URL périmée ?)"
    fi
    if [[ "${header}" != *"${REQUIRED_COLUMN}"* ]]; then
        die 5 "Colonne '${REQUIRED_COLUMN}' absente de l'en-tête : fichier inattendu"
    fi
    log INFO "Contenu valide (${size} octets, colonne ${REQUIRED_COLUMN} présente)"
}

# sha256 d'un fichier (affiche uniquement le hash)
compute_sha256() {
    sha256sum "$1" | awk '{print $1}'
}

# Compare le sha256 du fichier à la référence ; la crée si elle n'existe pas
verify_checksum() {
    local file="$1" checksum_file="$2" actual expected
    actual="$(compute_sha256 "${file}")"

    if [[ -f "${checksum_file}" ]]; then
        expected="$(awk '{print $1}' "${checksum_file}" | head -n 1)"
        if [[ "${actual}" != "${expected}" ]]; then
            log ERROR "sha256 attendu : ${expected}"
            log ERROR "sha256 obtenu : ${actual}"
            die 4 "Somme de contrôle INCORRECTE pour $(basename "${file}") : fichier corrompu ou NCBI a publié une nouvelle version"
        fi
        log INFO "sha256 vérifié OK : ${actual}"
    else
        mkdir -p -- "$(dirname "${checksum_file}")"
        printf '%s  %s\n' "${actual}" "$(basename "${file}")" > "${checksum_file}"
        log WARN "Aucune somme de référence : créée dans ${checksum_file}"
        log WARN "sha256 = ${actual}  -> pensez à la committer dans Git et à la noter dans SOURCES.md"
    fi
}

# ------------------------------ Programme principal --------------------------
main() {
    while getopts ":d:u:c:fh" opt; do
        case "${opt}" in
            d) DATA_DIR="${OPTARG}" ;;
            u) URL="${OPTARG}" ;;
            c) CHECKSUM_DIR="${OPTARG}" ;;
            f) FORCE=1 ;;
            h) usage; exit 0 ;;
            :) usage >&2; die 2 "L'option -${OPTARG} requiert un argument" ;;
            \?) usage >&2; die 2 "Option inconnue : -${OPTARG}" ;;
        esac
    done
    shift $((OPTIND - 1))
    [[ $# -eq 0 ]] || { usage >&2; die 2 "Argument inattendu : $1"; }

    require_tools

    local filename target checksum_file
    filename="$(basename "${URL%%\?*}")"
    target="${DATA_DIR}/${filename}"
    checksum_file="${CHECKSUM_DIR}/${filename}.sha256"
    TMP_FILE="${target}.part"

    # Signaux : nettoyage du .part puis sortie avec le code conventionnel 128+N
    trap cleanup EXIT
    trap 'log WARN "Interruption (SIGINT)";  exit 130' INT
    trap 'log WARN "Interruption (SIGTERM)"; exit 143' TERM

    mkdir -p -- "${DATA_DIR}"
    log INFO "Dossier des données : ${DATA_DIR}"

    # -f : on repart de zéro (un fichier en 444 se supprime si le dossier est modifiable)
    if (( FORCE == 1 )) && [[ -f "${target}" ]]; then
        rm -f -- "${target}"
        log INFO "Option -f : fichier existant supprimé"
    fi

    if [[ -f "${target}" ]]; then
        log INFO "Fichier déjà présent : ${target} (pas de re-téléchargement)"
    else
        rm -f -- "${TMP_FILE}"
        log INFO "Téléchargement : ${URL}"
        if ! download "${URL}" "${TMP_FILE}"; then
            die 3 "Échec du téléchargement depuis ${URL} (réseau ? URL ? version NCBI retirée ?)"
        fi
        mv -- "${TMP_FILE}" "${target}"    # publication atomique : jamais de fichier à moitié écrit
        log INFO "Téléchargement terminé : ${target}"
    fi

    validate_content "${target}"
    verify_checksum "${target}" "${checksum_file}"

    chmod 444 -- "${target}"
    log INFO "Permissions : $(stat -c %A "${target}" 2>/dev/null || stat -f %Sp "${target}") (lecture seule)"
    log INFO "Terminé avec succès : ${target}"
}

main "$@"
