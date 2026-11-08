# Sources et Provenance des Données

## Jeu de données principal

- **Organisme / Pathogène :** *Salmonella enterica* (Salmonellose)
- **Source :** NCBI Pathogen Detection (National Center for Biotechnology Information)
- **Projet :** Isolats mondiaux séquencés par WGS (Whole Genome Sequencing)
- **Identifiant du jeu :** `PDG000000002` (Salmonella enterica), version `1697`
- **Nom du fichier :** `PDG000000002.1697.amr.metadata.tsv`
- **URL de téléchargement direct :** `https://ftp.ncbi.nlm.nih.gov/pathogen/Results/Salmonella/PDG000000002.1697/AMR/PDG000000002.1697.amr.metadata.tsv`
- **Répertoire parent :** `https://ftp.ncbi.nlm.nih.gov/pathogen/Results/Salmonella/PDG000000002.1697/AMR/`
- **Format :** TSV (Tab-Separated Values), 49 colonnes, 249 543 isolats
- **Taille :** 129 100 239 octets (≈ 123 Mo)
- **Date de téléchargement :** 8 novembre 2026
- **Somme de contrôle SHA-256 :** `9c2dc6970d2673d1f396e3b353dae9e671806595adc89e4580be2552d01a3d85`
  (référence versionnée dans `checksums/PDG000000002.1697.amr.metadata.tsv.sha256`)

### Remarques

- Version figée (instantané du 2020-01-01) : le dossier `latest_kmer` est mis à jour chaque semaine, son contenu et son SHA-256 changent, il n'est donc pas utilisé.
- Le téléchargement et la vérification d'intégrité sont automatisés par `scripts/download_and_verify.sh`.

## Colonnes d'intérêt exploitées dans le projet

01. `#label` (col. 1) : identifiant de l'isolat.
02. `collection_date` (col. 20) : date de collecte.
03. `epi_type` (col. 21) : `clinical` (167 081) ou `environmental/other` (82 462).
04. `geo_loc_name` (col. 23) : localisation géographique.
05. `isolation_source` (col. 26) : source d'isolement.
06. `scientific_name` (col. 30) : nom taxonomique.
07. `serovar` (col. 31) : sérotype (vide pour 112 068 isolats).
08. `number_amr_genes` (col. 47) : nombre de gènes de résistance.
09. `AST_phenotypes` (col. 48) : phénotypes de résistance (antibiogramme).
10. `AMR_genotypes` (col. 49) : gènes de résistance séparés par des virgules, entre guillemets ; `NULL` si aucun gène.
