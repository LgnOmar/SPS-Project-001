#!/usr/bin/env bash
# ==============================================================================
# run.sh - Master Orchestrator Pipeline
# Projet « Enquête sur une maladie » - Analyse AMR Salmonella
#
# Auteur : Ahmed Amar LAGGOUNE (Propriétaire du dépôt / Intégration & Orchestration)
# Équipe : HECHAM Idriss, Bouabdelli Mohamed, Bouchene Zakaria, FARTAS Nadir
#
# Rôle :
#   Exécute le pipeline bioinformatique automatisé et reproductible de bout en bout :
#     1. Vérification des outils système et permissions
#     2. Initialisation des répertoires et des journaux horodatés
#     3. Acquisition des données et vérification SHA-256 (download_and_verify.sh)
#     4. Filtrage Unix par tubes et extraction du motif MDR (filter_motifs.sh)
#     5. Analyse statistique et génération des figures (analyze_amr.py)
#     6. Exécution des tests de validation automatisés (test_analyze.py)
#     7. Archivage daté et compressé des résultats finaux (tar.gz)
#
# Codes de retour :
#   0  succès complet
#   1  erreur d'exécution dans une étape du pipeline
#   2  erreur d'usage ou option invalide
#   3  dépendance ou outil système requis manquant
#   130 interruption utilisateur (SIGINT / Ctrl+C)
#   143 arrêt du processus (SIGTERM)
# ==============================================================================
set -euo pipefail

# ----------------------------- Constantes & Chemins ---------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="${SCRIPT_DIR}"
readonly SCRIPTS_DIR="${REPO_ROOT}/scripts"
readonly RAW_FILENAME="PDG000000002.1697.amr.metadata.tsv"

# Valeurs configurables par arguments
DATA_DIR="${REPO_ROOT}/data"
RESULTS_DIR="${REPO_ROOT}/results"
LOGS_DIR="${REPO_ROOT}/logs"
FORCE_DOWNLOAD=0
SKIP_TESTS=0
TMP_DIR=""

# ------------------------------- Fonctions -----------------------------------

# 1. Journalisation horodatée (stdout/stderr + fichier log)
log() {
    local level="$1"; shift
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local line="[${timestamp}] [${level}] [${SCRIPT_NAME}] $*"
    echo "${line}" >&2
    if [[ -n "${CURRENT_LOG_FILE:-}" ]]; then
        echo "${line}" >> "${CURRENT_LOG_FILE}"
    fi
}

# 2. Gestion des erreurs fatales et sortie
die() {
    local code="$1"; shift
    log "ERROR" "$*"
    exit "${code}"
}

# 3. Affichage de l'aide en ligne de commande (-h)
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Pipeline automatisé pour l'enquête génomique sur la salmonellose et l'analyse
des gènes de multi-résistance aux antibiotiques (AMR).

Options :
  -d DIR   Spécifier le répertoire des données brutes    (défaut : ${DATA_DIR})
  -o DIR   Spécifier le répertoire des résultats        (défaut : ${RESULTS_DIR})
  -l DIR   Spécifier le répertoire des journaux de log  (défaut : ${LOGS_DIR})
  -f       Forcer le re-téléchargement et le re-calcul complet
  -s       Passer l'étape des tests pytest
  -h       Afficher cette aide détaillée et quitter

Exemples d'utilisation :
  ./${SCRIPT_NAME}
  ./${SCRIPT_NAME} -f
  ./${SCRIPT_NAME} -d /tmp/custom_data -o /tmp/custom_results
EOF
}

# 4. Nettoyage sécurisé des fichiers temporaires (déclenché par trap)
cleanup() {
    local exit_code=$?
    if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
        rm -rf -- "${TMP_DIR}"
        log "DEBUG" "Répertoire temporaire nettoyé : ${TMP_DIR}"
    fi
    if [[ ${exit_code} -ne 0 && ${exit_code} -ne 130 && ${exit_code} -ne 143 ]]; then
        log "ERROR" "Le pipeline s'est interrompu avec le code d'erreur : ${exit_code}"
    fi
}

# 5. Vérification de la présence des outils requis
require_cmd() {
    local cmd="$1"
    command -v "${cmd}" >/dev/null 2>&1 || die 3 "Outil système obligatoire manquant : '${cmd}'. Veuillez l'installer."
}

