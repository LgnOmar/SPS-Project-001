# Projet « Enquête sur une maladie » — Analyse AMR Salmonella

## 📌 Présentation du Projet
Projet académique d'analyse automatisée et reproductible de données génomiques sur la salmonellose (*Salmonella enterica*). 
Le pipeline a pour objectif d'analyser la prévalence et la co-occurrence des gènes de résistance aux antibiotiques (AMR - *Antimicrobial Resistance*) à partir des isolats issus de la base **NCBI Pathogen Detection**.

- **Maladie étudiée :** Salmonellose (*Salmonella enterica*)
- **Jeu de données :** Métadonnées d'isolats WGS NCBI Pathogen Detection (`PDG000000002.1697.amr.metadata.tsv`, ~123 Mo)
- **Question biologique :** Quelle est la fréquence des gènes de résistance aux antibiotiques critiques (notamment bêta-lactamines, fluoroquinolones et aminoglycosides) parmi les isolats cliniques vs environnementaux/alimentaires de *Salmonella*, et quels profils de multi-résistance (MDR) émergent de façon significative ?

---

## 👥 Composition du Groupe
- **LAGGOUNE Ahmed Amar** (Propriétaire du dépôt GitHub / Intégration & Orchestration)
- **HECHAM Idriss** (Délégué du groupe / Traitement Shell & Rapport)
- **Bouabdelli Mohamed** (Acquisition & Intégrité des données)
- **Bouchene Zakaria** (Analyse statistique Python & Visualisation)
- **FARTAS Nadir** (Tests automatisés, Environnement & Planification)

### Répartition officielle des tâches
1. **LAGGOUNE Ahmed Amar :** Gestion et intégration du dépôt GitHub, revue des Pull Requests, conception du script maître `run.sh`, parsing des options (`getopts`), documentation d'aide (`-h`), gestion des signaux et erreurs (`trap`, `set -euo pipefail`), archivage daté (`tar.gz`), et fonctions réutilisables.
2. **HECHAM Idriss :** Conception du pipeline Unix (`scripts/filter_motifs.sh`), filtrage par enchaînement de tubes (`cut | grep | awk | sort | uniq`), extraction des motifs de résistance (MDR), et coordination de la rédaction du `rapport.pdf`.
3. **Bouabdelli Mohamed :** Script d'acquisition des données (`scripts/download_and_verify.sh`), calcul et vérification des sommes de contrôle (`sha256sum`), verrouillage des permissions en lecture seule (`chmod 444`), et tenue de `SOURCES.md`.
4. **Bouchene Zakaria :** Développement du script Python d'analyse statistique (`scripts/analyze_amr.py`) avec `argparse`, calcul des fréquences de résistance par source et sérovar, génération automatique des graphiques PNG, et export chiffré en CSV/JSON.
5. **FARTAS Nadir :** Développement de la suite de tests automatisés (`scripts/test_analyze.py` avec `pytest`), configuration des environnements reproductibles (`requirements.txt` / `environment.yml`), écriture et documentation de la tâche planifiée (`cron/crontab.sample`), et gestion des journaux d'exécution horodatés (`logs/`).

---

## 📂 Structure du Répertoire
```text
.
├── .gitattributes          # Normalisation des fins de ligne (LF pour les scripts bash)
├── .gitignore              # Exclusion des données brutes (>100 Mo), logs et caches
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

Le filtrage Unix peut aussi être lancé indépendamment :
```bash
chmod +x scripts/filter_motifs.sh
./scripts/filter_motifs.sh \
  -i data/PDG000000002.1697.amr.metadata.tsv \
  -o results/filtered_amr.tsv
```

---

## 🧪 Tests Automatisés
Pour vérifier le bon fonctionnement des traitements statistiques :
```bash
pytest scripts/test_analyze.py
```

---

## ⏰ Automatisation & Tâche Planifiée (Cron)
La planification hebdomadaire est documentée dans `cron/crontab.sample`. Elle lance le pipeline chaque dimanche à 02:00 et conserve la sortie dans un journal daté sous `logs/`.
