# Projet « Enquête sur une maladie » — Analyse AMR Salmonella

## 📌 Présentation du Projet
Projet académique d'analyse automatisée et reproductible de données génomiques sur la salmonellose (*Salmonella enterica*). 
Le pipeline a pour objectif d'analyser la prévalence et la co-occurrence des gènes de résistance aux antibiotiques (AMR - *Antimicrobial Resistance*) à partir des isolats issus de la base **NCBI Pathogen Detection**.

- **Maladie étudiée :** Salmonellose (*Salmonella enterica*)
- **Jeu de données :** Métadonnées d'isolats WGS NCBI Pathogen Detection (`PDG000000002.1697.amr.metadata.tsv`, ~123 Mo)
- **Question biologique :** Quelle est la fréquence des gènes de résistance aux antibiotiques critiques (notamment bêta-lactamines, fluoroquinolones et aminoglycosides) parmi les isolats cliniques vs environnementaux/alimentaires de *Salmonella*, et quels profils de multi-résistance (MDR) émergent de façon significative ?

---

## 👥 Composition du Groupe
- **HECHAM Idriss** (Délégué de groupe)
- **Bouabdelli Mohamed**
- **LAGGOUNE Ahmed Amar**
- **Bouchene Zakaria**
- **FARTAS Nadir**

### Répartition indicative des tâches
1. **HECHAM Idriss :** Architecture de `run.sh`, gestion des arguments (`getopts`), aide (`-h`), capture des signaux (`trap`) et robustesse (`set -euo pipefail`).
2. **Bouabdelli Mohamed :** Acquisition des données, calcul et vérification des sommes de contrôle (`sha256sum`), permissions de fichiers (`chmod 444`), et documentation `SOURCES.md`.
3. **LAGGOUNE Ahmed Amar :** Traitement Shell en tubes Unix (`cut | grep | awk | sort | uniq`) pour le filtrage des isolats et l'extraction des motifs AMR.
4. **Bouchene Zakaria :** Script Python d'analyse statistique (`argparse`), calcul des métriques, export CSV/JSON et génération des figures graphiques.
5. **FARTAS Nadir :** Tests automatisés (`pytest`), environnement reproductible (`requirements.txt` / `environment.yml`), configuration cron/timer et journaux horodatés (`logs/`).

---

## 📂 Structure du Répertoire
```text
.
├── .gitattributes          # Normalisation des fins de ligne (LF pour les scripts bash)
├── .gitignore              # Exclusion des données brutes (>800 Mo), logs et caches
├── README.md               # Présentation, mode d'emploi et architecture
├── SOURCES.md              # Origine, identifiant, URL et date des données
├── LIEN_GIT.txt            # URL du dépôt et hash du commit final évalué
├── run.sh                  # Script maître automatisant l'ensemble du pipeline
├── requirements.txt        # Dépendances Python pour virtualenv / pip
├── environment.yml         # Spécification d'environnement Conda
├── scripts/                # Scripts modulaires du pipeline
│   ├── download_and_verify.sh  # Téléchargement et vérification sha256
│   ├── filter_motifs.sh        # Tube Unix de filtrage et recherche de motif
│   ├── analyze_amr.py          # Analyse statistique et tracé Python
│   └── test_analyze.py         # Tests unitaires automatisés
├── cron/                   # Tâches planifiées
│   └── crontab.sample          # Exemple de planification périodique documentée
├── data/                   # Données brutes téléchargées (généré, ignoré par Git)
├── results/                # Données filtrées, métriques CSV/JSON, graphiques et archive .tar.gz
└── logs/                   # Journaux d'exécution horodatés
```

---

## ⚙️ Prérequis & Installation

### Option 1 : Environnement Python virtuel (venv)
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Option 2 : Environnement Conda
```bash
conda env create -f environment.yml
conda activate salmonella-amr
```

---

## 🚀 Utilisation Rapide
Le script principal `run.sh` orchestre l'ensemble du traitement :

```bash
# Rendre le script exécutable
chmod +x run.sh

# Afficher l'aide
./run.sh -h

# Exécuter l'ensemble du pipeline
./run.sh
```

---

## 🧪 Tests Automatisés
Pour vérifier le bon fonctionnement des traitements statistiques :
```bash
pytest scripts/test_analyze.py
```