# 6. Création sécurisée et idempotente des dossiers
ensure_directory() {
    local dir="$1"
    if [[ ! -d "${dir}" ]]; then
        mkdir -p -- "${dir}" || die 1 "Impossible de créer le dossier : ${dir}"
        log "DEBUG" "Dossier initialisé : ${dir}"
    fi
}

# 7. Archivage daté et compressé des résultats
create_dated_archive() {
    local target_dir="$1"
    local archive_name
    archive_name="archive_$(date '+%Y%m%d_%H%M%S').tar.gz"
    local archive_path="${target_dir}/${archive_name}"

    log "INFO" "Création de l'archive datée des résultats : ${archive_name}..."
    (
        cd "${target_dir}" && \
        tar -czf "${archive_name}" \
            --exclude="*.tar.gz" \
            --exclude="*.tmp*" \
            * 2>/dev/null || true
    ) || die 1 "Échec de la création de l'archive tar des résultats."

    if [[ -f "${archive_path}" ]]; then
        log "INFO" "Archive créée avec succès : ${archive_path} ($(stat -c %s "${archive_path}" 2>/dev/null || stat -f %z "${archive_path}") octets)"
    else
        die 1 "Le fichier d'archive n'a pas été généré."
    fi
}

# ----------------------------- Gestion des Arguments --------------------------
while getopts ":d:o:l:fsh" opt; do
    case "${opt}" in
        d) DATA_DIR="${OPTARG}" ;;
        o) RESULTS_DIR="${OPTARG}" ;;
        l) LOGS_DIR="${OPTARG}" ;;
        f) FORCE_DOWNLOAD=1 ;;
        s) SKIP_TESTS=1 ;;
        h) usage; exit 0 ;;
        :) usage >&2; die 2 "L'option -${OPTARG} requiert un chemin de répertoire." ;;
        \?) usage >&2; die 2 "Option inconnue : -${OPTARG}. Utilisez -h pour voir l'aide." ;;
    esac
done
shift $((OPTIND - 1))
[[ $# -eq 0 ]] || die 2 "Argument inattendu : '$1'. Utilisez -h pour l'aide."

# -------------------------- Traps & Signaux Système ---------------------------
trap cleanup EXIT
trap 'log "WARN" "Interruption par l utilisateur (SIGINT reçu)"; exit 130' INT
trap 'log "WARN" "Arrêt forcé du processus (SIGTERM reçu)"; exit 143' TERM

# ----------------------------- Début du Pipeline ------------------------------
ensure_directory "${DATA_DIR}"
ensure_directory "${RESULTS_DIR}"
ensure_directory "${LOGS_DIR}"

CURRENT_LOG_FILE="${LOGS_DIR}/pipeline_$(date '+%Y%m%d_%H%M%S').log"
touch "${CURRENT_LOG_FILE}" || die 1 "Impossible d'écrire dans le dossier logs."
export LOG_FILE="${CURRENT_LOG_FILE}"

log "INFO" "======================================================================"
log "INFO" " Démarrage du Pipeline Salmonella AMR - Projet Enquête sur une maladie"
log "INFO" " Intégration : Ahmed Amar LAGGOUNE (Propriétaire du dépôt)"
log "INFO" " Journal d'exécution : ${CURRENT_LOG_FILE}"
log "INFO" "======================================================================"

# Détection portable de Python (compatible Linux python3 et Windows/Git Bash python)
if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    die 3 "Interpréteur Python introuvable. Veuillez installer Python 3.10+."
fi

# Étape 1 : Vérification des dépendances système
log "INFO" "[Étape 1/6] Audit des outils système et droits d'accès..."
for tool in bash awk cut grep sort uniq tar sha256sum stat head tail "${PYTHON_BIN}"; do
    require_cmd "${tool}"
done

# Vérification de l'interpréteur Python et des paquets requis
if ! "${PYTHON_BIN}" -c "import pandas, matplotlib, seaborn" >/dev/null 2>&1; then
    die 3 "Bibliothèques Python manquantes (pandas, matplotlib, seaborn). Exécutez : pip install -r requirements.txt"
fi

# Application des permissions d'exécution sur les scripts
chmod +x "${SCRIPTS_DIR}"/*.sh 2>/dev/null || true
log "INFO" "Permissions d'exécution validées sur ${SCRIPTS_DIR}/*.sh."

# Migration du jeu de données existant vers data/ si présent à la racine
if [[ -f "${REPO_ROOT}/${RAW_FILENAME}" && ! -f "${DATA_DIR}/${RAW_FILENAME}" ]]; then
    log "INFO" "Déplacement du jeu de données local vers ${DATA_DIR}/${RAW_FILENAME}..."
    mv -- "${REPO_ROOT}/${RAW_FILENAME}" "${DATA_DIR}/${RAW_FILENAME}"
fi

# Étape 2 : Acquisition des données et vérification d'intégrité SHA-256
log "INFO" "[Étape 2/6] Vérification et intégrité des données brutes (SHA-256)..."
DOWNLOAD_ARGS=("-d" "${DATA_DIR}")
if [[ ${FORCE_DOWNLOAD} -eq 1 ]]; then
    DOWNLOAD_ARGS+=("-f")
fi
"${SCRIPTS_DIR}/download_and_verify.sh" "${DOWNLOAD_ARGS[@]}" || \
    die 1 "Échec critique à l'étape d'acquisition/vérification des données."

RAW_DATA_PATH="${DATA_DIR}/${RAW_FILENAME}"
[[ -f "${RAW_DATA_PATH}" ]] || die 1 "Fichier de données brutes introuvable : ${RAW_DATA_PATH}"

# Étape 3 : Filtrage par tubes Unix & extraction du motif biologique
log "INFO" "[Étape 3/6] Filtrage Unix (enchaînement de tubes) et extraction du motif MDR..."
FILTERED_OUTPUT="${RESULTS_DIR}/filtered_amr.tsv"

"${SCRIPTS_DIR}/filter_motifs.sh" \
    -i "${RAW_DATA_PATH}" \
    -o "${FILTERED_OUTPUT}" || \
    die 1 "Échec du filtrage Unix des données."

[[ -s "${FILTERED_OUTPUT}" ]] || die 1 "Le fichier filtré est vide ou absent : ${FILTERED_OUTPUT}"
FILTERED_COUNT=$(tail -n +2 "${FILTERED_OUTPUT}" | wc -l || echo "0")
log "INFO" "Motif extrait : ${FILTERED_COUNT} isolats multi-résistants (MDR) identifiés."

# Étape 4 : Analyse statistique Python & génération des visualisations
log "INFO" "[Étape 4/6] Analyse statistique Python et tracés graphiques..."
"${PYTHON_BIN}" "${SCRIPTS_DIR}/analyze_amr.py" \
    --input "${FILTERED_OUTPUT}" \
    --output-dir "${RESULTS_DIR}" || \
    die 1 "Échec de l'analyse statistique Python."

# Vérification des fichiers produits annoncés
for expected_file in "amr_summary.csv" "amr_source_comparison.csv" "amr_frequency_plot.png"; do
    if [[ ! -s "${RESULTS_DIR}/${expected_file}" ]]; then
        die 1 "Fichier de résultat attendu manquant ou vide : ${RESULTS_DIR}/${expected_file}"
    fi
    log "INFO" "Sortie validée : ${RESULTS_DIR}/${expected_file}"
done

# Étape 5 : Exécution de la suite de tests automatisés (pytest)
if [[ ${SKIP_TESTS} -eq 0 ]]; then
    log "INFO" "[Étape 5/6] Validation par tests unitaires automatisés (pytest)..."
    if command -v pytest >/dev/null 2>&1; then
        pytest -q "${SCRIPTS_DIR}/test_analyze.py" || \
            die 1 "Les tests automatisés pytest ont échoué."
        log "INFO" "Tous les tests unitaires automatisés ont réussi avec succès."
    elif "${PYTHON_BIN}" -m pytest --version >/dev/null 2>&1; then
        "${PYTHON_BIN}" -m pytest -q "${SCRIPTS_DIR}/test_analyze.py" || \
            die 1 "Les tests automatisés pytest ont échoué."
        log "INFO" "Tous les tests unitaires automatisés ont réussi avec succès."
    else
        log "WARN" "Pytest non trouvé dans le PATH système. Tests ignorés."
    fi
else
    log "INFO" "[Étape 5/6] Tests automatisés ignorés (option -s active)."
fi

# Étape 6 : Archivage daté et compressé des résultats finaux (tar.gz)
log "INFO" "[Étape 6/6] Création de l'archive datée des résultats..."
create_dated_archive "${RESULTS_DIR}"

log "INFO" "======================================================================"
log "INFO" " ✅ Pipeline terminé avec succès !"
log "INFO" " Résultats disponibles sous : ${RESULTS_DIR}/"
log "INFO" " Journal d'exécution complet : ${CURRENT_LOG_FILE}"
log "INFO" "======================================================================"

exit 0
